cmake_minimum_required(VERSION 3.25)

project(TulaNetcdfCxx4 VERSION 4.3.1 LANGUAGES CXX)

include(GNUInstallDirs)
find_package(TulaCMake 3 CONFIG REQUIRED)
include(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaNetcdfCxx4Dependency.cmake"
)

add_library(tula_netcdf_cxx4 INTERFACE)
add_library(tula_deps::netcdf_cxx4 ALIAS tula_netcdf_cxx4)
set_target_properties(
    tula_netcdf_cxx4
    PROPERTIES EXPORT_NAME netcdf_cxx4
)
target_link_libraries(
    tula_netcdf_cxx4
    INTERFACE
        "${TulaNetcdfCxx4_CXX_LIBRARY}"
        "${TulaNetcdfCxx4_C_LIBRARY}"
)
target_include_directories(
    tula_netcdf_cxx4
    INTERFACE "${TulaNetcdfCxx4_INCLUDE_DIR}"
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
