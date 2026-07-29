"""Conan recipe for Unidata's netCDF C++4 library."""

from __future__ import annotations

from pathlib import Path
from typing import ClassVar

from conan import ConanFile
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.files import copy, get

required_conan_version = ">=2.31"


class NetcdfCxx4Recipe(ConanFile):
    """Conan 2 package for Unidata's separate netCDF C++4 library."""

    name = "netcdf-cxx4"
    version = "4.3.1"
    description = "Unidata netCDF C++4 library"
    license = "BSD-3-Clause"
    url = "https://github.com/Unidata/netcdf-cxx4"
    homepage = "https://github.com/Unidata/netcdf-cxx4"
    package_type = "static-library"
    settings = "os", "arch", "compiler", "build_type"
    options: ClassVar = {"fPIC": [True, False]}
    default_options: ClassVar = {"fPIC": True}
    exports_sources = "conan-CMakeLists.txt"

    def requirements(self) -> None:
        self.requires(
            "netcdf/4.8.1",
            transitive_headers=True,
            transitive_libs=True,
        )

    def source(self) -> None:
        get(
            self,
            ("https://github.com/Unidata/netcdf-cxx4/archive/refs/tags/v4.3.1.tar.gz"),
            sha256=("e3fe3d2ec06c1c2772555bf1208d220aab5fee186d04bd265219b0bc7a978edc"),
            strip_root=True,
        )
        source = Path(self.source_folder)
        (source / "conan-CMakeLists.txt").replace(source / "CMakeLists.txt")

    def layout(self) -> None:
        cmake_layout(self)

    def generate(self) -> None:
        CMakeDeps(self).generate()
        CMakeToolchain(self).generate()

    def build(self) -> None:
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self) -> None:
        copy(
            self,
            "COPYRIGHT",
            src=self.source_folder,
            dst=Path(self.package_folder) / "licenses",
        )
        CMake(self).install()

    def package_info(self) -> None:
        self.cpp_info.set_property("cmake_file_name", "netCDFCxx")
        self.cpp_info.set_property(
            "cmake_target_name",
            "netCDF::netcdf-cxx4",
        )
        self.cpp_info.libs = ["netcdf-cxx4"]
