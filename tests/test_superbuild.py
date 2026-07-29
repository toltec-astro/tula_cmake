from __future__ import annotations

import json
from collections.abc import Sequence
from pathlib import Path

import pytest

from tula_cmake.models import (
    BuildRequest,
    FeatureMode,
    ProjectCatalog,
    ProjectMode,
    ResolvedSuperbuild,
)
from tula_cmake.registry import load_registry
from tula_cmake.superbuild import (
    ProjectGraphResolver,
    load_project_catalog,
    load_project_manifest,
    parse_project_source_overrides,
    parse_provider_overrides,
    render_conanfile,
    render_project_lock,
    render_project_manifest,
)
from tula_cmake.workflow import BuildWorkflow

_ROOT = Path(__file__).parents[1]
_BOILERPLATE = _ROOT / "examples" / "tula_boilerplate"
_DOWNSTREAM = _ROOT / "examples" / "tula_downstream"
_PINNED_REVISION = "d27aa6e653b4f96fe3187f3cd8c2b4ae4feb6a73"


def _local_sources() -> dict[str, Path]:
    return {"tula_boilerplate": _BOILERPLATE}


def _catalog_for(
    name: str,
    *,
    version: str,
    repository: str,
    revision: str = "0" * 40,
    source_subdir: str = "",
) -> ProjectCatalog:
    return ProjectCatalog.model_validate(
        {
            "schema_version": 1,
            "projects": {
                name: {
                    "name": name,
                    "version": version,
                    "source": {
                        "git_repository": repository,
                        "git_revision": revision,
                        "source_subdir": source_subdir,
                    },
                    "cmake_target": f"{name}::target",
                }
            },
        }
    )


def _resolve_local(
    overrides: dict[str, FeatureMode] | None = None,
) -> ResolvedSuperbuild:
    return ProjectGraphResolver(load_registry()).resolve(
        _DOWNSTREAM,
        overrides,
        project_sources=_local_sources(),
    )


def test_vertical_slice_resolves_project_and_transitive_feature() -> None:
    graph = _resolve_local()

    assert graph.root.name == "tula_downstream"
    assert [(project.name, project.provider) for project in graph.projects] == [
        ("tula_boilerplate", ProjectMode.CPM),
    ]
    assert graph.projects[0].source_kind == "local"
    assert graph.providers["logging"] is FeatureMode.CONAN
    assert graph.providers["yaml_cpp"] is FeatureMode.DISABLED
    assert graph.conan_requires == ("fmt/12.1.0", "spdlog/1.17.0")


def test_catalog_acquires_pinned_local_git_url(tmp_path: Path) -> None:
    bundled = load_project_catalog()
    raw = bundled.model_dump(mode="json")
    raw["projects"]["tula_boilerplate"]["source"]["git_repository"] = str(_ROOT)
    catalog = ProjectCatalog.model_validate(raw)

    graph = ProjectGraphResolver(load_registry()).resolve(
        _DOWNSTREAM,
        catalog=catalog,
        source_cache=tmp_path / "sources",
    )

    project = graph.projects[0]
    assert project.source_kind == "catalog"
    assert project.git_revision == _PINNED_REVISION
    assert project.source_dir.is_relative_to(tmp_path / "sources")
    assert load_project_manifest(project.source_dir).project.name == "tula_boilerplate"

    cached_graph = ProjectGraphResolver(load_registry()).resolve(
        _DOWNSTREAM,
        catalog=catalog,
        source_cache=tmp_path / "sources",
    )
    assert cached_graph.projects[0].source_dir == project.source_dir


def test_root_override_controls_transitive_provider() -> None:
    graph = _resolve_local({"logging": FeatureMode.SYSTEM})

    assert graph.providers["logging"] is FeatureMode.SYSTEM
    assert graph.conan_requires == ()


def test_generated_inputs_separate_projects_from_conan_requirements() -> None:
    graph = _resolve_local()

    projects = render_project_manifest(graph)
    conanfile = render_conanfile(graph.conan_requires)
    lock = render_project_lock(graph)

    assert 'set(TULA_PROJECT_tula_boilerplate_MODE "cpm")' in projects
    assert str(_BOILERPLATE.resolve()) in projects
    assert "fmt/12.1.0" in conanfile
    assert "spdlog/1.17.0" in conanfile
    assert "tula-boilerplate" not in conanfile
    assert "kind: local" in lock
    assert f"path: {_BOILERPLATE.resolve()}" in lock


def test_project_manifest_identity_must_match_dependency_key(tmp_path: Path) -> None:
    child = tmp_path / "child"
    child.mkdir()
    (child / "tula-project.yaml").write_text(
        """
schema_version: 1
project: {name: actual_name, version: 1.0.0}
dependencies: {projects: {}, features: {}}
"""
    )
    (tmp_path / "tula-project.yaml").write_text(
        """
schema_version: 1
project: {name: root, version: 1.0.0}
dependencies:
  projects:
    expected_name: {default_provider: cpm}
  features: {}
"""
    )
    catalog = _catalog_for(
        "expected_name",
        version="1.0.0",
        repository=str(tmp_path),
    )

    with pytest.raises(ValueError, match="resolved manifest 'actual_name'"):
        ProjectGraphResolver(load_registry()).resolve(
            tmp_path,
            catalog=catalog,
            project_sources={"expected_name": child},
        )


