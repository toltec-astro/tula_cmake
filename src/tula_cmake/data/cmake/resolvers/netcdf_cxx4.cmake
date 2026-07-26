include_guard(GLOBAL)

include(TulaCPM)

function(_tula_netcdf_cxx4_cpm)
    tula_load_cpm()
    CPMAddPackage(
        NAME netcdf_cxx4
        URL "${TULA_FEATURE_netcdf_cxx4_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_netcdf_cxx4_SHA256}"
        DOWNLOAD_ONLY YES
    )
    if(NOT netcdf_cxx4_SOURCE_DIR)
        message(FATAL_ERROR
            "netcdf_cxx4: CPM did not provide a source directory")
    endif()

    file(
        GLOB _netcdf_cxx4_sources
        CONFIGURE_DEPENDS
        "${netcdf_cxx4_SOURCE_DIR}/cxx4/nc*.cpp"
    )
    if(NOT _netcdf_cxx4_sources)
        message(FATAL_ERROR "netcdf_cxx4: no C++ library sources found")
    endif()
    add_library(tula_netcdf_cxx4_cpm STATIC ${_netcdf_cxx4_sources})
    set_target_properties(
        tula_netcdf_cxx4_cpm
        PROPERTIES POSITION_INDEPENDENT_CODE ON
    )
    target_include_directories(
        tula_netcdf_cxx4_cpm
        PUBLIC "${netcdf_cxx4_SOURCE_DIR}/cxx4"
    )
    target_link_libraries(tula_netcdf_cxx4_cpm PUBLIC tula::netcdf_c)
endfunction()

function(_tula_netcdf_cxx4_system)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(
        NETCDF_CXX4
        REQUIRED
        IMPORTED_TARGET
        netcdf-cxx4
    )
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

function(tula_resolve_netcdf_cxx4_cpm)
    _tula_netcdf_cxx4_cpm()
    _tula_netcdf_cxx4_finalize(tula_netcdf_cxx4_cpm)
endfunction()

function(tula_resolve_netcdf_cxx4_system)
    _tula_netcdf_cxx4_system()
    _tula_netcdf_cxx4_finalize(PkgConfig::NETCDF_CXX4)
endfunction()
