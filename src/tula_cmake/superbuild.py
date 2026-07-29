"""Recursive project discovery, source acquisition, and generated inputs."""

from __future__ import annotations

import os
import subprocess
import tempfile
from collections import defaultdict
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

import yaml

from .models import (
    FeatureMode,
    FeatureRegistry,
    ProjectCatalog,
    ProjectCatalogEntry,
    ProjectManifest,
    ResolvedProject,
    ResolvedSuperbuild,
)
from .registry import resolution_order
from .resources import project_catalog_path

PROJECT_MANIFEST_NAME = "tula-project.yaml"


def load_project_manifest(source_dir: Path) -> ProjectManifest:
    """Load one validated project manifest from ``source_dir``."""
    path = source_dir / PROJECT_MANIFEST_NAME
    if not path.is_file():
        raise ValueError(f"project manifest is unavailable: {path}")
    raw = yaml.safe_load(path.read_text())
    if not isinstance(raw, dict):
        raise ValueError(f"project manifest must be a mapping: {path}")
    return ProjectManifest.model_validate(raw)


def load_project_catalog(path: Path | None = None) -> ProjectCatalog:
    """Load the bundled or explicitly selected owned-project catalog."""
    catalog_path = (path or project_catalog_path()).resolve()
    if not catalog_path.is_file():
        raise ValueError(f"project catalog is unavailable: {catalog_path}")
    raw = yaml.safe_load(catalog_path.read_text())
    if not isinstance(raw, dict):
        raise ValueError(f"project catalog must be a mapping: {catalog_path}")
    return ProjectCatalog.model_validate(raw)


def parse_provider_overrides(assignments: tuple[str, ...]) -> dict[str, FeatureMode]:
    """Parse root-owned ``feature=provider`` assignments."""
    result: dict[str, FeatureMode] = {}
    for assignment in assignments:
        name, value = assignment.split("=", maxsplit=1)
        if name in result:
            raise ValueError(f"duplicate provider override: {name}")
        result[name] = FeatureMode(value)
    return result


def parse_project_source_overrides(
    assignments: tuple[str, ...],
) -> dict[str, Path]:
    """Parse root-owned ``project=source-directory`` assignments."""
    result: dict[str, Path] = {}
    for assignment in assignments:
        name, value = assignment.split("=", maxsplit=1)
        if name in result:
            raise ValueError(f"duplicate project source override: {name}")
        result[name] = Path(value)
    return result


