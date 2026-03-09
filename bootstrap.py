"""
tula_cmake bootstrap utility.

Locates tula_cmake (the directory containing tula_conan.py) via three
strategies, in order:

  1. Sibling directory: <project_root>/../tula/tula_cmake/
     Used in monorepo / side-by-side clone layouts.

  2. Environment variable: TULA_CMAKE_DIR
     Useful for CI or custom tula installations.

  3. Local sparse-checkout cache: <project_root>/.tula_bootstrap/tula/tula_cmake/
     Populated automatically by a git sparse-checkout that fetches only the
     tula_cmake/ subdirectory from GitHub.  The repo URL and tag are also
     overridable via environment variables:
       TULA_GIT_REPO  (default: https://github.com/toltec-astro/tula.git)
       TULA_GIT_TAG   (default: main)

Usage — from a downstream conanfile.py
---------------------------------------
    import sys
    from pathlib import Path
    from tula_cmake.bootstrap import find_tula_cmake   # only works if tula is already
                                                        # a sibling — circular otherwise!

For the truly standalone case (no tula on disk yet) copy the inline snippet
from the bottom of this file into the downstream conanfile.py directly.
The snippet is self-contained and has no imports beyond the stdlib.

Usage — as a script (pre-fetch tula_cmake into a cache)
---------------------------------------------------------
    python bootstrap.py [--cache-dir .tula_bootstrap] [--tag v3]
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def find_tula_cmake(project_root: Path | None = None) -> Path:
    """Return the Path to a valid tula_cmake directory.

    Searches in this order:
      1. Sibling ../tula/tula_cmake/ relative to *project_root*
      2. TULA_CMAKE_DIR environment variable
      3. Sparse-checkout cache in <project_root>/.tula_bootstrap/

    Args:
        project_root: Directory of the project's conanfile.py.
                      Defaults to the directory that contains *this* file's
                      parent (i.e. the tula repo root), which is useful when
                      running the script standalone.

    Returns:
        Path to tula_cmake directory (guaranteed to contain tula_conan.py).

    Raises:
        RuntimeError if tula_cmake cannot be found or fetched.
    """
    if project_root is None:
        project_root = Path(__file__).parent.parent  # tula_cmake/../  = tula repo root

    # 1. Sibling directory
    sibling = project_root.parent / "tula" / "tula_cmake"
    if (sibling / "tula_conan.py").exists():
        return sibling

    # 2. Environment variable override
    env_dir = os.environ.get("TULA_CMAKE_DIR", "")
    if env_dir:
        p = Path(env_dir)
        if (p / "tula_conan.py").exists():
            return p
        print(f"[tula] WARNING: TULA_CMAKE_DIR={env_dir!r} does not contain "
              f"tula_conan.py; ignoring.")

    # 3. Sparse-checkout cache
    cache_tula = project_root / ".tula_bootstrap" / "tula"
    tula_cmake = cache_tula / "tula_cmake"
    if not (tula_cmake / "tula_conan.py").exists():
        _sparse_clone(cache_tula, project_root)

    if not (tula_cmake / "tula_conan.py").exists():
        raise RuntimeError(
            f"tula_cmake not found after fetch.  Expected: {tula_cmake}\n"
            "Check your internet connection or set TULA_CMAKE_DIR."
        )
    return tula_cmake


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _sparse_clone(target_dir: Path, project_root: Path) -> None:
    """Clone only the tula_cmake/ subtree of the tula repo into *target_dir*."""
    repo = os.environ.get("TULA_GIT_REPO",
                          "https://github.com/toltec-astro/tula.git")
    tag  = os.environ.get("TULA_GIT_TAG", "main")

    print(f"[tula] tula_cmake not found locally.")
    print(f"[tula] Fetching tula_cmake ({tag}) from {repo}")
    print(f"[tula] Cache: {target_dir}")

    target_dir.parent.mkdir(parents=True, exist_ok=True)

    if target_dir.exists():
        # Already cloned but tula_conan.py missing — try sparse-checkout repair
        subprocess.run(
            ["git", "-C", str(target_dir), "sparse-checkout", "set", "tula_cmake"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(target_dir), "checkout"],
            check=True,
        )
    else:
        # Fresh sparse clone — only materialise tula_cmake/
        subprocess.run(
            [
                "git", "clone",
                "--depth=1",
                "--filter=blob:none",
                "--sparse",
                "--branch", tag,
                repo,
                str(target_dir),
            ],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(target_dir), "sparse-checkout", "set", "tula_cmake"],
            check=True,
        )


# ---------------------------------------------------------------------------
# Inline snippet — copy this into a downstream conanfile.py
# ---------------------------------------------------------------------------
#
# The snippet below is self-contained (stdlib only) and can be pasted
# verbatim into any downstream conanfile.py that needs to bootstrap
# tula_cmake without a sibling tula/ directory on disk.
#
# ----- cut here -----
#
# import os, subprocess, sys
# from pathlib import Path
#
# def _find_tula_cmake(project_root: Path = Path(__file__).parent) -> Path:
#     """Locate tula_cmake locally or fetch from GitHub (sparse clone)."""
#     # 1. Sibling directory
#     sibling = project_root.parent / "tula" / "tula_cmake"
#     if (sibling / "tula_conan.py").exists():
#         return sibling
#     # 2. Environment variable
#     if (env := os.environ.get("TULA_CMAKE_DIR")):
#         p = Path(env)
#         if (p / "tula_conan.py").exists():
#             return p
#     # 3. Sparse-checkout cache
#     cache = project_root / ".tula_bootstrap" / "tula"
#     tula_cmake = cache / "tula_cmake"
#     if not (tula_cmake / "tula_conan.py").exists():
#         repo = os.environ.get("TULA_GIT_REPO", "https://github.com/toltec-astro/tula.git")
#         tag  = os.environ.get("TULA_GIT_TAG",  "main")
#         print(f"[tula] fetching tula_cmake ({tag}) from {repo} → {cache.parent}")
#         cache.parent.mkdir(parents=True, exist_ok=True)
#         subprocess.run(["git", "clone", "--depth=1", "--filter=blob:none",
#                         "--sparse", "--branch", tag, repo, str(cache)], check=True)
#         subprocess.run(["git", "-C", str(cache), "sparse-checkout", "set",
#                         "tula_cmake"], check=True)
#     return tula_cmake
#
# sys.path.insert(0, str(_find_tula_cmake()))
# from tula_conan import TulaConan
#
# ----- cut here -----


# ---------------------------------------------------------------------------
# Script entry-point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Fetch tula_cmake from GitHub into a local sparse-checkout cache."
    )
    parser.add_argument(
        "--project-root", type=Path, default=Path.cwd(),
        help="Project root (default: cwd).  Cache will be placed at "
             "<project-root>/.tula_bootstrap/",
    )
    parser.add_argument(
        "--tag", default=None,
        help="Git tag/branch to fetch (default: TULA_GIT_TAG env or 'main').",
    )
    parser.add_argument(
        "--repo", default=None,
        help="Git repo URL (default: TULA_GIT_REPO env or the toltec-astro GitHub URL).",
    )
    args = parser.parse_args()

    if args.tag:
        os.environ["TULA_GIT_TAG"] = args.tag
    if args.repo:
        os.environ["TULA_GIT_REPO"] = args.repo

    result = find_tula_cmake(args.project_root)
    print(f"[tula] tula_cmake ready at: {result}")
    sys.exit(0)
