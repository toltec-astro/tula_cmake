from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from tula_cmake.models import BuildRequest
from tula_cmake.resources import profiles_dir
from tula_cmake.workflow import BuildWorkflow


def test_generated_preset_is_read_through_models(tmp_path: Path) -> None:
    generated = tmp_path / "build" / "generators" / "CMakePresets.json"
    generated.parent.mkdir(parents=True)
    generated.write_text(json.dumps({"buildPresets": [{"name": "conan-debug"}]}))
    (tmp_path / "CMakeUserPresets.json").write_text(
        json.dumps({"include": ["build/generators/CMakePresets.json"]})
    )
    assert BuildWorkflow._generated_preset(tmp_path) == "conan-debug"


def test_workflow_runs_conan_then_generated_cmake_presets(
    tmp_path: Path,
) -> None:
    generated = tmp_path / "build" / "generators" / "CMakePresets.json"
    generated.parent.mkdir(parents=True)
    generated.write_text(json.dumps({"buildPresets": [{"name": "conan-debug"}]}))
    (tmp_path / "CMakeUserPresets.json").write_text(
        json.dumps({"include": ["build/generators/CMakePresets.json"]})
    )
    calls: list[tuple[tuple[str, ...], Path | None]] = []

    def record(command: Any, cwd: Path | None) -> None:
        calls.append((tuple(command), cwd))

    request = BuildRequest(
        source=tmp_path,
        output=tmp_path / "build",
        profiles=("base-profile", "feature-profile"),
        options=("perflibs=system", "perflibs_openmp=required"),
    )
    BuildWorkflow(request, runner=record).execute()

    assert calls[0][0][1:3] == ("install", str(tmp_path))
    assert calls[0][0].count("--profile:all") == 2
    assert calls[0][0].count("--options:host") == 2
    assert "&:perflibs=system" in calls[0][0]
    assert "&:perflibs_openmp=required" in calls[0][0]
    assert calls[1] == (
        ("cmake", "--preset", "conan-debug", "--fresh"),
        tmp_path,
    )
    assert calls[2] == (
        ("cmake", "--build", "--preset", "conan-debug"),
        tmp_path,
    )


def test_workflow_uses_bundled_platform_profile_by_default(
    tmp_path: Path,
    monkeypatch: Any,
) -> None:
    generated = tmp_path / "build" / "generators" / "CMakePresets.json"
    generated.parent.mkdir(parents=True)
    generated.write_text(json.dumps({"buildPresets": [{"name": "conan-debug"}]}))
    (tmp_path / "CMakeUserPresets.json").write_text(
        json.dumps({"include": ["build/generators/CMakePresets.json"]})
    )
    calls: list[tuple[tuple[str, ...], Path | None]] = []

    def record(command: Any, cwd: Path | None) -> None:
        calls.append((tuple(command), cwd))

    monkeypatch.setattr("tula_cmake.workflow.sys.platform", "darwin")
    BuildWorkflow(
        BuildRequest(source=tmp_path, output=tmp_path / "build"),
        runner=record,
    ).execute()

    assert calls[0][0].count("--profile:all") == 1
    assert str(profiles_dir() / "macos-brew-llvm-debug") in calls[0][0]
