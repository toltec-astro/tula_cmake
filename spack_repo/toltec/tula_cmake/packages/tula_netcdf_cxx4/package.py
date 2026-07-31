"""Normalized NetCDF C++ target adapter used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaNetcdfCxx4(CMakePackage):
    """Install ``tula_deps::netcdf_cxx4`` backed by NetCDF C++4."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("4.3.1")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("pkgconf", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on("netcdf-cxx4@4.3.1", type=("build", "link"))
