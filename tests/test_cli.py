from __future__ import annotations

from typing import TYPE_CHECKING

from typer.testing import CliRunner

from tula_cmake.cli import app
from tula_cmake.workflow import BuildWorkflow

if TYPE_CHECKING:
    import pytest

    from tula_cmake.models import BuildRequest

runner = CliRunner()


def test_profile_prints_installed_resource() -> None:
    result = runner.invoke(app, ["profile", "linux-gcc13-debug"])
    assert result.exit_code == 0
    assert result.stdout.rstrip().endswith("data/profiles/linux-gcc13-debug")


def test_profile_rejects_unknown_name() -> None:
    result = runner.invoke(app, ["profile", "missing"])
    assert result.exit_code == 2
    assert "unknown bundled profile" in result.output


def test_build_constructs_and_executes_workflow(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    requests: list[BuildRequest] = []

    def execute(workflow: BuildWorkflow) -> None:
        requests.append(workflow.request)

    monkeypatch.setattr(BuildWorkflow, "execute", execute)
    result = runner.invoke(
        app,
        [
            "build",
            ".",
            "--output",
            "out",
            "--profile",
            "base",
            "--profile",
            "features",
            "--option",
            "perflibs=system",
            "-o",
            "perflibs_openmp=required",
        ],
    )
    assert result.exit_code == 0
    assert requests[0].profiles == ("base", "features")
    assert requests[0].options == (
        "perflibs=system",
        "perflibs_openmp=required",
    )


def test_build_reads_config_source_from_environment(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    requests: list[BuildRequest] = []

    def execute(workflow: BuildWorkflow) -> None:
        requests.append(workflow.request)

    monkeypatch.setattr(BuildWorkflow, "execute", execute)
    result = runner.invoke(
        app,
        ["build", "."],
        env={"TULA_CONAN_CONFIG_SOURCE": "https://example.invalid/conan-config.zip"},
    )
    assert result.exit_code == 0
    assert requests[0].config_source == "https://example.invalid/conan-config.zip"
