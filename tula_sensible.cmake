# tula_sensible.cmake - Sensible defaults for tula projects
#
# This file runs on include (no function call needed).
# include_guard(GLOBAL) ensures it only runs once.
#
# All values come from Conan profile or environment - nothing hardcoded.

include_guard(GLOBAL)

# Minimum CMake version
set(TULA_CMAKE_MINIMUM_VERSION "4.1")
if(CMAKE_VERSION VERSION_LESS ${TULA_CMAKE_MINIMUM_VERSION})
    message(FATAL_ERROR 
        "tula requires CMake ${TULA_CMAKE_MINIMUM_VERSION}+, got ${CMAKE_VERSION}")
endif()

# Position independent code
if(NOT DEFINED CMAKE_POSITION_INDEPENDENT_CODE)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# Export compile commands for IDE support
if(NOT DEFINED CMAKE_EXPORT_COMPILE_COMMANDS)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

# RPATH settings
if(NOT DEFINED CMAKE_SKIP_BUILD_RPATH)
    set(CMAKE_SKIP_BUILD_RPATH FALSE)
endif()
if(NOT DEFINED CMAKE_BUILD_WITH_INSTALL_RPATH)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
endif()
if(NOT DEFINED CMAKE_BUILD_RPATH_USE_ORIGIN)
    set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
endif()
if(NOT DEFINED CMAKE_INSTALL_RPATH_USE_LINK_PATH)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
endif()

# Output directories
if(NOT DEFINED CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
endif()
if(NOT DEFINED CMAKE_LIBRARY_OUTPUT_DIRECTORY)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
endif()
if(NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endif()

# CPM cache directory
if(NOT DEFINED CPM_SOURCE_CACHE)
    if(DEFINED ENV{CPM_SOURCE_CACHE})
        set(CPM_SOURCE_CACHE "$ENV{CPM_SOURCE_CACHE}" CACHE PATH "CPM source cache")
    elseif(DEFINED ENV{TULA_CACHE_ROOT})
        set(CPM_SOURCE_CACHE "$ENV{TULA_CACHE_ROOT}/cpm" CACHE PATH "CPM source cache")
    else()
        set(CPM_SOURCE_CACHE "$ENV{HOME}/.tula_cache/cpm" CACHE PATH "CPM source cache")
    endif()
endif()
file(MAKE_DIRECTORY "${CPM_SOURCE_CACHE}")

# Platform: macOS RPATH
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CMAKE_MACOSX_RPATH TRUE)
endif()

# Compiler library paths for RPATH (Homebrew LLVM, custom GCC)
if(DEFINED CMAKE_CXX_COMPILER)
    get_filename_component(_tula_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
    get_filename_component(_tula_libdir "${_tula_bindir}/../lib" ABSOLUTE)
    
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        if(_tula_libdir MATCHES "/opt/homebrew" OR _tula_libdir MATCHES "/usr/local")
            message(STATUS "(tula) Homebrew LLVM detected, adding rpath: ${_tula_libdir}")
            set(CMAKE_EXE_LINKER_FLAGS 
                "${CMAKE_EXE_LINKER_FLAGS} -L${_tula_libdir}/c++ -L${_tula_libdir} -Wl,-rpath,${_tula_libdir}")
        endif()
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        get_filename_component(_tula_lib64dir "${_tula_bindir}/../lib64" ABSOLUTE)
        if(EXISTS ${_tula_libdir} OR EXISTS ${_tula_lib64dir})
            message(STATUS "(tula) GCC detected, adding library paths to RPATH")
            set(CMAKE_EXE_LINKER_FLAGS 
                "${CMAKE_EXE_LINKER_FLAGS} -L${_tula_libdir} -Wl,-rpath,${_tula_libdir} -Wl,-rpath,${_tula_lib64dir}")
        endif()
    endif()
    
    unset(_tula_bindir)
    unset(_tula_libdir)
    unset(_tula_lib64dir)
endif()

message(STATUS "(tula) Sensible defaults applied")
