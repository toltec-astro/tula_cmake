"""Conan python-require distribution for the Tula superbuild infrastructure."""

from __future__ import annotations

import sys
from pathlib import Path

from conan import ConanFile

sys.path.insert(0, str(Path(__file__).parent / "src"))

from tula_cmake.recipe import TulaConan


class TulaCMakeRecipe(ConanFile):
    """Export the Python recipe mixin and its installed resources."""

    name = "tula-cmake"
    version = "3.1.0"
    description = "Conan and CMake superbuild infrastructure for TolTEC C++ packages"
    license = "BSD-3-Clause"
    url = "https://github.com/toltec-astro/tula_cmake"
    package_type = "python-require"
    required_conan_version = ">=2.31"
    exports = (
        "src/tula_cmake/*.py",
        "src/tula_cmake/py.typed",
        "src/tula_cmake/data/*",
        "src/tula_cmake/data/cmake/*/*",
        "src/tula_cmake/data/profiles/*",
        "src/tula_cmake/data/recipes/*/*",
        "src/tula_cmake/data/templates/*",
    )


__all__ = ["TulaConan"]
