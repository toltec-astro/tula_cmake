# Spectra.cmake - C++ library for large scale eigenvalue problems (header-only)
#
# Defines: tula_Spectra_add_conan(), tula_Spectra_add_cpm(), tula_Spectra_add_system()
# Called by: tula_deps_add(deps Spectra) from tula_deps.cmake
# Note: Spectra depends on Eigen3, which should be loaded first

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Load Spectra from Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(tula_Spectra_add_conan)
    tula_try_conan_header_only(Spectra Spectra::Spectra)
    if(NOT TULA_Spectra_CONAN_SUCCESS)
        return()
    endif()
    _tula_Spectra_create_wrapper()
endfunction()

#[=======================================================================[
@brief Fetch Spectra via CPM
Note: Spectra's CMakeLists.txt doesn't create targets, so we create one manually
]=======================================================================]
function(tula_Spectra_add_cpm)
    # Check if target already exists
    _tula_check_target_exists(Spectra Spectra::Spectra CPM)
    if(_TULA_TARGET_EXISTS)
        _tula_Spectra_create_wrapper()
        return()
    endif()
    
    if(NOT DEFINED TULA_SPECTRA_CPM_GITHUB_REPO)
        return()
    endif()
    
    CPMAddPackage(
        NAME Spectra
        GITHUB_REPOSITORY "${TULA_SPECTRA_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_SPECTRA_CPM_GIT_TAG}"
        DOWNLOAD_ONLY YES  # Avoid install() export issues
    )
    
    if(Spectra_ADDED)
        # Spectra doesn't create targets, so we create one manually
        add_library(Spectra::Spectra INTERFACE IMPORTED GLOBAL)
        target_include_directories(Spectra::Spectra INTERFACE "${Spectra_SOURCE_DIR}/include")
        verbose_message("Fetched Spectra via CPM and created Spectra::Spectra target")
    endif()
    
    if(NOT TARGET Spectra::Spectra)
        return()
    endif()
    _tula_Spectra_create_wrapper()
endfunction()

#[=======================================================================[
@brief Find Spectra via system find_package
]=======================================================================]
function(tula_Spectra_add_system)
    tula_try_system(Spectra Spectra::Spectra)
    if(NOT TULA_Spectra_SYSTEM_SUCCESS)
        return()
    endif()
    _tula_Spectra_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::Spectra wrapper target (includes Eigen3 dependency)
]=======================================================================]
function(_tula_Spectra_create_wrapper)
    if(TARGET tula_Spectra)
        return()
    endif()
    
    if(NOT TARGET Spectra::Spectra)
        message(FATAL_ERROR "Cannot create wrapper: Spectra::Spectra target does not exist")
    endif()
    
    if(NOT TARGET tula::Eigen3)
        message(FATAL_ERROR 
            "Spectra requires Eigen3. Please add Eigen3 before Spectra:\n"
            "  tula_deps_add(deps Eigen3)\n"
            "  tula_deps_add(deps Spectra)")
    endif()
    
    make_tula_target(Spectra Spectra::Spectra tula::Eigen3)
    
    verbose_message("Created tula::Spectra wrapper (with Eigen3 dependency)")
endfunction()