def _run_git(command: Sequence[str]) -> str:
    """Run one Git command and return stripped standard output."""
    try:
        result = subprocess.run(
            tuple(command),
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        detail = (error.stderr or error.stdout or str(error)).strip()
        raise RuntimeError(f"Git source acquisition failed: {detail}") from error
    return result.stdout.strip()


@dataclass(frozen=True)
class _PreparedProject:
    """One catalog project prepared for recursive manifest discovery."""

    entry: ProjectCatalogEntry
    source_dir: Path
    source_kind: Literal["catalog", "local"]


class ProjectSourceManager:
    """Prepare immutable catalog checkouts or explicit local overrides."""

    def __init__(
        self,
        catalog: ProjectCatalog,
        *,
        root_dir: Path,
        source_cache: Path,
        overrides: Mapping[str, Path] | None = None,
    ) -> None:
        self.catalog = catalog
        self.root_dir = root_dir.resolve()
        self.source_cache = source_cache.resolve()
        self.overrides = dict(overrides or {})
        unknown = self.overrides.keys() - self.catalog.projects.keys()
        if unknown:
            raise ValueError(f"unknown project source overrides: {sorted(unknown)}")
        self._used_overrides: set[str] = set()

    def prepare(self, name: str) -> _PreparedProject:
        """Return a source tree containing ``name`` and its manifest."""
        try:
            entry = self.catalog.projects[name]
        except KeyError as error:
            raise ValueError(f"owned project is absent from catalog: {name}") from error

        override = self.overrides.get(name)
        if override is None:
            environment_value = os.environ.get(f"CPM_{name}_SOURCE")
            if environment_value:
                override = Path(environment_value)
        if override is not None:
            self._used_overrides.add(name)
            source_dir = (
                override.resolve()
                if override.is_absolute()
                else (self.root_dir / override).resolve()
            )
            self._validate_source(name, source_dir)
            return _PreparedProject(entry, source_dir, "local")

        checkout = self._catalog_checkout(entry)
        checkout = checkout.resolve()
        source_dir = (checkout / entry.source.source_subdir).resolve()
        if not source_dir.is_relative_to(checkout):
            raise ValueError(f"{name}: source_subdir escapes its Git checkout")
        self._validate_source(name, source_dir)
        return _PreparedProject(entry, source_dir, "catalog")

    def validate_overrides_used(self) -> None:
        """Reject explicit root overrides that are not graph dependencies."""
        unused = self.overrides.keys() - self._used_overrides
        if unused:
            raise ValueError(f"unused project source overrides: {sorted(unused)}")

    def _catalog_checkout(self, entry: ProjectCatalogEntry) -> Path:
        revision = entry.source.git_revision
        destination = self.source_cache / f"{entry.name}-{revision[:12]}"
        self.source_cache.mkdir(parents=True, exist_ok=True)
        if not destination.is_dir():
            with tempfile.TemporaryDirectory(
                prefix=f".{entry.name}-",
                dir=self.source_cache,
            ) as temporary:
                checkout = Path(temporary) / "checkout"
                _run_git(
                    (
                        "git",
                        "clone",
                        "--filter=blob:none",
                        "--no-checkout",
                        entry.source.git_repository,
                        str(checkout),
                    )
                )
                _run_git(
                    (
                        "git",
                        "-C",
                        str(checkout),
                        "checkout",
                        "--detach",
                        revision,
                    )
                )
                checkout.replace(destination)
        actual_revision = _run_git(("git", "-C", str(destination), "rev-parse", "HEAD"))
        if actual_revision != revision:
            raise ValueError(
                f"{entry.name}: cached revision {actual_revision} "
                f"does not match {revision}"
            )
        return destination

    @staticmethod
    def _validate_source(name: str, source_dir: Path) -> None:
        if not source_dir.is_dir():
            raise ValueError(f"{name}: project source is unavailable: {source_dir}")
        if not (source_dir / PROJECT_MANIFEST_NAME).is_file():
            raise ValueError(f"{name}: source has no {PROJECT_MANIFEST_NAME}")


class ProjectGraphResolver:
    """Resolve project manifests into one provider-selected graph."""

    def __init__(self, registry: FeatureRegistry) -> None:
        self.registry = registry

    def resolve(
        self,
        root_dir: Path,
        overrides: Mapping[str, FeatureMode] | None = None,
        *,
        catalog: ProjectCatalog | None = None,
        project_sources: Mapping[str, Path] | None = None,
        source_cache: Path | None = None,
    ) -> ResolvedSuperbuild:
        """Acquire and walk the graph rooted at ``root_dir``."""
        root_dir = root_dir.resolve()
        root_manifest = load_project_manifest(root_dir)
        override_map = dict(overrides or {})
        self._validate_override_names(override_map)
        sources = ProjectSourceManager(
            catalog or load_project_catalog(),
            root_dir=root_dir,
            source_cache=source_cache or root_dir / ".tula" / "sources",
            overrides=project_sources,
        )
        walk = _GraphWalk(self.registry, sources)
        walk.visit(root_dir)
        sources.validate_overrides_used()
        required = self._required_features(walk.feature_defaults)
        providers = self._select_providers(
            required,
            walk.feature_defaults,
            override_map,
        )
        return ResolvedSuperbuild(
            root=root_manifest.project,
            projects=tuple(dict.fromkeys(walk.projects)),
            providers=providers,
            conan_requires=self._conan_requirements(providers),
        )

    def _validate_override_names(
        self,
        overrides: Mapping[str, FeatureMode],
    ) -> None:
        unknown = overrides.keys() - self.registry.features.keys()
        if unknown:
            raise ValueError(f"unknown feature provider overrides: {sorted(unknown)}")

    def _required_features(
        self,
        defaults: Mapping[str, set[FeatureMode]],
    ) -> set[str]:
        required = set(defaults)
        pending = list(required)
        while pending:
            for dependency in self.registry.features[pending.pop()].dependencies:
                if dependency not in required:
                    required.add(dependency)
                    pending.append(dependency)
        return required

    def _select_providers(
        self,
        required: set[str],
        defaults: Mapping[str, set[FeatureMode]],
        overrides: Mapping[str, FeatureMode],
    ) -> dict[str, FeatureMode]:
        providers = dict.fromkeys(self.registry.features, FeatureMode.DISABLED)
        for name in required:
            providers[name] = self._select_provider(
                name,
                defaults.get(name, set()),
                overrides,
            )
        for name, mode in overrides.items():
            if name not in required:
                raise ValueError(f"{name}: provider override targets an unused feature")
            if mode not in self.registry.features[name].modes:
                raise ValueError(f"{name}: unsupported provider {mode.value!r}")
        return providers

    @staticmethod
    def _select_provider(
        name: str,
        defaults: set[FeatureMode],
        overrides: Mapping[str, FeatureMode],
    ) -> FeatureMode:
        if name in overrides:
            return overrides[name]
        if not defaults:
            raise ValueError(f"{name}: transitive prerequisite has no default provider")
        if len(defaults) != 1:
            values = sorted(mode.value for mode in defaults)
            raise ValueError(
                f"{name}: conflicting default providers {values}; "
                "the root must override this feature"
            )
        return next(iter(defaults))

    def _conan_requirements(
        self,
        providers: Mapping[str, FeatureMode],
    ) -> tuple[str, ...]:
        requirements: list[str] = []
        for name in resolution_order(self.registry):
            if providers[name] is FeatureMode.CONAN:
                for requirement in self.registry.features[name].conan_requires:
                    if requirement not in requirements:
                        requirements.append(requirement)
        return tuple(requirements)


class _GraphWalk:
    """Mutable traversal state scoped to one graph resolution."""

    def __init__(
        self,
        registry: FeatureRegistry,
        sources: ProjectSourceManager,
    ) -> None:
        self.registry = registry
        self.source_manager = sources
        self.projects: list[ResolvedProject] = []
        self.feature_defaults: dict[str, set[FeatureMode]] = defaultdict(set)
        self.sources: dict[str, Path] = {}
        self.visiting: set[str] = set()
        self.visited: set[str] = set()

    def visit(
        self,
        source_dir: Path,
        *,
        expected_name: str | None = None,
        expected_version: str | None = None,
    ) -> ProjectManifest:
        """Visit one project and then its direct project dependencies."""
        manifest = load_project_manifest(source_dir)
        name = manifest.project.name
        self._validate_identity(
            name,
            manifest.project.version,
            source_dir,
            expected_name,
            expected_version,
        )
        if name in self.visiting:
            raise ValueError(f"project dependency cycle includes {name}")
        if name in self.visited:
            return manifest

        self.visiting.add(name)
        self._record_features(manifest)
        for project_name, dependency in manifest.dependencies.projects.items():
            prepared = self.source_manager.prepare(project_name)
            child = self.visit(
                prepared.source_dir,
                expected_name=project_name,
                expected_version=prepared.entry.version,
            )
            self.projects.append(
                ResolvedProject(
                    name=project_name,
                    version=child.project.version,
                    provider=dependency.default_provider,
                    source_dir=prepared.source_dir,
                    cmake_target=prepared.entry.cmake_target,
                    source_kind=prepared.source_kind,
                    git_repository=(
                        prepared.entry.source.git_repository
                        if prepared.source_kind == "catalog"
                        else None
                    ),
                    git_revision=(
                        prepared.entry.source.git_revision
                        if prepared.source_kind == "catalog"
                        else None
                    ),
                    source_subdir=(
                        prepared.entry.source.source_subdir
                        if prepared.source_kind == "catalog"
                        else ""
                    ),
                )
            )
        self.visiting.remove(name)
        self.visited.add(name)
        return manifest

    def _validate_identity(
        self,
        name: str,
        version: str,
        source_dir: Path,
        expected_name: str | None,
        expected_version: str | None,
    ) -> None:
        if expected_name is not None and name != expected_name:
            raise ValueError(
                f"project dependency {expected_name!r} resolved manifest {name!r}"
            )
        if expected_version is not None and version != expected_version:
            raise ValueError(
                f"project {name!r} catalog version {expected_version!r} "
                f"does not match manifest {version!r}"
            )
        resolved_source = source_dir.resolve()
        previous_source = self.sources.get(name)
        if previous_source is not None and previous_source != resolved_source:
            raise ValueError(
                f"project {name!r} resolves to multiple sources: "
                f"{previous_source} and {resolved_source}"
            )
        self.sources[name] = resolved_source

    def _record_features(self, manifest: ProjectManifest) -> None:
        for name, dependency in manifest.dependencies.features.items():
            if name not in self.registry.features:
                raise ValueError(f"{manifest.project.name}: unknown feature {name!r}")
            self.feature_defaults[name].add(dependency.default_provider)


def render_project_manifest(graph: ResolvedSuperbuild) -> str:
    """Render source-project provider state for ``TulaProject.cmake``."""
    names = ";".join(project.name for project in graph.projects)
    lines = [
        "# Generated by tula_cmake. Do not edit.",
        f'set(TULA_PROJECT_DEPENDENCIES "{names}")',
    ]
    for project in graph.projects:
        prefix = f"TULA_PROJECT_{project.name}"
        source = str(project.source_dir).replace("\\", "\\\\").replace('"', '\\"')
        target = project.cmake_target.replace("\\", "\\\\").replace('"', '\\"')
        lines.extend(
            [
                f'set({prefix}_MODE "{project.provider.value}")',
                f'set({prefix}_VERSION "{project.version}")',
                f'set({prefix}_SOURCE_DIR "{source}")',
                f'set({prefix}_TARGET "{target}")',
            ]
        )
    lines.append("")
    return "\n".join(lines)


def render_conanfile(requirements: tuple[str, ...]) -> str:
    """Render the virtual Conan consumer for Conan-selected graph nodes."""
    lines = [
        "[requires]",
        *requirements,
        "",
        "[generators]",
        "CMakeDeps",
        "CMakeToolchain",
    ]
    return "\n".join(lines) + "\n"


def render_project_lock(graph: ResolvedSuperbuild) -> str:
    """Render an auditable lock record for the resolved owned-project graph."""
    projects: dict[str, object] = {}
    for project in graph.projects:
        source: dict[str, object] = {"kind": project.source_kind}
        if project.source_kind == "catalog":
            source.update(
                {
                    "git_repository": project.git_repository,
                    "git_revision": project.git_revision,
                    "source_subdir": project.source_subdir,
                }
            )
        else:
            source["path"] = str(project.source_dir)
        projects[project.name] = {
            "version": project.version,
            "provider": project.provider.value,
            "cmake_target": project.cmake_target,
            "source": source,
        }
    document = {
        "schema_version": 1,
        "root": graph.root.model_dump(mode="json"),
        "projects": projects,
    }
    return yaml.safe_dump(document, sort_keys=False)
