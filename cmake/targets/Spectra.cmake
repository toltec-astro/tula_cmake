# Spectra.cmake - C++ library for large scale eigenvalue problems
# Single-include workflow with callback-based target creation
#
# Creates target: tula::Spectra

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_Spectra)
    message(STATUS "(Spectra) Target tula_Spectra already exists, skipping")
    return()
endif()

# Spectra depends on Eigen3
if(NOT TARGET tula::Eigen3)
    include(Eigen3)
endif()

#[=======================================================================[
@brief Create Spectra::Spectra target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_spectra_create_conan_target)
    if(TARGET Spectra::Spectra)
        return()  # Already created
    endif()
    
    set(SPECTRA_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "spectra" OR _path MATCHES "Spectra")
            set(SPECTRA_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT SPECTRA_INCLUDE_DIR)
        message(STATUS "  ✗ Spectra not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Spectra is header-only
    add_library(Spectra::Spectra INTERFACE IMPORTED GLOBAL)
    target_include_directories(Spectra::Spectra INTERFACE "${SPECTRA_INCLUDE_DIR}")
    message(STATUS "  ✓ Created Spectra::Spectra target from Conan: ${SPECTRA_INCLUDE_DIR}")
endfunction()

# Spectra - Header-only C++ library for large scale eigenvalue problems
# Built on top of Eigen, provides algorithms for sparse/dense matrices
tula_deps_register(Spectra
    CONAN_NAME Spectra
    CONAN_TARGET_CALLBACK _tula_spectra_create_conan_target
    CONAN_TARGET_NAME Spectra::Spectra
    CPM_GITHUB_REPOSITORY yixuan/spectra
    CPM_GIT_TAG v1.0.1
    CPM_OPTIONS
        "BUILD_TESTS OFF"
        "BUILD_EXAMPLES OFF"
    SYSTEM_NAME Spectra
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::Spectra after dependency is resolved
function(_tula_spectra_create_wrapper)
    if(TARGET tula_Spectra)
        return()  # Already created
    endif()
    
    # Check for available targets
    set(_spectra_libs "")

    if(TARGET Spectra::Spectra)
        list(APPEND _spectra_libs Spectra::Spectra)
        verbose_message("Spectra configured with Spectra::Spectra target")
    elseif(TARGET spectra)
        list(APPEND _spectra_libs spectra)
        verbose_message("Spectra configured with spectra target")
    else()
        # Spectra is header-only, might not create targets in all modes
        # Create an interface target manually if needed
        verbose_message("Spectra targets not found, attempting manual configuration")
        
        if(DEFINED Spectra_INCLUDE_DIR)
            add_library(spectra_interface INTERFACE)
            target_include_directories(spectra_interface INTERFACE ${Spectra_INCLUDE_DIR})
            list(APPEND _spectra_libs spectra_interface)
            verbose_message("Spectra configured with manual interface target")
        else()
            message(FATAL_ERROR "Spectra not found after dependency resolution")
        endif()
    endif()

    # Always link Eigen3 as Spectra depends on it
    list(APPEND _spectra_libs tula::Eigen3)

    # Create tula wrapper target
    include(make_tula_target)
    make_tula_target(Spectra ${_spectra_libs})

    verbose_message("Spectra configured: tula::Spectra")
endfunction()

# If Spectra already exists, create wrapper now
if(TARGET Spectra::Spectra OR TARGET spectra)
    _tula_spectra_create_wrapper()
endif()
