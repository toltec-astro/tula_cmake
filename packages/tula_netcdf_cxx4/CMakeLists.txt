cmake_minimum_required(VERSION 3.25)

project(TulaNetcdfCxx4 VERSION 4.3.1 LANGUAGES CXX)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(NETCDF_CXX4 REQUIRED IMPORTED_TARGET netcdf-cxx4)

add_library(tula_netcdf_cxx4 INTERFACE)
add_library(tula_deps::netcdf_cxx4 ALIAS tula_netcdf_cxx4)
set_target_properties(
    tula_netcdf_cxx4
    PROPERTIES EXPORT_NAME netcdf_cxx4
)
target_link_libraries(
    tula_netcdf_cxx4
    INTERFACE PkgConfig::NETCDF_CXX4
)

tula_cmake_install_package(
    PACKAGE TulaNetcdfCxx4
    EXPORT TulaNetcdfCxx4Targets
    NAMESPACE tula_deps::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_netcdf_cxx4
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaNetcdfCxx4Config.cmake.in"
)
