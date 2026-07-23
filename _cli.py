"""Small discovery CLI for installed tula_cmake resources."""

from __future__ import annotations

import argparse
from collections.abc import Sequence

from . import profiles_dir


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="tula-cmake")
    subparsers = parser.add_subparsers(dest="command", required=True)
    profile_parser = subparsers.add_parser("profile", help="print one bundled profile path")
    profile_parser.add_argument("name")
    args = parser.parse_args(argv)

    profile = profiles_dir() / args.name
    if not profile.is_file():
        parser.error(f"unknown bundled profile: {args.name}")
    print(profile)
    return 0
