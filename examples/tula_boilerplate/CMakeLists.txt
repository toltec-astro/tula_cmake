cmake_minimum_required(VERSION 3.25)

project(
    TulaBoilerplate
    VERSION 0.1.0
    DESCRIPTION "Minimal package using TulaCMake and the TolTEC Spack graph"
    LANGUAGES CXX
)

include(CTest)
include(GNUInstallDirs)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(TulaLibA CONFIG REQUIRED)
find_package(TulaPerflibs CONFIG REQUIRED)

set(TULA_BOILERPLATE_HAS_LOGGING 1)
set(TULA_BOILERPLATE_HAS_PERFLIBS 1)

add_library(tula_boilerplate INTERFACE)
add_library(tula_boilerplate::tula_boilerplate ALIAS tula_boilerplate)
set_target_properties(
    tula_boilerplate
    PROPERTIES EXPORT_NAME tula_boilerplate
)
tula_cmake_target_defaults(
    TARGET tula_boilerplate
    WARNINGS
)
target_include_directories(
    tula_boilerplate
    INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
)
tula_cmake_generate_config_header(
    TARGET tula_boilerplate
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/include/tula_boilerplate/config.h.in"
    OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_boilerplate/config.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
tula_cmake_generate_version_header(
    TARGET tula_boilerplate
    OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_boilerplate/version.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
    NAMESPACE tula_boilerplate
    VERSION "${PROJECT_VERSION}"
    REVISION "${TULA_BOILERPLATE_GIT_REVISION}"
)
target_link_libraries(
    tula_boilerplate
    INTERFACE
        fmt::fmt
        spdlog::spdlog
        tula::lib_a
        tula::perflibs
)

if(BUILD_TESTING)
    add_executable(tula_boilerplate_smoke src/main.cpp)
    tula_cmake_target_defaults(TARGET tula_boilerplate_smoke WARNINGS)
    target_link_libraries(
        tula_boilerplate_smoke
        PRIVATE tula_boilerplate::tula_boilerplate
    )
    add_test(NAME tula_boilerplate::smoke COMMAND tula_boilerplate_smoke)
endif()

install(
    DIRECTORY include/
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_boilerplate/config.h"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_boilerplate/version.h"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/tula_boilerplate"
)
tula_cmake_install_package(
    PACKAGE TulaBoilerplate
    EXPORT TulaBoilerplateTargets
    NAMESPACE tula_boilerplate::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_boilerplate
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaBoilerplateConfig.cmake.in"
)
