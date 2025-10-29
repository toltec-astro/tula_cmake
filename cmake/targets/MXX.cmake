# MXX.cmake - Modern MPI C++ wrapper library
# Single-include workflow with callback-based target creation
#
# Creates target: tula::MXX
# Note: MXX primarily uses CPM mode as no conan package exists

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_MXX)
    message(STATUS "(MXX) Target tula_MXX already exists, skipping")
    return()
endif()

# First, ensure MPI is available
find_package(MPI REQUIRED COMPONENTS CXX)
if(NOT MPI_FOUND)
    message(FATAL_ERROR "MPI not found. MXX requires MPI for parallel operations.")
endif()

set(_mxx_libs MPI::MPI_CXX)

#[=======================================================================[
@brief Create mxx target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_mxx_create_conan_target)
    if(TARGET mxx)
        return()  # Already created
    endif()
    
    # MXX is header-only, search for include directory
    set(MXX_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "mxx")
            set(MXX_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT MXX_INCLUDE_DIR)
        message(STATUS "  ✗ mxx not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target
    add_library(mxx INTERFACE IMPORTED GLOBAL)
    target_include_directories(mxx INTERFACE "${MXX_INCLUDE_DIR}")
    message(STATUS "  ✓ Created mxx target from Conan: ${MXX_INCLUDE_DIR}")
endfunction()

# MXX - Modern MPI C++ wrapper (header-only library)
# Note: No conan package exists; CPM is the primary installation method
tula_deps_register(MXX
    # CONAN_NAME mxx  # No conan package available
    CONAN_TARGET_CALLBACK _tula_mxx_create_conan_target
    CONAN_TARGET_NAME mxx
    CPM_GITHUB_REPOSITORY patflick/mxx
    CPM_GIT_TAG master
    CPM_OPTIONS
        "MXX_BUILD_TESTS OFF"
        "MXX_BUILD_DOCS OFF"
    # SYSTEM_NAME mxx  # Typically not installed system-wide
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::MXX after dependency is resolved
function(_tula_mxx_create_wrapper)
    if(TARGET tula_MXX)
        return()  # Already created
    endif()
    
    # Check for available targets
    if(TARGET mxx)
        list(APPEND _mxx_libs mxx)
        verbose_message("MXX configured with mxx target")
    else()
        message(FATAL_ERROR "MXX not found after dependency resolution")
    endif()

    # Create tula wrapper target
    include(make_tula_target)
    make_tula_target(MXX ${_mxx_libs})

    verbose_message("MXX configured: tula::MXX")
endfunction()

# If mxx already exists, create wrapper now
if(TARGET mxx)
    _tula_mxx_create_wrapper()
endif()

