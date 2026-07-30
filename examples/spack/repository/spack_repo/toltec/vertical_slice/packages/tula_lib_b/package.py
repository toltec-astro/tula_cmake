"""Spack package for the root's direct libB fixture."""

from spack.package import depends_on, variant, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaLibB(CMakePackage):
    """Small CMake package with a user-selectable flavor."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("0.1.0")

    variant(
        "flavor",
        default="fast",
        values=("fast", "safe"),
        multi=False,
        description="Observable libB implementation flavor",
    )

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")

    def cmake_args(self) -> list[str]:
        """Map the Spack variant to the package's ordinary CMake option."""
        return [
            self.define(
                "TULA_LIB_B_FLAVOR",
                self.spec.variants["flavor"].value,
            )
        ]
