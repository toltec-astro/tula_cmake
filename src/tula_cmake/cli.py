"""Command-line interface for the Tula build workflow."""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Annotated

import typer

from .models import BuildRequest
from .resources import profiles_dir, recipe_dir
from .workflow import BuildWorkflow, conan_command, run_command

app = typer.Typer(
    name="tula-cmake",
    help="Bootstrap Conan and build TolTEC C++ packages through generated presets.",
    no_args_is_help=True,
)


@app.command()
def profile(name: str) -> None:
    """Print the path of a bundled Conan profile."""
    path = profiles_dir() / name
    if not path.is_file():
        raise typer.BadParameter(f"unknown bundled profile: {name}")
    typer.echo(path)


@app.command()
def bootstrap() -> None:
    """Export project-owned dependency recipes into the active Conan home."""
    for name in ("netcdf-cxx4",):
        path = recipe_dir(name)
        typer.echo(f"==> bootstrap: export {name}")
        try:
            run_command((*conan_command(), "export", str(path)))
        except (OSError, subprocess.CalledProcessError) as error:
            typer.echo(f"tula-cmake: {error}", err=True)
            raise typer.Exit(1) from error


@app.command()
def build(
    source: Annotated[
        Path,
        typer.Argument(help="Conan/CMake source directory."),
    ] = Path.cwd(),
    output: Annotated[
        Path,
        typer.Option(help="Conan output root."),
    ] = Path(".tula"),
    profiles: Annotated[
        list[str] | None,
        typer.Option("--profile", help="Profile for build and host; repeatable."),
    ] = None,
    options: Annotated[
        list[str] | None,
        typer.Option(
            "--option",
            "-o",
            help="Root-package Conan option as NAME=VALUE; repeatable.",
        ),
    ] = None,
    providers: Annotated[
        list[str] | None,
        typer.Option(
            "--provider",
            help="Root feature provider as NAME=conan|cpm|system; repeatable.",
        ),
    ] = None,
    config_source: Annotated[
        str | None,
        typer.Option(
            help="Optional source for 'conan config install'.",
            envvar="TULA_CONAN_CONFIG_SOURCE",
        ),
    ] = None,
    preset: Annotated[
        str | None,
        typer.Option(help="Override the generated CMake build preset."),
    ] = None,
    build_policy: Annotated[
        str,
        typer.Option(help="Value passed to Conan's --build option."),
    ] = "missing",
) -> None:
    """Run Conan install, CMake configure, and CMake build."""
    request = BuildRequest(
        source=source,
        output=output,
        profiles=tuple(profiles or ()),
        options=tuple(options or ()),
        providers=tuple(providers or ()),
        config_source=config_source,
        preset=preset,
        build_policy=build_policy,
    )
    try:
        BuildWorkflow(request).execute()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        typer.echo(f"tula-cmake: {error}", err=True)
        raise typer.Exit(1) from error
