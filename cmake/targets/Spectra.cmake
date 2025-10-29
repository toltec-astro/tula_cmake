# Spectra.cmake - C++ library for large scale eigenvalue problems (header-only)

include(_deps_callbacks)

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
@brief Try to find Spectra via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_Spectra_TRY_CONAN)
    tula_try_conan_header_only(Spectra Spectra::Spectra)
    set(TULA_Spectra_CONAN_SUCCESS ${TULA_Spectra_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Spectra via CPM
Note: Spectra's CMakeLists.txt doesn't create targets, so we create one manually
]=======================================================================]
function(TULA_Spectra_TRY_CPM)
    _tula_check_target_exists(Spectra Spectra::Spectra CPM)
    if(_TULA_TARGET_EXISTS)
        return()
    endif()
    
    include(_ensure_cpm)
    
    CPMAddPackage(
        NAME Spectra
        GITHUB_REPOSITORY yixuan/spectra
        GIT_TAG v1.0.1
    )
    
    if(Spectra_ADDED)
        # Spectra doesn't create targets, so we create one manually
        add_library(Spectra::Spectra INTERFACE IMPORTED GLOBAL)
        target_include_directories(Spectra::Spectra INTERFACE "${Spectra_SOURCE_DIR}/include")
        message(STATUS "    Fetched Spectra via CPM and created Spectra::Spectra target")
        set(TULA_Spectra_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        message(STATUS "    CPM fetch failed for Spectra")
        set(TULA_Spectra_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Try to find Spectra via system find_package
]=======================================================================]
function(TULA_Spectra_TRY_SYSTEM)
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
    
    # Always link Eigen3 as Spectra depends on it
    include(make_tula_target)
    make_tula_target(Spectra Spectra::Spectra tula::Eigen3)
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        verbose_message("Spectra configured: tula::Spectra")
    endif()
endfunction()

# Register Spectra for tri-modal resolution
tula_deps_register(Spectra)
