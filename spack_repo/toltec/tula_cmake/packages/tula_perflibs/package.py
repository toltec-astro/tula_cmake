"""Spack package for the portable performance-runtime interface."""

from spack.package import depends_on, variant, version
from spack_repo.builtin.build_systems.cmake import CMakePackage


class TulaPerflibs(CMakePackage):
    """Install the Threads/OpenMP interface target and capability header."""

    homepage = "https://github.com/toltec-astro/tula_cmake"
    git = "https://github.com/toltec-astro/tula_cmake.git"
    @property
    def root_cmakelists_dir(self):
        """Select the focused develop tree or monorepo release subtree."""
        return "." if self.spec.is_develop else "packages/tula_perflibs"

    version("0.1.0", tag="v3.2.0")

    variant(
        "openmp",
        default=True,
        description="Require and propagate a compatible OpenMP runtime",
    )

    depends_on("cmake@3.25:", type="build")
    depends_on("cxx", type="build")
    depends_on("tula-cmake@3.2.0", type="build")
    depends_on(
        "llvm-openmp@20.1.8",
        when="+openmp platform=darwin",
        type=("build", "link", "run"),
    )

    def cmake_args(self) -> list[str]:
        """Translate the Spack variant into the ordinary CMake option."""
        args = [
            self.define_from_variant(
                "TULA_PERFLIBS_ENABLE_OPENMP",
                "openmp",
            )
        ]
        if self.spec.satisfies("+openmp platform=darwin"):
            runtime = self.spec["llvm-openmp"]
            args.extend(
                [
                    self.define("OpenMP_CXX_FLAGS", "-fopenmp"),
                    self.define(
                        "OpenMP_CXX_INCLUDE_DIR",
                        runtime.headers.directories[0],
                    ),
                    self.define("OpenMP_CXX_LIB_NAMES", "omp"),
                    self.define("OpenMP_omp_LIBRARY", runtime.libs[0]),
                ]
            )
        return args
