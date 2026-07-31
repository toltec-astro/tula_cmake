"""Spack package for the portable performance-runtime interface."""

from spack.package import depends_on, variant, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaPerflibs(CMakePackage):
    """Install the Threads/OpenMP interface target and capability header."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("0.1.0")

    variant(
        "openmp",
        default=True,
        description="Require and propagate compiler-native OpenMP",
    )

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-cmake@3.2.0", type="build")

    def cmake_args(self) -> list[str]:
        """Translate the Spack variant into the ordinary CMake option."""
        return [
            self.define_from_variant(
                "TULA_PERFLIBS_ENABLE_OPENMP",
                "openmp",
            )
        ]
