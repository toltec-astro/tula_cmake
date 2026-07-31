cmake_minimum_required(VERSION 3.25)

project(TulaYamlCpp VERSION 0.8.0 LANGUAGES CXX)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(yaml-cpp 0.8 CONFIG REQUIRED)

add_library(tula_yaml_cpp INTERFACE)
add_library(tula_deps::yaml_cpp ALIAS tula_yaml_cpp)
set_target_properties(tula_yaml_cpp PROPERTIES EXPORT_NAME yaml_cpp)
target_link_libraries(tula_yaml_cpp INTERFACE yaml-cpp::yaml-cpp)

tula_cmake_install_package(
    PACKAGE TulaYamlCpp
    EXPORT TulaYamlCppTargets
    NAMESPACE tula_deps::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_yaml_cpp
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaYamlCppConfig.cmake.in"
)
