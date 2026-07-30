cmake_minimum_required(VERSION 3.25)

project(tula_lib_a VERSION 0.1.0 LANGUAGES CXX)

include(CMakePackageConfigHelpers)

set(TULA_LIB_A_FLAVOR "vanilla" CACHE STRING "libA implementation flavor")
set_property(CACHE TULA_LIB_A_FLAVOR PROPERTY STRINGS vanilla chocolate)
if(NOT TULA_LIB_A_FLAVOR MATCHES "^(vanilla|chocolate)$")
    message(FATAL_ERROR "unsupported TULA_LIB_A_FLAVOR=${TULA_LIB_A_FLAVOR}")
endif()

configure_file(
    include/tula_lib_a/config.h.in
    generated/tula_lib_a/config.h
    @ONLY
)

add_library(tula_lib_a INTERFACE)
add_library(tula::lib_a ALIAS tula_lib_a)
set_target_properties(tula_lib_a PROPERTIES EXPORT_NAME lib_a)
target_compile_features(tula_lib_a INTERFACE cxx_std_23)
target_include_directories(
    tula_lib_a
    INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/generated>"
        "$<INSTALL_INTERFACE:include>"
)

install(TARGETS tula_lib_a EXPORT TulaLibATargets)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_lib_a/config.h"
        DESTINATION include/tula_lib_a)
install(EXPORT TulaLibATargets NAMESPACE tula::
        DESTINATION lib/cmake/TulaLibA)
configure_package_config_file(
    cmake/TulaLibAConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/TulaLibAConfig.cmake"
    INSTALL_DESTINATION lib/cmake/TulaLibA
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/TulaLibAConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion
)
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/TulaLibAConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/TulaLibAConfigVersion.cmake"
    DESTINATION lib/cmake/TulaLibA
)

