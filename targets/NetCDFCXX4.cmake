# NetCDFCXX4.cmake - NetCDF C++ bindings
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Setup NetCDFCXX4 package (CPM or SYSTEM, requires NetCDF dependency)
@param MODE Resolution mode (AUTO, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_NetCDFCXX4 MODE)
    verbose_message("Setting up tula::NetCDFCXX4 (mode=${MODE})")
    
    if(TARGET tula::NetCDFCXX4)
        verbose_message("tula::NetCDFCXX4 already exists")
        return()
    endif()
    
    # Ensure NetCDF dependency is available
    if(NOT TARGET tula::NetCDF)
        verbose_message("NetCDFCXX4 requires NetCDF, loading it first...")
        # Load NetCDF with appropriate mode
        if(MODE STREQUAL "CPM")
            set(NETCDF_MODE "CONAN")  # NetCDF doesn't support CPM
        else()
            set(NETCDF_MODE "${MODE}")
        endif()
        tula_deps_add(_netcdf_dep NetCDF)
    endif()
    
    if(MODE STREQUAL "AUTO")
        TULA_NetCDFCXX4_TRY_CPM()
        if(NOT TULA_NetCDFCXX4_CPM_SUCCESS)
            TULA_NetCDFCXX4_TRY_SYSTEM()
        endif()
    elseif(MODE STREQUAL "CPM")
        TULA_NetCDFCXX4_TRY_CPM()
    elseif(MODE STREQUAL "SYSTEM")
        TULA_NetCDFCXX4_TRY_SYSTEM()
    elseif(MODE STREQUAL "CONAN")
        message(FATAL_ERROR "NetCDFCXX4 is not available in Conan")
    else()
        message(FATAL_ERROR "Invalid MODE for NetCDFCXX4: ${MODE}")
    endif()
    
    # Create wrapper
    TULA_NetCDFCXX4_CREATE_WRAPPER()
    verbose_message("tula::NetCDFCXX4 ready")
endfunction()

#[=======================================================================[
@brief Try to fetch NetCDFCXX4 via CPM
]=======================================================================]
function(TULA_NetCDFCXX4_TRY_CPM)
    if(NOT DEFINED NETCDFCXX4_CPM_GITHUB_REPO)
        message(FATAL_ERROR "NETCDFCXX4_CPM_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    tula_try_cpm(NetCDFCXX4 netCDF::netcdf-cxx4
        NAME netcdfcxx4
        GITHUB_REPOSITORY "${NETCDFCXX4_CPM_GITHUB_REPO}"
        GIT_TAG "${NETCDFCXX4_CPM_GIT_TAG}"
        OPTIONS ${NETCDFCXX4_CPM_OPTIONS}
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
    
    set(TULA_NetCDFCXX4_CPM_SUCCESS ${TULA_NetCDFCXX4_CPM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find NetCDFCXX4 via system find_package
]=======================================================================]
function(TULA_NetCDFCXX4_TRY_SYSTEM)
    tula_try_system(NetCDFCXX4 netCDF::netcdf-cxx4 netCDF-CXX4)
    set(TULA_NetCDFCXX4_SYSTEM_SUCCESS ${TULA_NetCDFCXX4_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::NetCDFCXX4 wrapper target
]=======================================================================]
function(TULA_NetCDFCXX4_CREATE_WRAPPER)
    tula_create_wrapper(NetCDFCXX4 netCDF::netcdf-cxx4)
    verbose_message("Created tula::NetCDFCXX4 wrapper")
endfunction()
