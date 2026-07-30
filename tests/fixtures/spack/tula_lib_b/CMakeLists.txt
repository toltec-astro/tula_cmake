cmake_minimum_required(VERSION 3.25)

project(TulaLibB VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)

find_package(TulaCMake 3 CONFIG REQUIRED)

set(TULA_LIB_B_FLAVOR "fast" CACHE STRING "libB implementation flavor")
set_property(CACHE TULA_LIB_B_FLAVOR PROPERTY STRINGS fast safe)
if(NOT TULA_LIB_B_FLAVOR MATCHES "^(fast|safe)$")
    message(FATAL_ERROR "Unsupported TULA_LIB_B_FLAVOR=${TULA_LIB_B_FLAVOR}")
endif()

add_library(tula_lib_b INTERFACE)
add_library(tula::lib_b ALIAS tula_lib_b)
set_target_properties(tula_lib_b PROPERTIES EXPORT_NAME lib_b)
tula_cmake_target_defaults(TARGET tula_lib_b WARNINGS)
tula_cmake_generate_config_header(
    TARGET tula_lib_b
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/include/tula_lib_b/config.h.in"
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_lib_b/config.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_lib_b/config.h"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/tula_lib_b"
)
tula_cmake_install_package(
    PACKAGE TulaLibB
    EXPORT TulaLibBTargets
    NAMESPACE tula::
    TARGETS tula_lib_b
)
