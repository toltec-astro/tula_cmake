# NetCDF.cmake - NetCDF C library support

include(_deps_callbacks)

# Skip if target already exists
if(TARGET tula_NetCDF)
    message(STATUS "(NetCDF) Target tula_NetCDF already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Try to find netCDF via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_NetCDF_TRY_CONAN)
    tula_try_conan_header_only(NetCDF netCDF::netcdf)
    set(TULA_NetCDF_CONAN_SUCCESS ${TULA_NetCDF_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch netCDF via CPM
NetCDF has many dependencies (HDF5, libcurl, etc.) - not practical for CPM
]=======================================================================]
function(TULA_NetCDF_TRY_CPM)
    message(STATUS "  ✗ NetCDF not supported via CPM (too many dependencies)")
    set(TULA_NetCDF_CPM_SUCCESS FALSE PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find netCDF via system find_package
]=======================================================================]
function(TULA_NetCDF_TRY_SYSTEM)
    tula_try_system(NetCDF netCDF::netcdf)
    set(TULA_NetCDF_SYSTEM_SUCCESS ${TULA_NetCDF_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::NetCDF wrapper target
]=======================================================================]
function(TULA_NetCDF_CREATE_WRAPPER)
    if(TARGET tula_NetCDF)
        return()  # Already created
    endif()
    
    if(NOT TARGET netCDF::netcdf)
        message(FATAL_ERROR "Cannot create wrapper: netCDF::netcdf target does not exist")
    endif()
    
    include(make_tula_target)
    make_tula_target(NetCDF netCDF::netcdf)
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        verbose_message("NetCDF configured: tula::NetCDF")
    endif()
endfunction()

# Register netCDF for tri-modal resolution
tula_deps_register(NetCDF)
