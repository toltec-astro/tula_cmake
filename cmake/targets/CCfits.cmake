# CCfits.cmake - FITS file I/O library for astronomy

include(_deps_callbacks)

# Skip if target already exists
if(TARGET tula_CCfits)
    message(STATUS "(CCfits) Target tula_CCfits already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Try to find CCfits via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_CCfits_TRY_CONAN)
    tula_try_conan_header_only(CCfits CCfits::CCfits)
    set(TULA_CCfits_CONAN_SUCCESS ${TULA_CCfits_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch CCfits via CPM
Note: No git repository available - CPM not supported
]=======================================================================]
function(TULA_CCfits_TRY_CPM)
    message(STATUS "  ✗ CCfits not supported via CPM (no git repository)")
    set(TULA_CCfits_CPM_SUCCESS FALSE PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find CCfits via system find_package
]=======================================================================]
function(TULA_CCfits_TRY_SYSTEM)
    tula_try_system(CCfits CCfits::CCfits)
    set(TULA_CCfits_SYSTEM_SUCCESS ${TULA_CCfits_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::CCfits wrapper target
]=======================================================================]
function(TULA_CCfits_CREATE_WRAPPER)
    if(TARGET tula_CCfits)
        return()  # Already created
    endif()
    
    if(NOT TARGET CCfits::CCfits)
        message(FATAL_ERROR "Cannot create wrapper: CCfits::CCfits target does not exist")
    endif()
    
    include(make_tula_target)
    make_tula_target(CCfits CCfits::CCfits)
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        verbose_message("CCfits configured: tula::CCfits")
    endif()
endfunction()

# Register CCfits for tri-modal resolution
tula_deps_register(CCfits)

# If CCfits already exists, create wrapper now
if(TARGET CCfits::CCfits OR TARGET CCfits)
    _tula_ccfits_create_wrapper()
endif()

