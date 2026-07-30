cmake_minimum_required(VERSION 3.25)

project(TulaLibA VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)

find_package(TulaCMake 3 CONFIG REQUIRED)

set(TULA_LIB_A_FLAVOR "vanilla" CACHE STRING "libA implementation flavor")
set_property(CACHE TULA_LIB_A_FLAVOR PROPERTY STRINGS vanilla chocolate)
if(NOT TULA_LIB_A_FLAVOR MATCHES "^(vanilla|chocolate)$")
    message(FATAL_ERROR "Unsupported TULA_LIB_A_FLAVOR=${TULA_LIB_A_FLAVOR}")
endif()

add_library(tula_lib_a INTERFACE)
add_library(tula::lib_a ALIAS tula_lib_a)
set_target_properties(tula_lib_a PROPERTIES EXPORT_NAME lib_a)
tula_cmake_target_defaults(TARGET tula_lib_a WARNINGS)
tula_cmake_generate_config_header(
    TARGET tula_lib_a
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/include/tula_lib_a/config.h.in"
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_lib_a/config.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_lib_a/config.h"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/tula_lib_a"
)
tula_cmake_install_package(
    PACKAGE TulaLibA
    EXPORT TulaLibATargets
    NAMESPACE tula::
    TARGETS tula_lib_a
)
