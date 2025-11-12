# Spectra.cmake - C++ library for large scale eigenvalue problems (header-only)
# Adapted for v3 Conan-centric architecture with stateless functions

include_guard(GLOBAL)

# Include utilities
include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Main setup function for Spectra (stateless, mode as parameter)

This is the entry point called by tula_deps_add().
Mode is passed as parameter (not global variable).

Note: Spectra depends on Eigen3, which should be loaded first via tula_deps_add().

@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_Spectra MODE)
    verbose_message("Setting up tula::Spectra (mode=${MODE})")
    
    # Idempotency check
    if(TARGET tula::Spectra)
        verbose_message("tula::Spectra already exists, skipping")
        return()
    endif()
    
    # Check Eigen3 dependency
    if(NOT TARGET tula::Eigen3)
        message(FATAL_ERROR 
            "Spectra requires Eigen3. Please add Eigen3 before Spectra:\n"
            "  tula_deps_add(deps Eigen3)\n"
            "  tula_deps_add(deps Spectra)")
    endif()
    
    # Mode-driven resolution (reuses existing helper functions)
    if(MODE MATCHES "CONAN|AUTO")
        TULA_Spectra_TRY_CONAN()
    elseif(MODE STREQUAL "CPM")
        TULA_Spectra_TRY_CPM()
    elseif(MODE STREQUAL "SYSTEM")
        TULA_Spectra_TRY_SYSTEM()
    else()
        message(FATAL_ERROR "Unknown Spectra mode: ${MODE}")
    endif()
    
    # Create wrapper target (includes Eigen3 dependency)
    TULA_Spectra_CREATE_WRAPPER()
    
    verbose_message("tula::Spectra ready")
endfunction()

#[=======================================================================[
@brief Try to find Spectra via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_Spectra_TRY_CONAN)
    # Use existing helper from _deps_callbacks.cmake
    tula_try_conan_header_only(Spectra Spectra::Spectra)
    set(TULA_Spectra_CONAN_SUCCESS ${TULA_Spectra_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Spectra via CPM
Note: Spectra's CMakeLists.txt doesn't create targets, so we create one manually
]=======================================================================]
function(TULA_Spectra_TRY_CPM)
    # Check if target already exists
    _tula_check_target_exists(Spectra Spectra::Spectra CPM)
    if(_TULA_TARGET_EXISTS)
        set(TULA_Spectra_CPM_SUCCESS TRUE PARENT_SCOPE)
        return()
    endif()
    
    # Use variables set by toolchain (from Spectra.py get_cmake_vars)
    if(NOT DEFINED SPECTRA_CPM_GITHUB_REPO)
        message(FATAL_ERROR "SPECTRA_CPM_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    CPMAddPackage(
        NAME Spectra
        GITHUB_REPOSITORY "${SPECTRA_CPM_GITHUB_REPO}"
        GIT_TAG "${SPECTRA_CPM_GIT_TAG}"
        DOWNLOAD_ONLY YES  # Avoid install() export issues
    )
    
    if(Spectra_ADDED)
        # Spectra doesn't create targets, so we create one manually
        add_library(Spectra::Spectra INTERFACE IMPORTED GLOBAL)
        target_include_directories(Spectra::Spectra INTERFACE "${Spectra_SOURCE_DIR}/include")
        verbose_message("Fetched Spectra via CPM and created Spectra::Spectra target")
        set(TULA_Spectra_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        verbose_message("CPM fetch failed for Spectra")
        set(TULA_Spectra_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Try to find Spectra via system find_package
]=======================================================================]
function(TULA_Spectra_TRY_SYSTEM)
    # Use existing helper from _deps_callbacks.cmake
    tula_try_system(Spectra Spectra::Spectra)
    set(TULA_Spectra_SYSTEM_SUCCESS ${TULA_Spectra_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Spectra wrapper target
Spectra depends on Eigen3, so we link both
]=======================================================================]
function(TULA_Spectra_CREATE_WRAPPER)
    if(TARGET tula_Spectra)
        return()  # Already created
    endif()
    
    if(NOT TARGET Spectra::Spectra)
        message(FATAL_ERROR "Cannot create wrapper: Spectra::Spectra target does not exist")
    endif()
    
    # Link both Spectra and Eigen3 (dependency)
    make_tula_target(Spectra Spectra::Spectra tula::Eigen3)
    
    verbose_message("Created tula::Spectra wrapper (with Eigen3 dependency)")
endfunction()