def test_project_catalog_version_must_match_manifest(tmp_path: Path) -> None:
    (tmp_path / "tula-project.yaml").write_text(
        """
schema_version: 1
project: {name: root, version: 1.0.0}
dependencies:
  projects:
    tula_boilerplate: {default_provider: cpm}
  features: {}
"""
    )
    catalog = _catalog_for(
        "tula_boilerplate",
        version="9.0.0",
        repository=str(_ROOT),
    )
    with pytest.raises(ValueError, match="catalog version"):
        ProjectGraphResolver(load_registry()).resolve(
            tmp_path,
            catalog=catalog,
            project_sources=_local_sources(),
        )


def test_overrides_reject_duplicates_unknown_and_unused_projects() -> None:
    with pytest.raises(ValueError, match="duplicate provider override"):
        parse_provider_overrides(("logging=conan", "logging=system"))
    with pytest.raises(ValueError, match="duplicate project source override"):
        parse_project_source_overrides(("tula=one", "tula=two"))

    with pytest.raises(ValueError, match="unused feature"):
        ProjectGraphResolver(load_registry()).resolve(
            _DOWNSTREAM,
            {"yaml_cpp": FeatureMode.CONAN},
            project_sources=_local_sources(),
        )
    with pytest.raises(ValueError, match="unknown project source"):
        ProjectGraphResolver(load_registry()).resolve(
            _DOWNSTREAM,
            project_sources={"missing": _BOILERPLATE},
        )


def test_load_project_inputs_require_mappings(tmp_path: Path) -> None:
    (tmp_path / "tula-project.yaml").write_text("- not\n- a\n- mapping\n")
    catalog = tmp_path / "projects.yaml"
    catalog.write_text("- not\n- a\n- mapping\n")

    with pytest.raises(ValueError, match="manifest must be a mapping"):
        load_project_manifest(tmp_path)
    with pytest.raises(ValueError, match="catalog must be a mapping"):
        load_project_catalog(catalog)


def test_superbuild_presets_are_rebased_to_root(
    tmp_path: Path,
) -> None:
    source = tmp_path / "source"
    output = tmp_path / "output"
    generators = output / "generators"
    source.mkdir()
    generators.mkdir(parents=True)
    (generators / "conan_toolchain.cmake").touch()
    (generators / "CMakePresets.json").write_text(
        json.dumps(
            {
                "version": 3,
                "configurePresets": [
                    {
                        "name": "conan-debug",
                        "toolchainFile": "conan_toolchain.cmake",
                        "binaryDir": str(generators),
                    }
                ],
                "buildPresets": [
                    {"name": "conan-debug", "configurePreset": "conan-debug"}
                ],
            }
        )
    )

    preset = BuildWorkflow._write_superbuild_presets(
        source,
        output,
        generators,
        {"TULA_FEATURE_MANIFEST": "/feature-manifest"},
    )

    user = json.loads((source / "CMakeUserPresets.json").read_text())
    configure = user["configurePresets"][0]
    assert preset == "conan-debug"
    assert configure["binaryDir"] == str((output / "build").resolve())
    assert configure["toolchainFile"] == str(
        (generators / "conan_toolchain.cmake").resolve()
    )
    assert configure["cacheVariables"]["TULA_FEATURE_MANIFEST"] == "/feature-manifest"
    assert user["vendor"]["tula_cmake"]["generated"] is True


def test_workflow_executes_recursive_superbuild_phases(tmp_path: Path) -> None:
    source = tmp_path / "source"
    output = tmp_path / "output"
    source.mkdir()
    (source / "tula-project.yaml").write_text(
        """
schema_version: 1
project: {name: tula_downstream, version: 3.1.0}
dependencies:
  projects:
    tula_boilerplate: {default_provider: cpm}
  features: {}
"""
    )
    calls: list[tuple[tuple[str, ...], Path | None]] = []

    def run(command: Sequence[str], cwd: Path | None) -> None:
        call = tuple(command)
        calls.append((call, cwd))
        if len(call) > 1 and call[1] == "install":
            generators = Path(call[call.index("--output-folder") + 1])
            generators.mkdir(parents=True, exist_ok=True)
            (generators / "conan_toolchain.cmake").touch()
            (generators / "CMakePresets.json").write_text(
                json.dumps(
                    {
                        "version": 3,
                        "configurePresets": [
                            {
                                "name": "conan-debug",
                                "toolchainFile": "conan_toolchain.cmake",
                            }
                        ],
                        "buildPresets": [
                            {
                                "name": "conan-debug",
                                "configurePreset": "conan-debug",
                            }
                        ],
                    }
                )
            )

    BuildWorkflow(
        BuildRequest(
            source=source,
            output=output,
            profiles=("test-profile",),
            project_sources=(f"tula_boilerplate={_BOILERPLATE}",),
        ),
        runner=run,
    ).execute()

    assert calls[0][0][1] == "install"
    assert "--requires" not in calls[0][0]
    assert calls[1] == (
        ("cmake", "--preset", "conan-debug", "--fresh"),
        source,
    )
    assert calls[2] == (
        ("cmake", "--build", "--preset", "conan-debug"),
        source,
    )
    assert "fmt/12.1.0" in (output / "generated" / "conanfile.txt").read_text()
    assert (
        "tula-boilerplate" not in (output / "generated" / "conanfile.txt").read_text()
    )
    assert (
        "kind: local" in (output / "generated" / "tula-project-lock.yaml").read_text()
    )
