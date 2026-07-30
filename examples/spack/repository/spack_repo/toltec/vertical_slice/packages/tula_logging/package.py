"""Compatible fmt and spdlog pair used by TolTEC projects."""

from spack.package import depends_on, version
from spack_repo.builtin.build_systems.bundle import BundlePackage


class TulaLogging(BundlePackage):
    """No-code bundle defining the supported logging implementation."""

    homepage = "https://github.com/toltec-astro/tula_cmake"

    version("1.0.0")

    # spdlog 1.12 declares this fmt compatibility range. Keeping the exact pair
    # here makes logging policy visible as one graph node and lets the GCC 13
    # dev container reuse its matching distro installations as externals.
    depends_on("fmt@9.1.0", type=("build", "link"))
    depends_on("spdlog@1.12.0", type=("build", "link"))
