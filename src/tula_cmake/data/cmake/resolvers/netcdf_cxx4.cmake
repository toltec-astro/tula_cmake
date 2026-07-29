include_guard(GLOBAL)

function(_tula_netcdf_cxx4_system)
    find_package(PkgConfig QUIET)
    if(PkgConfig_FOUND)
        pkg_check_modules(
            NETCDF_CXX4
            QUIET
            IMPORTED_TARGET
            netcdf-cxx4
        )
    endif()
    if(TARGET PkgConfig::NETCDF_CXX4)
        set(TULA_NETCDF_CXX4_SYSTEM_TARGET
            PkgConfig::NETCDF_CXX4 PARENT_SCOPE)
        return()
    endif()

    find_program(NCXX4_CONFIG_EXECUTABLE NAMES ncxx4-config REQUIRED)
    execute_process(
        COMMAND "${NCXX4_CONFIG_EXECUTABLE}" --includedir
        OUTPUT_VARIABLE _include_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )
    execute_process(
        COMMAND "${NCXX4_CONFIG_EXECUTABLE}" --libdir
        OUTPUT_VARIABLE _library_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )
    find_library(
        NETCDF_CXX4_LIBRARY
        NAMES netcdf-cxx4
        HINTS "${_library_dir}"
        REQUIRED
    )
    add_library(tula_netcdf_cxx4_system UNKNOWN IMPORTED)
    set_target_properties(
        tula_netcdf_cxx4_system
        PROPERTIES
            IMPORTED_LOCATION "${NETCDF_CXX4_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${_include_dir}"
    )
    set(TULA_NETCDF_CXX4_SYSTEM_TARGET
        tula_netcdf_cxx4_system PARENT_SCOPE)
endfunction()

function(_tula_netcdf_cxx4_finalize provider_target)
    if(TARGET tula::netcdf_cxx4)
        return()
    endif()
    if(NOT TARGET "${provider_target}")
        message(FATAL_ERROR
            "netcdf_cxx4: ${provider_target} provider target is unavailable")
    endif()
    if(NOT TARGET tula::netcdf_c)
        message(FATAL_ERROR
            "netcdf_cxx4: required target tula::netcdf_c is unavailable")
    endif()

    add_library(tula_netcdf_cxx4 INTERFACE)
    target_link_libraries(
        tula_netcdf_cxx4
        INTERFACE "${provider_target}" tula::netcdf_c
    )
    add_library(tula::netcdf_cxx4 ALIAS tula_netcdf_cxx4)
endfunction()

function(tula_resolve_netcdf_cxx4_conan)
    find_package(netCDFCxx CONFIG REQUIRED)
    _tula_netcdf_cxx4_finalize(netCDF::netcdf-cxx4)
endfunction()

function(tula_resolve_netcdf_cxx4_system)
    _tula_netcdf_cxx4_system()
    _tula_netcdf_cxx4_finalize("${TULA_NETCDF_CXX4_SYSTEM_TARGET}")
endfunction()
