# CCfits.cmake - FITS file I/O library for astronomy
# Single-include workflow with callback-based target creation
#
# Creates target: tula::CCfits

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_CCfits)
    message(STATUS "(CCfits) Target tula_CCfits already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Create CCfits::CCfits target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_ccfits_create_conan_target)
    if(TARGET CCfits::CCfits)
        return()  # Already created
    endif()
    
    # Conan provides include/lib paths via CMAKE_INCLUDE_PATH
    set(CCFITS_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "CCfits" OR _path MATCHES "ccfits")
            set(CCFITS_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT CCFITS_INCLUDE_DIR)
        message(STATUS "  ✗ CCfits not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target (simplified)
    add_library(CCfits::CCfits INTERFACE IMPORTED GLOBAL)
    target_include_directories(CCfits::CCfits INTERFACE "${CCFITS_INCLUDE_DIR}")
    message(STATUS "  ✓ Created CCfits::CCfits target from Conan: ${CCFITS_INCLUDE_DIR}")
endfunction()

# CCfits - FITS file I/O library (C++ wrapper for cfitsio)
# Note: No git repository available, so CPM mode is not supported
#       Use conan (recommended) or system-installed package
tula_deps_register(CCfits
    CONAN_NAME CCfits
    CONAN_TARGET_CALLBACK _tula_ccfits_create_conan_target
    CONAN_TARGET_NAME CCfits::CCfits
    # CPM mode unavailable - no git repository
    SYSTEM_NAME CCfits
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::CCfits after dependency is resolved
function(_tula_ccfits_create_wrapper)
    if(TARGET tula_CCfits)
        return()  # Already created
    endif()
    
    # Check for available targets
    set(_ccfits_libs "")

    if(TARGET CCfits::CCfits)
        list(APPEND _ccfits_libs CCfits::CCfits)
        verbose_message("CCfits configured with CCfits::CCfits target")
    elseif(TARGET CCfits)
        list(APPEND _ccfits_libs CCfits)
        verbose_message("CCfits configured with CCfits target")
    else()
        message(FATAL_ERROR "CCfits not found after dependency resolution")
    endif()

    # Create tula wrapper target
    include(make_tula_target)
    make_tula_target(CCfits ${_ccfits_libs})

    verbose_message("CCfits configured: tula::CCfits")
endfunction()

# If CCfits already exists, create wrapper now
if(TARGET CCfits::CCfits OR TARGET CCfits)
    _tula_ccfits_create_wrapper()
endif()

