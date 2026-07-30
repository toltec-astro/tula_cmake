"""Spack package for the complete downstream executable."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaDownstream(CMakePackage):
    """Root package with a direct libB and transitive libA."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("0.1.0")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-boilerplate@0.1.0", type=("build", "link"))
    depends_on("tula-lib-b@0.1.0", type=("build", "link"))
