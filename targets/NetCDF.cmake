# NetCDF.cmake - Network Common Data Form library
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Setup NetCDF package (CONAN or SYSTEM only, no CPM support)
@param MODE Resolution mode (AUTO, CONAN, SYSTEM)
]=======================================================================]
function(tula_setup_NetCDF MODE)
    verbose_message("Setting up tula::NetCDF (mode=${MODE})")
    
    if(TARGET tula::NetCDF)
        verbose_message("tula::NetCDF already exists")
        return()
    endif()
    
    if(MODE STREQUAL "AUTO")
        TULA_NetCDF_TRY_CONAN()
        if(NOT TULA_NetCDF_CONAN_SUCCESS)
            TULA_NetCDF_TRY_SYSTEM()
        endif()
    elseif(MODE STREQUAL "CONAN")
        TULA_NetCDF_TRY_CONAN()
    elseif(MODE STREQUAL "SYSTEM")
        TULA_NetCDF_TRY_SYSTEM()
    elseif(MODE STREQUAL "CPM")
        message(FATAL_ERROR "NetCDF does not support CPM mode (requires system libraries)")
    else()
        message(FATAL_ERROR "Invalid MODE for NetCDF: ${MODE}")
    endif()
    
    # Create wrapper
    TULA_NetCDF_CREATE_WRAPPER()
    verbose_message("tula::NetCDF ready")
endfunction()

#[=======================================================================[
@brief Try to find NetCDF via Conan
]=======================================================================]
function(TULA_NetCDF_TRY_CONAN)
    tula_try_conan_header_only(NetCDF netCDF::netcdf netCDF)
    set(TULA_NetCDF_CONAN_SUCCESS ${TULA_NetCDF_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find NetCDF via system find_package
]=======================================================================]
function(TULA_NetCDF_TRY_SYSTEM)
    tula_try_system(NetCDF netCDF::netcdf netCDF)
    set(TULA_NetCDF_SYSTEM_SUCCESS ${TULA_NetCDF_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::NetCDF wrapper target
]=======================================================================]
function(TULA_NetCDF_CREATE_WRAPPER)
    tula_create_wrapper(NetCDF netCDF::netcdf)
    verbose_message("Created tula::NetCDF wrapper")
endfunction()
