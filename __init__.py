"""tula_cmake — tula v3 Conan + CMake build system utilities.

Provides TulaConan (Conan recipe base class) and helpers for
locating bundled Conan profiles.

Typical downstream conanfile.py::

    from tula_cmake import TulaConan

    class MyRecipe(TulaConan):
        pass

    if __name__ == "__main__":
        import sys
        from tula_cmake import run_conan
        raise SystemExit(run_conan(sys.argv[1:]))
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path


def profiles_dir() -> Path:
    """Return the path to the bundled Conan profiles directory.

    Works both for editable installs (points to the source tree) and
    for regular pip installs (points to the installed package data).

    Use from the command line::

        conan install . --profile=$(tula-cmake profiles-dir)/linux-clang20-debug
    """
    return Path(__file__).parent / "profiles"


def run_conan(argv: list[str]) -> int:
    """Forward *argv* to ``conan``, resolving tula base profiles.

    Project profiles declare their tula base profile by name via a comment::

        # tula-base: linux-clang20-debug

    When ``--profile=<path>`` resolves to a file with that comment,
    ``run_conan`` prepends ``--profile=<abs-path>`` for the named tula
    profile so Conan sees both in order.  No hardcoded paths in profile
    files, works whether tula_cmake is a monorepo sibling or pip-installed.

    All ``--profile:build=``, ``--profile:host=``, ``-pr:b=``,
    ``-pr:h=`` variants are handled the same way.
    """
    _PROFILE_FLAGS = {
        "--profile", "-pr",
        "--profile:build", "-pr:b",
        "--profile:host", "-pr:h",
    }
    _BASE_RE = re.compile(r"^\s*#\s*tula-base:\s*(\S+)", re.MULTILINE)

    expanded: list[str] = []
    for arg in argv:
        prefix, sep, value = arg.partition("=")
        if sep and prefix in _PROFILE_FLAGS:
            p = Path(value)
            if p.exists():
                m = _BASE_RE.search(p.read_text())
                if m:
                    base_path = profiles_dir() / m.group(1)
                    expanded.append(f"{prefix}={base_path}")
        expanded.append(arg)

    return subprocess.run(["conan"] + expanded).returncode


def __getattr__(name: str):
    """Lazy-import TulaConan only when conan is available (i.e. inside Conan)."""
    if name == "TulaConan":
        from .tula_conan import TulaConan
        return TulaConan
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = ["TulaConan", "profiles_dir", "run_conan"]
