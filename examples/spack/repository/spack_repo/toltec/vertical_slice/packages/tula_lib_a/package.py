"""Spack package for the transitive libA fixture."""

from spack.package import depends_on, variant, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaLibA(CMakePackage):
    """Small CMake package with a user-selectable flavor."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("0.1.0")

    variant(
        "flavor",
        default="vanilla",
        values=("vanilla", "chocolate"),
        multi=False,
        description="Observable libA implementation flavor",
    )

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-cmake@3.2.0", type="build")

    def cmake_args(self) -> list[str]:
        """Map the Spack variant to the package's ordinary CMake option."""
        return [
            self.define(
                "TULA_LIB_A_FLAVOR",
                self.spec.variants["flavor"].value,
            )
        ]
