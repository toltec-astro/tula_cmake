# NetCDF.cmake - Network Common Data Form library
#
# Defines: tula_NetCDF_add_conan(), tula_NetCDF_add_system()
# Called by: tula_deps_add(deps NetCDF) from tula_deps.cmake
# Note: CONAN or SYSTEM only - no CPM support

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Load NetCDF from Conan
]=======================================================================]
function(tula_NetCDF_add_conan)
    tula_try_conan_header_only(NetCDF netCDF::netcdf netCDF)
    if(NOT TULA_NetCDF_CONAN_SUCCESS)
        return()
    endif()
    _tula_NetCDF_create_wrapper()
endfunction()

#[=======================================================================[
@brief Find NetCDF via system find_package
]=======================================================================]
function(tula_NetCDF_add_system)
    tula_try_system(NetCDF netCDF::netcdf netCDF)
    if(NOT TULA_NetCDF_SYSTEM_SUCCESS)
        return()
    endif()
    _tula_NetCDF_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::NetCDF wrapper target
]=======================================================================]
function(_tula_NetCDF_create_wrapper)
    if(TARGET tula_NetCDF)
        return()
    endif()
    
    if(NOT TARGET netCDF::netcdf)
        message(FATAL_ERROR "Cannot create wrapper: netCDF::netcdf target does not exist")
    endif()
    
    make_tula_target(NetCDF netCDF::netcdf)
    
    verbose_message("Created tula::NetCDF wrapper")
endfunction()
