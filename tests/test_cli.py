from __future__ import annotations

from typing import TYPE_CHECKING

from typer.testing import CliRunner

from tula_cmake.cli import app
from tula_cmake.resources import recipe_dir
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


def test_bootstrap_exports_bundled_dependency_recipes(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[tuple[str, ...]] = []
    monkeypatch.setattr("tula_cmake.cli.conan_command", lambda: ("conan",))
    monkeypatch.setattr(
        "tula_cmake.cli.run_command",
        lambda command: calls.append(tuple(command)),
    )

    result = runner.invoke(app, ["bootstrap"])

    assert result.exit_code == 0
    assert calls == [
        ("conan", "export", str(recipe_dir("netcdf-cxx4"))),
    ]


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
            "--provider",
            "logging=system",
        ],
    )
    assert result.exit_code == 0
    assert requests[0].profiles == ("base", "features")
    assert requests[0].options == (
        "perflibs=system",
        "perflibs_openmp=required",
    )
    assert requests[0].providers == ("logging=system",)


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
