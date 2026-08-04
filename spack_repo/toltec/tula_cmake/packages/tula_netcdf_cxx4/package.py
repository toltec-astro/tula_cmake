"""Normalized NetCDF C++ target adapter used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaNetcdfCxx4(CMakePackage):
    """Install ``tula_deps::netcdf_cxx4`` backed by NetCDF C++4."""

    homepage = "https://github.com/toltec-astro/tula_cmake"
    git = "https://github.com/toltec-astro/tula_cmake.git"
    @property
    def root_cmakelists_dir(self):
        """Select the focused develop tree or monorepo release subtree."""
        return "." if self.spec.is_develop else "packages/tula_netcdf_cxx4"

    version("4.3.1", tag="v3.2.0")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("pkgconf", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on("netcdf-cxx4@4.3.1", type=("build", "link"))
