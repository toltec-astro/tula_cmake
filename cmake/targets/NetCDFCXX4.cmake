# NetCDFCXX4.cmake - NetCDF C++ API support
# Single-include workflow with callback-based target creation

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_NetCDFCXX4)
    message(STATUS "(NetCDFCXX4) Target tula_NetCDFCXX4 already exists, skipping")
    return()
endif()

# NetCDFCXX4 depends on NetCDF C library
if (NOT TARGET tula::NetCDF)
    include(NetCDF)
endif()

#[=======================================================================[
@brief Create netCDF::netcdf-cxx4 target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_netcdfcxx4_create_conan_target)
    if(TARGET netCDF::netcdf-cxx4)
        return()  # Already created
    endif()
    
    # Conan provides include/lib paths via CMAKE_INCLUDE_PATH
    set(NETCDFCXX4_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "netcdf.*cxx")
            set(NETCDFCXX4_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT NETCDFCXX4_INCLUDE_DIR)
        message(STATUS "  ✗ netcdf-cxx4 not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target (simplified)
    add_library(netCDF::netcdf-cxx4 INTERFACE IMPORTED GLOBAL)
    target_include_directories(netCDF::netcdf-cxx4 INTERFACE "${NETCDFCXX4_INCLUDE_DIR}")
    message(STATUS "  ✓ Created netCDF::netcdf-cxx4 target from Conan: ${NETCDFCXX4_INCLUDE_DIR}")
endfunction()

# Find or fetch netCDF-CXX4
# Note: Using main branch instead of v4.3.1 (Sep 2019) because main has 6+ years of fixes
# Latest release is v4.3.1 but main branch is actively maintained (last commit: Aug 2025)
tula_deps_register(netCDF-CXX4
    CONAN_NAME netCDF-CXX4
    CONAN_TARGET_CALLBACK _tula_netcdfcxx4_create_conan_target
    CONAN_TARGET_NAME netCDF::netcdf-cxx4
    CPM_GITHUB_REPOSITORY Unidata/netcdf-cxx4
    CPM_GIT_TAG main  # Using main branch - includes fixes since v4.3.1
    CPM_OPTIONS 
        "ENABLE_DOXYGEN OFF" 
        "BUILD_SHARED_LIBS OFF"
        "NCXX_ENABLE_TESTS OFF"
        "ENABLE_COVERAGE_TESTS OFF"
        "ENABLE_LARGE_FILE_TESTS OFF"
    SYSTEM_NAME netCDF-CXX4
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::NetCDFCXX4 after dependency is resolved
function(_tula_netcdfcxx4_create_wrapper)
    if(TARGET tula_NetCDFCXX4)
        return()  # Already created
    endif()
    
    # Suppress compiler warnings for netcdf-cxx4 target if built via CPM
    if(TARGET netcdf-cxx4)
        set_property(
            TARGET netcdf-cxx4
            APPEND PROPERTY COMPILE_OPTIONS
            -Wno-sign-conversion
            -Wno-shorten-64-to-32
            -Wno-mismatched-new-delete
            -Wno-tautological-overlap-compare
            -Wno-unused-private-field
        )
    endif()
    
    # Create tula interface library
    include(make_tula_target)
    make_tula_target(NetCDFCXX4 netCDF::netcdf-cxx4)
    
    verbose_message("NetCDFCXX4 configured: tula::NetCDFCXX4")
endfunction()

# If netCDF-CXX4 already exists, create wrapper now
if(TARGET netCDF::netcdf-cxx4 OR TARGET netcdf-cxx4)
    _tula_netcdfcxx4_create_wrapper()
endif()
