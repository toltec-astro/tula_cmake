cmake_minimum_required(VERSION 3.25)

project(TulaCMake VERSION 3.2.0 LANGUAGES NONE)

include(CMakePackageConfigHelpers)
if(NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(
        CMAKE_INSTALL_LIBDIR lib
        CACHE PATH "Object code libraries"
    )
endif()
include(GNUInstallDirs)

option(
    TULA_CMAKE_BUILD_TESTING
    "Build the TulaCMake fixture and installed-consumer tests"
    "${PROJECT_IS_TOP_LEVEL}"
)

set(
    TULA_CMAKE_MODULES
    cmake/TulaCMake.cmake
    cmake/TulaCMakeConfigHeader.cmake
    cmake/TulaCMakeGitVersion.cmake
    cmake/TulaCMakeInspectTarget.cmake
    cmake/TulaCMakeInstallPackage.cmake
    cmake/TulaCMakeLog.cmake
    cmake/TulaCMakeTargetDefaults.cmake
)

set(TULA_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/TulaCMake")

configure_package_config_file(
    cmake/TulaCMakeConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/TulaCMakeConfig.cmake"
    INSTALL_DESTINATION "${TULA_CMAKE_INSTALL_DIR}"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/TulaCMakeConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        ${TULA_CMAKE_MODULES}
        "${CMAKE_CURRENT_BINARY_DIR}/TulaCMakeConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/TulaCMakeConfigVersion.cmake"
    DESTINATION "${TULA_CMAKE_INSTALL_DIR}"
)

if(TULA_CMAKE_BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests/cmake)
endif()
