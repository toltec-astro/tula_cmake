cmake_minimum_required(VERSION 3.25)

project(TulaCfitsio VERSION 1.0.0 LANGUAGES CXX)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(CFITSIO REQUIRED IMPORTED_TARGET cfitsio)
pkg_check_modules(CCFITS REQUIRED IMPORTED_TARGET CCfits)

add_library(tula_cfitsio INTERFACE)
add_library(tula_deps::cfitsio ALIAS tula_cfitsio)
set_target_properties(tula_cfitsio PROPERTIES EXPORT_NAME cfitsio)
target_link_libraries(
    tula_cfitsio
    INTERFACE
        PkgConfig::CFITSIO
        PkgConfig::CCFITS
)

tula_cmake_install_package(
    PACKAGE TulaCfitsio
    EXPORT TulaCfitsioTargets
    NAMESPACE tula_deps::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_cfitsio
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaCfitsioConfig.cmake.in"
)
