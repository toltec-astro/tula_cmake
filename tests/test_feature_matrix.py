from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

import pytest

from tula_cmake.models import BuildRequest, FeatureMode
from tula_cmake.registry import load_registry
from tula_cmake.resources import profiles_dir
from tula_cmake.workflow import BuildWorkflow

from .feature_matrix.catalog import MatrixCase, load_catalog

MATRIX_ROOT = Path(__file__).parent / "feature_matrix"
REGISTRY = load_registry()
CATALOG = load_catalog(MATRIX_ROOT / "matrix.yaml")


def _parameter(case: MatrixCase) -> Any:
    marks: list[pytest.MarkDecorator] = [pytest.mark.feature_matrix]
    if case.network:
        marks.append(pytest.mark.network)
    available = {
        value.strip()
        for value in os.environ.get("TULA_TEST_CAPABILITIES", "").split(",")
        if value.strip()
    }
    missing = set(case.capabilities) - available
    if case.profile_env is not None and not os.environ.get(case.profile_env):
        missing.add(f"profile:{case.profile_env}")
    if missing:
        marks.append(
            pytest.mark.skip(reason=f"missing test capabilities: {sorted(missing)}")
        )
    return pytest.param(case, id=case.id, marks=marks)


@pytest.mark.parametrize("case", [_parameter(case) for case in CATALOG.cases(REGISTRY)])
def test_feature_matrix(
    case: MatrixCase,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = tmp_path / "project"
    output = tmp_path / "output"
    shutil.copytree(MATRIX_ROOT / "project", source)
    probe = (
        MATRIX_ROOT / "probes" / case.probe
        if case.mode is not FeatureMode.DISABLED
        else MATRIX_ROOT / "probes" / "disabled.cpp"
    )
    shutil.copy2(probe, source / "probe.cpp")
    enabled = "ON" if case.mode is not FeatureMode.DISABLED else "OFF"
    matrix_lines = [
        f'set(TULA_MATRIX_FEATURE "{case.feature}")',
        f"set(TULA_MATRIX_EXPECT_ENABLED {enabled})",
    ]
    if case.feature == "perflibs" and case.mode is not FeatureMode.DISABLED:
        oneapi = case.options["perflibs_oneapi"]
        openmp = case.options["perflibs_openmp"]
        runtime = case.options["perflibs_openmp_runtime"]
        matrix_lines.extend(
            (
                f"set(TULA_MATRIX_EXPECT_MKL {int(oneapi == 'enabled')})",
                f'set(TULA_MATRIX_EXPECT_RUNTIME "{runtime}")',
            )
        )
        if openmp != "auto":
            matrix_lines.append(
                f"set(TULA_MATRIX_EXPECT_OPENMP {int(openmp == 'required')})"
            )
    (source / "matrix_case.cmake").write_text("\n".join((*matrix_lines, "")))
    monkeypatch.setenv(
        "CPM_SOURCE_CACHE",
        str(Path(__file__).parents[3] / ".devcontainer" / "cache" / "cpm"),
    )
    profile = (
        os.environ[case.profile_env]
        if case.profile_env is not None
        else os.environ.get(
            "TULA_TEST_PROFILE",
            str(profiles_dir() / "linux-gcc13-debug"),
        )
    )
    BuildWorkflow(
        BuildRequest(
            source=source,
            output=output,
            profiles=(profile,),
            options=case.conan_options(REGISTRY),
        )
    ).execute()

    preset_files = tuple(output.glob("**/generators/CMakePresets.json"))
    assert len(preset_files) == 1
    preset = json.loads(preset_files[0].read_text())["configurePresets"][0]
    cache = preset["cacheVariables"]
    feature = REGISTRY.features[case.feature]
    if case.mode is FeatureMode.DISABLED:
        assert all(
            option.cmake_variable not in cache for option in feature.options.values()
        )
    else:
        for option_name, option in feature.options.items():
            assert cache[option.cmake_variable] == case.options[option_name]

    ctest = shutil.which("ctest")
    assert ctest is not None
    subprocess.run(
        [
            ctest,
            "--test-dir",
            str(output / "build" / "Debug"),
            "--output-on-failure",
        ],
        check=True,
    )
