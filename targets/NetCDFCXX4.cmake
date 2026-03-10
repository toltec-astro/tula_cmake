# NetCDFCXX4.cmake - NetCDF C++ bindings
#
# Defines: tula_NetCDFCXX4_add_cpm(), tula_NetCDFCXX4_add_system()
# Called by: tula_deps_add(deps NetCDFCXX4) from tula_deps.cmake
# Note: CPM or SYSTEM only - requires NetCDF dependency

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Fetch NetCDFCXX4 via CPM
]=======================================================================]
function(tula_NetCDFCXX4_add_cpm)
    if(NOT DEFINED TULA_NETCDFCXX4_CPM_GITHUB_REPO)
        return()
    endif()
    
    tula_try_cpm(NetCDFCXX4 netCDF::netcdf-cxx4
        NAME netcdfcxx4
        GITHUB_REPOSITORY "${TULA_NETCDFCXX4_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_NETCDFCXX4_CPM_GIT_TAG}"
        OPTIONS ${TULA_NETCDFCXX4_CPM_OPTIONS}
    )
    
    # Suppress warnings on the netcdf-cxx4 target
    if(TARGET netcdf-cxx4)
        target_compile_options(netcdf-cxx4 PRIVATE
            -Wno-sign-conversion
            -Wno-shorten-64-to-32
            -Wno-mismatched-new-delete
            -Wno-tautological-overlap-compare
            -Wno-unused-private-field
        )
    endif()
    
    if(NOT TULA_NetCDFCXX4_CPM_SUCCESS)
        return()
    endif()
    _tula_NetCDFCXX4_create_wrapper()
endfunction()

#[=======================================================================[
@brief Find NetCDFCXX4 via system find_package
]=======================================================================]
function(tula_NetCDFCXX4_add_system)
    # During toolchain phase the system cmake paths are not yet populated.
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        foreach(_arch_dir
                "/usr/lib/aarch64-linux-gnu"
                "/usr/lib/x86_64-linux-gnu"
                "/usr/local"
                "/usr")
            list(APPEND CMAKE_PREFIX_PATH "${_arch_dir}")
            list(APPEND CMAKE_PREFIX_PATH "${_arch_dir}/cmake/netCDF-CXX4")
            list(APPEND CMAKE_PREFIX_PATH "${_arch_dir}/cmake/netcdf-cxx4")
        endforeach()
    endif()
    # Try CONFIG first (may not exist for system packages), then MODULE (FindNetCDFCXX4.cmake)
    find_package(netCDF-CXX4 CONFIG QUIET)
    if(NOT TARGET netCDF::netcdf-cxx4)
        find_package(NetCDFCXX4 MODULE QUIET)
    endif()
    if(TARGET netCDF::netcdf-cxx4)
        set(TULA_NetCDFCXX4_SYSTEM_SUCCESS TRUE PARENT_SCOPE)
        _tula_NetCDFCXX4_create_wrapper()
    else()
        verbose_message("NetCDFCXX4 system not found")
    endif()
endfunction()

#[=======================================================================[
@brief Create tula::NetCDFCXX4 wrapper target
]=======================================================================]
function(_tula_NetCDFCXX4_create_wrapper)
    if(TARGET tula_NetCDFCXX4)
        return()
    endif()
    
    if(NOT TARGET netCDF::netcdf-cxx4)
        message(FATAL_ERROR "Cannot create wrapper: netCDF::netcdf-cxx4 target does not exist")
    endif()
    
    if(NOT TARGET tula::NetCDF)
        message(FATAL_ERROR 
            "NetCDFCXX4 requires NetCDF. Please add NetCDF before NetCDFCXX4:\n"
            "  tula_deps_add(deps NetCDF)\n"
            "  tula_deps_add(deps NetCDFCXX4)")
    endif()
    
    make_tula_target(NetCDFCXX4 netCDF::netcdf-cxx4)
    
    verbose_message("Created tula::NetCDFCXX4 wrapper")
endfunction()
