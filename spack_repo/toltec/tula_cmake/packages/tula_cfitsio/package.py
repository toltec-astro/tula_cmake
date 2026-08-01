"""Normalized CFITSIO/CCfits target adapter used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaCfitsio(CMakePackage):
    """Install ``tula_deps::cfitsio`` backed by CFITSIO and CCfits."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("1.0.0")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("pkgconf", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on("cfitsio@4.3:~fortran", type=("build", "link"))
    depends_on("ccfits@2.6", type=("build", "link"))
