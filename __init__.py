"""tula_cmake — tula v3 Conan + CMake build system utilities.

Provides TulaConan (Conan recipe base class) and helpers for
locating bundled Conan profiles.

Typical downstream conanfile.py::

    try:
        from tula_cmake import TulaConan        # installed via pip
    except ImportError:
        ...                                     # fallback (see conanfile.py)

    class MyRecipe(TulaConan):
        pass
"""

from __future__ import annotations

from pathlib import Path


def profiles_dir() -> Path:
    """Return the path to the bundled Conan profiles directory.

    Works both for editable installs (points to the source tree) and
    for regular pip installs (points to the installed package data).

    Use from the command line::

        conan install . --profile=$(tula-cmake profiles-dir)/linux-clang20-debug
    """
    return Path(__file__).parent / "profiles"


def __getattr__(name: str):
    """Lazy-import TulaConan only when conan is available (i.e. inside Conan)."""
    if name == "TulaConan":
        from .tula_conan import TulaConan
        return TulaConan
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = ["TulaConan", "profiles_dir"]
