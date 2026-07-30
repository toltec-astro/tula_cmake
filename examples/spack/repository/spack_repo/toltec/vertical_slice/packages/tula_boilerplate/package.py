"""Spack package for the minimal TolTEC library example."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaBoilerplate(CMakePackage):
    """Consume logging, perflibs, and libA through normal CMake packages."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("0.1.0")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on("tula-logging@1", type=("build", "link"))
    depends_on("tula-lib-a@0.1.0", type=("build", "link"))
    depends_on("tula-perflibs@0.1.0", type=("build", "link"))

    def cmake_args(self) -> list[str]:
        """Enable the package smoke executable only for requested tests."""
        return [
            self.define("BUILD_TESTING", self.run_tests),
            self.define("TULA_BOILERPLATE_GIT_REVISION", "spack-fixture"),
        ]
