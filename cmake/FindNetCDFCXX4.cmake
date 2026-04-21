# FindNetCDFCXX4.cmake - Find the NetCDF C++ library
#
# This module finds the system-installed netcdf-cxx4 library.
# It first tries CMake config mode, then falls back to ncxx4-config.
#
# Defines:
#   NetCDFCXX4_FOUND          - True if found
#   netCDF::netcdf-cxx4       - Imported target
#
# Note: find_program/find_library results are cached by CMake. When this module
# is first called during the toolchain phase (before project()), those caches
# may be populated as NOTFOUND. We explicitly unset them before searching so
# that the post-project() retry gets a fresh search.

cmake_minimum_required(VERSION 3.15)

# Already defined (e.g., from previous find)
if(TARGET netCDF::netcdf-cxx4)
    set(NetCDFCXX4_FOUND TRUE)
    return()
endif()

# Try CMake config first
find_package(netCDF-CXX4 CONFIG QUIET)
if(TARGET netCDF::netcdf-cxx4)
    set(NetCDFCXX4_FOUND TRUE)
    return()
endif()

# Fall back to ncxx4-config.
# Unset cached results so a toolchain-phase NOTFOUND doesn't block the retry.
unset(NCXX4_CONFIG CACHE)
unset(NETCDF_CXX4_LIBRARY CACHE)

find_program(NCXX4_CONFIG ncxx4-config
    PATHS /usr/bin /usr/local/bin
    NO_DEFAULT_PATH)
if(NOT NCXX4_CONFIG)
    find_program(NCXX4_CONFIG ncxx4-config)
endif()

if(NCXX4_CONFIG)
    execute_process(COMMAND ${NCXX4_CONFIG} --cflags
        OUTPUT_VARIABLE _ncxx4_cflags OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND ${NCXX4_CONFIG} --libs
        OUTPUT_VARIABLE _ncxx4_libs OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND ${NCXX4_CONFIG} --includedir
        OUTPUT_VARIABLE _ncxx4_includedir OUTPUT_STRIP_TRAILING_WHITESPACE)

    # Find the library (unset cache ensures fresh search after toolchain phase)
    find_library(NETCDF_CXX4_LIBRARY
        NAMES netcdf_c++4 netcdf-cxx4
        PATHS /usr/lib /usr/lib/aarch64-linux-gnu /usr/local/lib
        NO_DEFAULT_PATH)
    if(NOT NETCDF_CXX4_LIBRARY)
        find_library(NETCDF_CXX4_LIBRARY NAMES netcdf_c++4 netcdf-cxx4)
    endif()

    if(NETCDF_CXX4_LIBRARY AND _ncxx4_includedir)
        add_library(netCDF::netcdf-cxx4 UNKNOWN IMPORTED)
        set_target_properties(netCDF::netcdf-cxx4 PROPERTIES
            IMPORTED_LOCATION "${NETCDF_CXX4_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${_ncxx4_includedir}"
        )
        # Link against the C netcdf library if available
        if(TARGET netCDF::netcdf)
            set_target_properties(netCDF::netcdf-cxx4 PROPERTIES
                INTERFACE_LINK_LIBRARIES "netCDF::netcdf"
            )
        endif()
        set(NetCDFCXX4_FOUND TRUE)
        message(STATUS "Found netcdf-cxx4 via ncxx4-config: ${NETCDF_CXX4_LIBRARY}")
    endif()
endif()

if(NOT NetCDFCXX4_FOUND)
    if(NetCDFCXX4_FIND_REQUIRED)
        message(FATAL_ERROR "Could not find netcdf-cxx4. Install libnetcdf-c++4-dev.")
    elseif(NOT NetCDFCXX4_FIND_QUIETLY)
        message(STATUS "netcdf-cxx4 not found")
    endif()
endif()
