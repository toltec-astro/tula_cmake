cmake_minimum_required(VERSION 3.25)

project(TulaEigen3 VERSION 3.4.0 LANGUAGES CXX)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(Eigen3 3.4 CONFIG REQUIRED)

add_library(tula_eigen3 INTERFACE)
add_library(tula_deps::eigen3 ALIAS tula_eigen3)
set_target_properties(tula_eigen3 PROPERTIES EXPORT_NAME eigen3)
target_link_libraries(tula_eigen3 INTERFACE Eigen3::Eigen)

tula_cmake_install_package(
    PACKAGE TulaEigen3
    EXPORT TulaEigen3Targets
    NAMESPACE tula_deps::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_eigen3
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaEigen3Config.cmake.in"
)
