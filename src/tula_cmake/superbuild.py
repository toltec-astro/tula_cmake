"""Recursive project-graph discovery and generated superbuild inputs."""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Mapping
from pathlib import Path

import yaml

from .models import (
    FeatureMode,
    FeatureRegistry,
    ProjectManifest,
    ResolvedProject,
    ResolvedSuperbuild,
)
from .registry import resolution_order

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


def parse_provider_overrides(assignments: tuple[str, ...]) -> dict[str, FeatureMode]:
    """Parse root-owned ``feature=provider`` assignments."""
    result: dict[str, FeatureMode] = {}
    for assignment in assignments:
        name, value = assignment.split("=", maxsplit=1)
        if name in result:
            raise ValueError(f"duplicate provider override: {name}")
        result[name] = FeatureMode(value)
    return result


class ProjectGraphResolver:
    """Resolve local project manifests into one provider-selected graph."""

    def __init__(self, registry: FeatureRegistry) -> None:
        self.registry = registry

    def resolve(
        self,
        root_dir: Path,
        overrides: Mapping[str, FeatureMode] | None = None,
    ) -> ResolvedSuperbuild:
        """Walk the graph rooted at ``root_dir`` and validate all selections."""
        root_dir = root_dir.resolve()
        root_manifest = load_project_manifest(root_dir)
        override_map = dict(overrides or {})
        self._validate_override_names(override_map)
        walk = _GraphWalk(self.registry)
        walk.visit(root_dir)
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

    def __init__(self, registry: FeatureRegistry) -> None:
        self.registry = registry
        self.projects: list[ResolvedProject] = []
        self.feature_defaults: dict[str, set[FeatureMode]] = defaultdict(set)
        self.sources: dict[str, Path] = {}
        self.visiting: set[str] = set()
        self.visited: set[str] = set()

    def visit(self, source_dir: Path, *, expected_name: str | None = None) -> None:
        """Visit one project and then its direct project dependencies."""
        manifest = load_project_manifest(source_dir)
        name = manifest.project.name
        self._validate_identity(name, source_dir, expected_name)
        if name in self.visiting:
            raise ValueError(f"project dependency cycle includes {name}")
        if name in self.visited:
            return

        self.visiting.add(name)
        self._record_features(manifest)
        for project_name, dependency in manifest.dependencies.projects.items():
            child_source = (source_dir.resolve() / dependency.source.path).resolve()
            self.visit(child_source, expected_name=project_name)
            child = load_project_manifest(child_source)
            self.projects.append(
                ResolvedProject(
                    name=project_name,
                    version=child.project.version,
                    provider=dependency.default_provider,
                    source_dir=child_source,
                    cmake_target=dependency.cmake_target,
                )
            )
        self.visiting.remove(name)
        self.visited.add(name)

    def _validate_identity(
        self,
        name: str,
        source_dir: Path,
        expected_name: str | None,
    ) -> None:
        if expected_name is not None and name != expected_name:
            raise ValueError(
                f"project dependency {expected_name!r} resolved manifest {name!r}"
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
