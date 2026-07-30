cmake_minimum_required(VERSION 3.25)

project(tula_lib_b VERSION 0.1.0 LANGUAGES CXX)

include(CMakePackageConfigHelpers)

set(TULA_LIB_B_FLAVOR "fast" CACHE STRING "libB implementation flavor")
set_property(CACHE TULA_LIB_B_FLAVOR PROPERTY STRINGS fast safe)
if(NOT TULA_LIB_B_FLAVOR MATCHES "^(fast|safe)$")
    message(FATAL_ERROR "unsupported TULA_LIB_B_FLAVOR=${TULA_LIB_B_FLAVOR}")
endif()

configure_file(
    include/tula_lib_b/config.h.in
    generated/tula_lib_b/config.h
    @ONLY
)

add_library(tula_lib_b INTERFACE)
add_library(tula::lib_b ALIAS tula_lib_b)
set_target_properties(tula_lib_b PROPERTIES EXPORT_NAME lib_b)
target_compile_features(tula_lib_b INTERFACE cxx_std_23)
target_include_directories(
    tula_lib_b
    INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/generated>"
        "$<INSTALL_INTERFACE:include>"
)

install(TARGETS tula_lib_b EXPORT TulaLibBTargets)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_lib_b/config.h"
        DESTINATION include/tula_lib_b)
install(EXPORT TulaLibBTargets NAMESPACE tula::
        DESTINATION lib/cmake/TulaLibB)
configure_package_config_file(
    cmake/TulaLibBConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/TulaLibBConfig.cmake"
    INSTALL_DESTINATION lib/cmake/TulaLibB
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/TulaLibBConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion
)
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/TulaLibBConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/TulaLibBConfigVersion.cmake"
    DESTINATION lib/cmake/TulaLibB
)

