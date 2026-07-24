"""Command-line entry points for the Tula build workflow."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path

from . import profiles_dir


def _conan_command() -> list[str]:
    executable = shutil.which("conan")
    return [executable] if executable else [sys.executable, "-m", "conan"]


def _generated_preset(source: Path) -> str:
    user_presets = source / "CMakeUserPresets.json"
    if not user_presets.is_file():
        raise RuntimeError(f"Conan did not generate {user_presets}")
    user_data = json.loads(user_presets.read_text())
    includes = user_data.get("include", [])
    if not includes:
        raise RuntimeError(f"{user_presets} does not include Conan presets")
    generated = (source / includes[0]).resolve()
    generated_data = json.loads(generated.read_text())
    build_presets = generated_data.get("buildPresets", [])
    if not build_presets:
        raise RuntimeError(f"{generated} contains no build presets")
    return str(build_presets[0]["name"])


def _run_build(args: argparse.Namespace) -> None:
    source = args.source.resolve()
    output = args.output.resolve()
    if args.config_source:
        print(
            f"==> bootstrap: install Conan configuration from {args.config_source}",
            flush=True,
        )
        subprocess.run(
            (*_conan_command(), "config", "install", args.config_source),
            check=True,
        )
    if not args.profile:
        print("==> bootstrap: ensure the default Conan profile exists", flush=True)
        subprocess.run(
            (*_conan_command(), "profile", "detect", "--exist-ok"),
            check=True,
        )
    install = [
        *_conan_command(),
        "install",
        str(source),
        "--output-folder",
        str(output),
        f"--build={args.build_policy}",
    ]
    for profile in args.profile:
        install.extend(("--profile:all", profile))
    print("==> conan: resolve the package graph and generate build files", flush=True)
    subprocess.run(install, check=True)

    preset = args.preset or _generated_preset(source)
    print(f"==> cmake: configure with preset {preset}", flush=True)
    subprocess.run(("cmake", "--preset", preset, "--fresh"), cwd=source, check=True)
    print(f"==> cmake: build with preset {preset}", flush=True)
    subprocess.run(("cmake", "--build", "--preset", preset), cwd=source, check=True)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="tula-cmake")
    subparsers = parser.add_subparsers(dest="command", required=True)

    profile_parser = subparsers.add_parser("profile", help="print one bundled profile path")
    profile_parser.add_argument("name")
    profile_parser.set_defaults(handler=None)

    build_parser = subparsers.add_parser(
        "build",
        help="run Conan install, then configure and build with its generated CMake preset",
    )
    build_parser.add_argument("source", nargs="?", type=Path, default=Path.cwd())
    build_parser.add_argument(
        "--output",
        type=Path,
        default=Path.cwd() / ".tula",
        help="Conan output root (default: .tula)",
    )
    build_parser.add_argument(
        "--profile",
        action="append",
        default=[],
        help="profile composed for both build and host contexts; may be repeated",
    )
    build_parser.add_argument(
        "--config-source",
        help="optional source passed to 'conan config install' during bootstrap",
    )
    build_parser.add_argument("--preset", help="generated CMake build preset")
    build_parser.add_argument("--build-policy", default="missing")
    build_parser.set_defaults(handler=_run_build)

    args = parser.parse_args(argv)

    if args.command == "profile":
        profile = profiles_dir() / args.name
        if not profile.is_file():
            parser.error(f"unknown bundled profile: {args.name}")
        print(profile)
    else:
        try:
            args.handler(args)
        except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
            parser.exit(1, f"tula-cmake: {error}\n")
    return 0
