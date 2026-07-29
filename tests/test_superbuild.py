from __future__ import annotations

import json
from collections.abc import Sequence
from pathlib import Path

import pytest

from tula_cmake.models import BuildRequest, FeatureMode, ProjectMode
from tula_cmake.registry import load_registry
from tula_cmake.superbuild import (
    ProjectGraphResolver,
    load_project_manifest,
    parse_provider_overrides,
    render_conanfile,
    render_project_manifest,
)
from tula_cmake.workflow import BuildWorkflow

_ROOT = Path(__file__).parents[1]
_DOWNSTREAM = _ROOT / "examples" / "tula_downstream"


def test_vertical_slice_resolves_project_and_transitive_feature() -> None:
    graph = ProjectGraphResolver(load_registry()).resolve(_DOWNSTREAM)

    assert graph.root.name == "tula_downstream"
    assert [(project.name, project.provider) for project in graph.projects] == [
        ("tula_boilerplate", ProjectMode.CPM),
    ]
    assert graph.providers["logging"] is FeatureMode.CONAN
    assert graph.providers["yaml_cpp"] is FeatureMode.DISABLED
    assert graph.conan_requires == ("fmt/12.1.0", "spdlog/1.17.0")


def test_root_override_controls_transitive_provider() -> None:
    graph = ProjectGraphResolver(load_registry()).resolve(
        _DOWNSTREAM,
        {"logging": FeatureMode.SYSTEM},
    )

    assert graph.providers["logging"] is FeatureMode.SYSTEM
    assert graph.conan_requires == ()


def test_generated_inputs_separate_projects_from_conan_requirements() -> None:
    graph = ProjectGraphResolver(load_registry()).resolve(_DOWNSTREAM)

    projects = render_project_manifest(graph)
    conanfile = render_conanfile(graph.conan_requires)

    assert 'set(TULA_PROJECT_tula_boilerplate_MODE "cpm")' in projects
    assert str((_DOWNSTREAM / "../tula_boilerplate").resolve()) in projects
    assert "fmt/12.1.0" in conanfile
    assert "spdlog/1.17.0" in conanfile
    assert "tula-boilerplate" not in conanfile


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
    expected_name:
      default_provider: cpm
      source: {path: child}
      cmake_target: expected::target
  features: {}
"""
    )

    with pytest.raises(ValueError, match="resolved manifest 'actual_name'"):
        ProjectGraphResolver(load_registry()).resolve(tmp_path)


def test_provider_overrides_reject_duplicates_and_unused_features() -> None:
    with pytest.raises(ValueError, match="duplicate provider override"):
        parse_provider_overrides(("logging=conan", "logging=system"))

    with pytest.raises(ValueError, match="unused feature"):
        ProjectGraphResolver(load_registry()).resolve(
            _DOWNSTREAM,
            {"yaml_cpp": FeatureMode.CONAN},
        )


def test_load_project_manifest_requires_mapping(tmp_path: Path) -> None:
    (tmp_path / "tula-project.yaml").write_text("- not\n- a\n- mapping\n")

    with pytest.raises(ValueError, match="must be a mapping"):
        load_project_manifest(tmp_path)


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
    child = tmp_path / "child"
    output = tmp_path / "output"
    source.mkdir()
    child.mkdir()
    (child / "tula-project.yaml").write_text(
        """
schema_version: 1
project: {name: tula_boilerplate, version: 3.1.0}
dependencies:
  projects: {}
  features:
    logging: {default_provider: conan}
"""
    )
    (source / "tula-project.yaml").write_text(
        """
schema_version: 1
project: {name: tula_downstream, version: 3.1.0}
dependencies:
  projects:
    tula_boilerplate:
      default_provider: cpm
      source: {path: ../child}
      cmake_target: tula_boilerplate::headers
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
