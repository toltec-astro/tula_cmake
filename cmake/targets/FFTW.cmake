# FFTW.cmake - Fast Fourier Transform library
# Single-include workflow with callback-based target creation
#
# Creates target: tula::FFTW

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_FFTW)
    message(STATUS "(FFTW) Target tula_FFTW already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Create FFTW3::fftw3 target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_fftw_create_conan_target)
    if(TARGET FFTW3::fftw3)
        return()  # Already created
    endif()
    
    set(FFTW_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "fftw")
            set(FFTW_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT FFTW_INCLUDE_DIR)
        message(STATUS "  ✗ FFTW3 not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    add_library(FFTW3::fftw3 INTERFACE IMPORTED GLOBAL)
    target_include_directories(FFTW3::fftw3 INTERFACE "${FFTW_INCLUDE_DIR}")
    message(STATUS "  ✓ Created FFTW3::fftw3 target from Conan: ${FFTW_INCLUDE_DIR}")
endfunction()

# FFTW - Fast Fourier Transform library
# Note: FFTW has multiple precision versions (float, double, long double, quad)
# This module finds the double-precision library (fftw3)
tula_deps_register(FFTW3
    CONAN_NAME FFTW3
    CONAN_TARGET_CALLBACK _tula_fftw_create_conan_target
    CONAN_TARGET_NAME FFTW3::fftw3
    CPM_GITHUB_REPOSITORY FFTW/fftw3
    CPM_GIT_TAG fftw-3.3.10
    CPM_OPTIONS
        "BUILD_TESTS OFF"
        "ENABLE_FLOAT OFF"
        "ENABLE_LONG_DOUBLE OFF"
        "ENABLE_QUAD_PRECISION OFF"
        "ENABLE_SSE2 ON"
        "ENABLE_AVX ON"
        "ENABLE_AVX2 ON"
        "ENABLE_OPENMP ON"
        "ENABLE_THREADS ON"
    SYSTEM_NAME FFTW3
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::FFTW after dependency is resolved
function(_tula_fftw_create_wrapper)
    if(TARGET tula_FFTW)
        return()  # Already created
    endif()
    
    # Check for available targets
    set(_fftw_libs "")

    if(TARGET FFTW3::fftw3)
        list(APPEND _fftw_libs FFTW3::fftw3)
        verbose_message("FFTW3 double-precision configured")
    elseif(TARGET fftw3)
        list(APPEND _fftw_libs fftw3)
        verbose_message("FFTW3 double-precision configured (fftw3 target)")
    else()
        message(FATAL_ERROR "FFTW3 not found after dependency resolution")
    endif()

    # Optional: Find threaded version if available
    if(TARGET FFTW3::fftw3_threads)
        list(APPEND _fftw_libs FFTW3::fftw3_threads)
        verbose_message("FFTW3 threads support found")
    elseif(TARGET fftw3_threads)
        list(APPEND _fftw_libs fftw3_threads)
        verbose_message("FFTW3 threads support found")
    endif()

    # Optional: Find OpenMP version if available
    if(TARGET FFTW3::fftw3_omp)
        list(APPEND _fftw_libs FFTW3::fftw3_omp)
        verbose_message("FFTW3 OpenMP support found")
    elseif(TARGET fftw3_omp)
        list(APPEND _fftw_libs fftw3_omp)
        verbose_message("FFTW3 OpenMP support found")
    endif()

    # Create tula wrapper target
    include(make_tula_target)
    make_tula_target(FFTW ${_fftw_libs})

    verbose_message("FFTW configured: tula::FFTW")
endfunction()

# If FFTW3 already exists, create wrapper now
if(TARGET FFTW3::fftw3 OR TARGET fftw3)
    _tula_fftw_create_wrapper()
endif()
