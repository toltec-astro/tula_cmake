"""Normalized Eigen target adapter used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaEigen3(CMakePackage):
    """Install ``tula_deps::eigen3`` backed by Eigen 3."""

    homepage = "https://github.com/toltec-astro/tula_cmake"
    git = "https://github.com/toltec-astro/tula_cmake.git"
    root_cmakelists_dir = "packages/tula_eigen3"

    version("3.4.0", tag="v3.2.0")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on("eigen@3.4.0", type=("build", "link"))
