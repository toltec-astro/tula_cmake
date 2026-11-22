"""Normalized yaml-cpp target adapter used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaYamlCpp(CMakePackage):
    """Install ``tula_deps::yaml_cpp`` backed by yaml-cpp."""

    homepage = "https://github.com/toltec-astro/tula_cmake"
    git = "https://github.com/toltec-astro/tula_cmake.git"
    @property
    def root_cmakelists_dir(self):
        """Select the focused develop tree or monorepo release subtree."""
        return "." if self.spec.is_develop else "packages/tula_yaml_cpp"

    version("1.0.0", commit="646b2d3cb4054656ec6c0ea11bc6ff331e06c208")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-cmake@3.2:3", type="build")
    depends_on("yaml-cpp@0.8.0:", type=("build", "link"))
