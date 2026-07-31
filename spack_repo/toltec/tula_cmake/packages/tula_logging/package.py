"""Normalized fmt/spdlog target adapter used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaLogging(CMakePackage):
    """Install ``tula_deps::logging`` backed by fmt and spdlog."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("1.0.0")

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on("fmt@9.1.0", type=("build", "link"))
    depends_on("spdlog@1.12.0", type=("build", "link"))
