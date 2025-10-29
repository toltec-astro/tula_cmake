# NetCDFCXX4.cmake - NetCDF C++ API support

include(_deps_callbacks)

# Skip if target already exists
if(TARGET tula_NetCDFCXX4)
    message(STATUS "(NetCDFCXX4) Target tula_NetCDFCXX4 already exists, skipping")
    return()
endif()

# NetCDFCXX4 depends on NetCDF C library
if(NOT TARGET tula::NetCDF)
    include(NetCDF)
endif()

#[=======================================================================[
@brief Try to find netCDF-CXX4 via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_NetCDFCXX4_TRY_CONAN)
    tula_try_conan_header_only(NetCDFCXX4 netCDF::netcdf-cxx4)
    set(TULA_NetCDFCXX4_CONAN_SUCCESS ${TULA_NetCDFCXX4_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch netCDF-CXX4 via CPM
Note: Using main branch - includes fixes since v4.3.1 (Sep 2019)
]=======================================================================]
function(TULA_NetCDFCXX4_TRY_CPM)
    _tula_check_target_exists(NetCDFCXX4 netCDF::netcdf-cxx4 CPM)
    if(_TULA_TARGET_EXISTS)
        return()
    endif()
    
    include(_ensure_cpm)
    
    CPMAddPackage(
        NAME netcdf-cxx4
        GITHUB_REPOSITORY Unidata/netcdf-cxx4
        GIT_TAG main
        OPTIONS
            "ENABLE_DOXYGEN OFF"
            "BUILD_SHARED_LIBS OFF"
            "NCXX_ENABLE_TESTS OFF"
            "ENABLE_COVERAGE_TESTS OFF"
            "ENABLE_LARGE_FILE_TESTS OFF"
    )
    
    if(netcdf-cxx4_ADDED)
        # Suppress compiler warnings for netcdf-cxx4 target
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
        
        # Check if upstream creates the target correctly
        if(NOT TARGET netCDF::netcdf-cxx4 AND TARGET netcdf-cxx4)
            add_library(netCDF::netcdf-cxx4 ALIAS netcdf-cxx4)
        endif()
        
        message(STATUS "    Fetched netcdf-cxx4 via CPM")
        set(TULA_NetCDFCXX4_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        message(STATUS "    CPM fetch failed for netcdf-cxx4")
        set(TULA_NetCDFCXX4_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Try to find netCDF-CXX4 via system find_package
]=======================================================================]
function(TULA_NetCDFCXX4_TRY_SYSTEM)
    tula_try_system(NetCDFCXX4 netCDF::netcdf-cxx4 netCDF-CXX4)
    set(TULA_NetCDFCXX4_SYSTEM_SUCCESS ${TULA_NetCDFCXX4_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::NetCDFCXX4 wrapper target
]=======================================================================]
function(TULA_NetCDFCXX4_CREATE_WRAPPER)
    if(TARGET tula_NetCDFCXX4)
        return()  # Already created
    endif()
    
    if(NOT TARGET netCDF::netcdf-cxx4)
        message(FATAL_ERROR "Cannot create wrapper: netCDF::netcdf-cxx4 target does not exist")
    endif()
    
    include(make_tula_target)
    make_tula_target(NetCDFCXX4 netCDF::netcdf-cxx4)
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        verbose_message("NetCDFCXX4 configured: tula::NetCDFCXX4")
    endif()
endfunction()

# Register netCDF-CXX4 for tri-modal resolution
tula_deps_register(NetCDFCXX4)
