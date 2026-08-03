"""Spack package for the reusable TolTEC CMake convention modules."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaCmake(CMakePackage):
    """Install the CMake-only TulaCMake package."""

    homepage = "https://github.com/toltec-astro/tula_cmake"
    git = "https://github.com/toltec-astro/tula_cmake.git"

    version("3.2.0", tag="v3.2.0")

    depends_on("cmake@3.25:", type="build")

    def cmake_args(self) -> list[str]:
        """Build the installed-consumer fixture only for requested tests."""
        return [self.define("TULA_CMAKE_BUILD_TESTING", self.run_tests)]
