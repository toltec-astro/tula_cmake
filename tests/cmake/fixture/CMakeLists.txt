cmake_minimum_required(VERSION 3.25)

project(TulaCMakeFixture VERSION 1.2.3 LANGUAGES CXX)

include(CTest)
include(GNUInstallDirs)

find_package(TulaCMake 3 CONFIG REQUIRED)

set(TULA_CMAKE_FIXTURE_HAS_EXAMPLE 1)

add_library(tula_cmake_fixture src/fixture.cpp)
add_library(fixture::fixture ALIAS tula_cmake_fixture)
set_target_properties(
    tula_cmake_fixture
    PROPERTIES EXPORT_NAME fixture
)
tula_cmake_target_defaults(TARGET tula_cmake_fixture WARNINGS)
target_include_directories(
    tula_cmake_fixture
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
)
tula_cmake_generate_config_header(
    TARGET tula_cmake_fixture
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/include/fixture/config.h.in"
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/fixture/config.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
tula_cmake_generate_version_header(
    TARGET tula_cmake_fixture
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/fixture/version.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
    NAMESPACE fixture
    VERSION "${PROJECT_VERSION}"
    REVISION "fixture-revision"
)
tula_cmake_inspect_target(
    TARGET fixture::fixture
    LEVEL VERBOSE
)

add_executable(tula_cmake_fixture_test src/main.cpp)
tula_cmake_target_defaults(TARGET tula_cmake_fixture_test WARNINGS)
target_link_libraries(tula_cmake_fixture_test PRIVATE fixture::fixture)
add_test(
    NAME tula_cmake_fixture
    COMMAND tula_cmake_fixture_test
)

install(
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/include/fixture/fixture.h"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/fixture/config.h"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/fixture/version.h"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/fixture"
)
tula_cmake_install_package(
    PACKAGE TulaCMakeFixture
    EXPORT TulaCMakeFixtureTargets
    NAMESPACE fixture::
    VERSION "${PROJECT_VERSION}"
    TARGETS tula_cmake_fixture
)
