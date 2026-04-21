"""
tula_cmake bootstrap utility.

Creates ``<project>/build/tula_cmake/`` — a stable, predictable location
for the tula_cmake directory that project profiles can reference with a
plain Conan 2 ``include()``:

    include(../build/tula_cmake/profiles/linux-clang20-debug)

Resolution order (first match wins):

  1. Sibling directory: ``<project>/../tula/tula_cmake/`` — monorepo layout.
     A symlink is created at ``build/tula_cmake → <abs-sibling-path>``.

  2. Environment variable: ``TULA_CMAKE_DIR``
     A symlink is created pointing at that directory.

  3. Git sparse-checkout: clones only ``tula_cmake/`` from the tula repo
     (or from ``TULA_GIT_REPO``) directly into ``build/tula_cmake/``.

After ``ensure_tula_cmake()`` returns, ``build/tula_cmake/`` exists and the
native ``conan install . --profile=profiles/clang20-debug`` command works
without any Python magic — the profile resolves the include path itself.

Usage in a downstream conanfile.py::

    if __name__ == "__main__":
        import sys
        from pathlib import Path
        from tula_cmake.bootstrap import ensure_tula_cmake
        ensure_tula_cmake(Path(__file__).parent)
        import subprocess
        raise SystemExit(subprocess.run(["conan"] + sys.argv[1:]).returncode)
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def ensure_tula_cmake(project_root: Path) -> Path:
    """Ensure ``<project_root>/build/tula_cmake/`` exists and is valid.

    Creates a symlink (monorepo / TULA_CMAKE_DIR) or a sparse git clone.
    Returns the path ``<project_root>/build/tula_cmake/``.

    Idempotent: if the target already exists and contains ``profiles/``,
    returns immediately without any network access.
    """
    project_root = project_root.resolve()
    target = project_root / "build" / "tula_cmake"

    if _is_valid(target):
        _sync_profiles(target)
        return target

    target.parent.mkdir(parents=True, exist_ok=True)

    # 1. Monorepo sibling: <project>/../tula/tula_cmake/
    sibling = project_root.parent / "tula" / "tula_cmake"
    if _is_valid(sibling):
        _symlink(target, sibling)
        _sync_profiles(target)
        return target

    # 2. TULA_CMAKE_DIR environment variable
    env_dir = os.environ.get("TULA_CMAKE_DIR", "")
    if env_dir:
        p = Path(env_dir)
        if _is_valid(p):
            _symlink(target, p)
            _sync_profiles(target)
            return target
        print(f"[tula] WARNING: TULA_CMAKE_DIR={env_dir!r} has no profiles/; ignoring.")

    # 3. Git sparse-checkout directly into build/tula_cmake/
    _sparse_clone(target)

    if not _is_valid(target):
        raise RuntimeError(
            f"tula_cmake bootstrap failed — {target} is missing profiles/.\n"
            "Check your internet connection or set TULA_CMAKE_DIR."
        )
    _sync_profiles(target)
    return target


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _sync_profiles(tula_cmake_dir: Path) -> None:
    """Copy profiles/ from tula_cmake to ~/.conan2/profiles/.

    Conan 2 resolves ``include()`` in profiles by searching ~/.conan2/profiles/
    *before* the including file's directory.  We must keep the Conan home
    profiles in sync with the tula_cmake source so that edits take effect.
    """
    import shutil
    src = (tula_cmake_dir / "profiles").resolve()
    if not src.is_dir():
        return
    conan_home = Path(os.environ.get("CONAN_HOME", Path.home() / ".conan2"))
    dst = conan_home / "profiles"
    dst.mkdir(parents=True, exist_ok=True)
    # Copy every file/subdir from src into dst (overwrite, but leave other
    # profiles the user may have in dst untouched).
    for item in src.rglob("*"):
        rel = item.relative_to(src)
        target_item = dst / rel
        if item.is_dir():
            target_item.mkdir(parents=True, exist_ok=True)
        else:
            target_item.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target_item)


def _is_valid(p: Path) -> bool:
    """True if *p* looks like a tula_cmake directory."""
    return (p / "profiles").is_dir()


def _symlink(target: Path, source: Path) -> None:
    if target.is_symlink():
        target.unlink()
    target.symlink_to(source.resolve())
    print(f"[tula] build/tula_cmake → {source.resolve()}")


def _sparse_clone(target: Path) -> None:
    """Sparse-clone only tula_cmake/ from the tula repo into *target*."""
    repo = os.environ.get(
        "TULA_GIT_REPO",
        "https://github.com/toltec-astro/tula_cmake.git",
    )
    tag = os.environ.get("TULA_GIT_TAG", "main")

    print(f"[tula] Fetching tula_cmake ({tag}) from {repo}")
    print(f"[tula] Target: {target}")

    if target.exists():
        # Repo already cloned but profiles/ missing — repair sparse-checkout
        subprocess.run(
            ["git", "-C", str(target), "sparse-checkout", "set", "."],
            check=True,
        )
        subprocess.run(["git", "-C", str(target), "checkout"], check=True)
    else:
        subprocess.run(
            [
                "git", "clone",
                "--depth=1",
                "--filter=blob:none",
                repo,
                str(target),
            ],
            check=True,
        )


# ---------------------------------------------------------------------------
# Script entry-point: python -m tula_cmake.bootstrap [--project-root DIR]
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Bootstrap build/tula_cmake/ for a downstream project."
    )
    parser.add_argument(
        "--project-root", type=Path, default=Path.cwd(),
        help="Project root (default: cwd).",
    )
    args = parser.parse_args()

    result = ensure_tula_cmake(args.project_root)
    print(f"[tula] tula_cmake ready at: {result}")
    sys.exit(0)
