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
    fetch_p = sub.add_parser(
        "fetch",
        help="Fetch tula_cmake into a local cache via sparse git clone.",
    )
    fetch_p.add_argument(
        "--project-root", type=Path, default=Path.cwd(),
        metavar="DIR",
        help="Project root; cache placed at <DIR>/.tula_bootstrap/ (default: cwd).",
    )
    fetch_p.add_argument(
        "--tag", default=None, metavar="TAG",
        help="Git tag/branch to fetch (default: TULA_GIT_TAG env or 'main').",
    )
    fetch_p.add_argument(
        "--repo", default=None, metavar="URL",
        help="Git repo URL (default: TULA_GIT_REPO env or the toltec-astro GitHub URL).",
    )

    args = parser.parse_args()

    if args.cmd == "profiles-dir":
        from tula_cmake import profiles_dir
        print(profiles_dir())

    elif args.cmd == "fetch":
        import os
        if args.tag:
            os.environ["TULA_GIT_TAG"] = args.tag
        if args.repo:
            os.environ["TULA_GIT_REPO"] = args.repo
        from tula_cmake.bootstrap import find_tula_cmake
        result = find_tula_cmake(args.project_root)
        print(f"[tula] tula_cmake ready at: {result}")

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
