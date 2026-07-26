include_guard(GLOBAL)

function(_tula_netcdf_c_installed)
    find_package(netCDF CONFIG REQUIRED)
endfunction()

function(_tula_netcdf_c_finalize)
    if(TARGET tula::netcdf_c)
        return()
    endif()
    if(NOT TARGET netCDF::netcdf)
        message(FATAL_ERROR
            "netcdf_c: netCDF::netcdf provider target is unavailable")
    endif()

    add_library(tula_netcdf_c INTERFACE)
    target_link_libraries(tula_netcdf_c INTERFACE netCDF::netcdf)
    add_library(tula::netcdf_c ALIAS tula_netcdf_c)
endfunction()

function(tula_resolve_netcdf_c_conan)
    _tula_netcdf_c_installed()
    _tula_netcdf_c_finalize()
endfunction()

function(tula_resolve_netcdf_c_system)
    _tula_netcdf_c_installed()
    _tula_netcdf_c_finalize()
endfunction()
