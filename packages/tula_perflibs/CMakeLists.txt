cmake_minimum_required(VERSION 3.25)

project(TulaPerflibs VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(Threads REQUIRED)

option(TULA_PERFLIBS_ENABLE_OPENMP "Require and export an OpenMP runtime" ON)
if(TULA_PERFLIBS_ENABLE_OPENMP)
    find_package(OpenMP REQUIRED COMPONENTS CXX)
endif()

set(TULA_PERFLIBS_HAS_THREADS 1)
if(TULA_PERFLIBS_ENABLE_OPENMP)
    set(TULA_PERFLIBS_HAS_OPENMP 1)
else()
    set(TULA_PERFLIBS_HAS_OPENMP 0)
endif()

add_library(tula_perflibs INTERFACE)
add_library(tula_deps::perflibs ALIAS tula_perflibs)
set_target_properties(tula_perflibs PROPERTIES EXPORT_NAME perflibs)
tula_cmake_target_defaults(TARGET tula_perflibs WARNINGS)
target_link_libraries(tula_perflibs INTERFACE Threads::Threads)
if(TULA_PERFLIBS_ENABLE_OPENMP)
    target_link_libraries(tula_perflibs INTERFACE OpenMP::OpenMP_CXX)
endif()

# FindOpenMP's imported target is not exported by CMake. Preserve the resolved
# inputs so installed consumers reconstruct the same runtime instead of probing
# their host and accidentally selecting a different libomp.
set(TULA_PERFLIBS_OPENMP_CACHE "")
if(TULA_PERFLIBS_ENABLE_OPENMP)
    string(APPEND TULA_PERFLIBS_OPENMP_CACHE
        "set(OpenMP_CXX_FLAGS [==[${OpenMP_CXX_FLAGS}]==])\n")
    string(APPEND TULA_PERFLIBS_OPENMP_CACHE
        "set(OpenMP_CXX_INCLUDE_DIR [==[${OpenMP_CXX_INCLUDE_DIR}]==])\n")
    string(APPEND TULA_PERFLIBS_OPENMP_CACHE
        "set(OpenMP_CXX_LIB_NAMES [==[${OpenMP_CXX_LIB_NAMES}]==])\n")
    foreach(_openmp_library_name IN LISTS OpenMP_CXX_LIB_NAMES)
        set(_openmp_library_variable
            "OpenMP_${_openmp_library_name}_LIBRARY")
        string(APPEND TULA_PERFLIBS_OPENMP_CACHE
            "set(${_openmp_library_variable} [==[${${_openmp_library_variable}}]==])\n")
    endforeach()
    unset(_openmp_library_name)
    unset(_openmp_library_variable)
endif()
tula_cmake_generate_config_header(
    TARGET tula_perflibs
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/include/tula_perflibs/config.h.in"
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_perflibs/config.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
)

install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/generated/tula_perflibs/config.h"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/tula_perflibs"
)
tula_cmake_install_package(
    PACKAGE TulaPerflibs
    EXPORT TulaPerflibsTargets
    NAMESPACE tula_deps::
    TARGETS tula_perflibs
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/TulaPerflibsConfig.cmake.in"
)
