# NetCDF.cmake - NetCDF C library support
# Single-include workflow with callback-based target creation

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_NetCDF)
    message(STATUS "(NetCDF) Target tula_NetCDF already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Create netCDF::netcdf target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_netcdf_create_conan_target)
    if(TARGET netCDF::netcdf)
        return()  # Already created
    endif()
    
    # Conan provides include/lib paths via CMAKE_INCLUDE_PATH
    set(NETCDF_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "netcdf")
            set(NETCDF_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT NETCDF_INCLUDE_DIR)
        message(STATUS "  ✗ NetCDF not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target (simplified - full version would link library)
    add_library(netCDF::netcdf INTERFACE IMPORTED GLOBAL)
    target_include_directories(netCDF::netcdf INTERFACE "${NETCDF_INCLUDE_DIR}")
    message(STATUS "  ✓ Created netCDF::netcdf target from Conan: ${NETCDF_INCLUDE_DIR}")
endfunction()

# Find NetCDF C library
# Note: NetCDF C library is complex and requires conan or system installation
# Fetching from source is not practical due to numerous dependencies (HDF5, libcurl, etc.)
tula_deps_register(netCDF
    CONAN_NAME netCDF
    CONAN_TARGET_CALLBACK _tula_netcdf_create_conan_target
    CONAN_TARGET_NAME netCDF::netcdf
    # No CPM mode - too many dependencies
    SYSTEM_NAME netCDF
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::NetCDF after dependency is resolved
function(_tula_netcdf_create_wrapper)
    if(TARGET tula_NetCDF)
        return()  # Already created
    endif()
    
    # Create tula interface library
    include(make_tula_target)
    make_tula_target(NetCDF netCDF::netcdf)
    
    verbose_message("NetCDF configured: tula::NetCDF")
endfunction()

# If netCDF already exists, create wrapper now
if(TARGET netCDF::netcdf OR TARGET netcdf)
    _tula_netcdf_create_wrapper()
endif()
