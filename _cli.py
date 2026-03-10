"""tula-cmake CLI — helper commands for downstream projects."""

import argparse
import sys
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="tula-cmake",
        description="tula v3 build system helpers",
    )
    sub = parser.add_subparsers(dest="cmd", metavar="COMMAND")

    sub.add_parser(
        "profiles-dir",
        help="Print the path to bundled Conan profiles (use with --profile=).",
    )

    setup_p = sub.add_parser(
        "setup",
        help="Ensure build/tula_cmake/ is ready for conan install (symlink or clone).",
    )
    setup_p.add_argument(
        "--project-root", type=Path, default=Path.cwd(),
        metavar="DIR",
        help="Project root (default: cwd).",
    )

    args = parser.parse_args()

    if args.cmd == "profiles-dir":
        from tula_cmake import profiles_dir
        print(profiles_dir())

    elif args.cmd == "setup":
        from tula_cmake.bootstrap import ensure_tula_cmake
        result = ensure_tula_cmake(args.project_root)
        print(f"[tula] tula_cmake ready at: {result}")

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
