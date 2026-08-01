cmake_minimum_required(VERSION 3.25)

project(TulaCcfits VERSION 1.0.0 LANGUAGES CXX)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(CFITSIO REQUIRED IMPORTED_TARGET cfitsio)
pkg_check_modules(CCFITS REQUIRED IMPORTED_TARGET CCfits)

add_library(tula_ccfits INTERFACE)
add_library(tula_deps::ccfits ALIAS tula_ccfits)
set_target_properties(tula_ccfits PROPERTIES EXPORT_NAME ccfits)
target_link_libraries(
    tula_ccfits
    INTERFACE
        PkgConfig::CFITSIO
        PkgConfig::CCFITS
)

tula_cmake_install_package(
    PACKAGE TulaCcfits
    EXPORT TulaCcfitsTargets
    NAMESPACE tula_deps::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_ccfits
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaCcfitsConfig.cmake.in"
)
