"""Conan python-require distribution for the Tula superbuild infrastructure."""

from __future__ import annotations

import sys
from pathlib import Path

from conan import ConanFile

sys.path.insert(0, str(Path(__file__).parent / "src"))

from tula_cmake.tula_conan import TulaConan  # noqa: E402,F401


class TulaCMakeRecipe(ConanFile):
    name = "tula-cmake"
    version = "3.1.0"
    package_type = "python-require"
    required_conan_version = ">=2.31"
    exports = (
        "src/tula_cmake/*.py",
        "src/tula_cmake/features.yaml",
        "src/tula_cmake/cmake/*",
        "src/tula_cmake/profiles/*",
    )
