cmake_minimum_required(VERSION 3.25)

project(TulaLogging VERSION 1.0.0 LANGUAGES CXX)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(fmt 9.1 CONFIG REQUIRED)
find_package(spdlog 1.12 CONFIG REQUIRED)

add_library(tula_logging INTERFACE)
add_library(tula_deps::logging ALIAS tula_logging)
set_target_properties(tula_logging PROPERTIES EXPORT_NAME logging)
target_link_libraries(tula_logging INTERFACE fmt::fmt spdlog::spdlog)

tula_cmake_install_package(
    PACKAGE TulaLogging
    EXPORT TulaLoggingTargets
    NAMESPACE tula_deps::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_logging
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaLoggingConfig.cmake.in"
)
