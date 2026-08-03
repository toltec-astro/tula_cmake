"""Normalized CCfits target adapter used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaCcfits(CMakePackage):
    """Install the CCfits API with its required CFITSIO implementation."""

    homepage = "https://github.com/toltec-astro/tula_cmake"
    git = "https://github.com/toltec-astro/tula_cmake.git"
    root_cmakelists_dir = "packages/tula_ccfits"

    version("1.0.0", tag="v3.2.0")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("pkgconf", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on("cfitsio@4.3:~fortran", type=("build", "link"))
    depends_on("ccfits@2.6", type=("build", "link"))
