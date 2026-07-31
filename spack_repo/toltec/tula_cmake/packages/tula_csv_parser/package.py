"""Pinned CSV parser exposed through ``tula_deps::csv_parser``."""

from spack.package import depends_on, install_tree, join_path, mkdirp, version
from spack_repo.builtin.build_systems.generic import Package


class TulaCsvParser(Package):
    """Install the TolTEC csv-parser fork and a relocatable CMake target."""

    homepage = "https://github.com/Jerry-Ma/csv-parser"

    version(
        "2020.06.12",
        url="https://github.com/Jerry-Ma/csv-parser/archive/"
        "bc3bebcc16fb74144e9d94035346b3d9150b39c5.tar.gz",
        sha256="55362b6595a9869b0cc20178ebc746fa0000fa252eeca935cd906c367aa7bc7e",
    )

    depends_on("cxx", type="build")

    def install(self, spec, prefix) -> None:
        """Install headers and the normalized target config."""
        install_tree("include", prefix.include)
        config_dir = join_path(prefix.lib, "cmake", "TulaCsvParser")
        mkdirp(config_dir)
        with open(
            join_path(config_dir, "TulaCsvParserConfig.cmake"), "w"
        ) as stream:
            stream.write(
                "get_filename_component(_prefix "
                '"${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)\n'
                "if(NOT TARGET tula_deps::csv_parser)\n"
                "  add_library(tula_deps::csv_parser INTERFACE IMPORTED)\n"
                "  set_target_properties(tula_deps::csv_parser PROPERTIES "
                'INTERFACE_INCLUDE_DIRECTORIES "${_prefix}/include")\n'
                "endif()\n"
            )
