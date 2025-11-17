# Ceres.cmake - Ceres Solver (non-linear least squares optimization)
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Setup Ceres package with tri-modal resolution
@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_Ceres MODE)
    verbose_message("Setting up tula::Ceres (mode=${MODE})")
    
    if(TARGET tula::Ceres)
        verbose_message("tula::Ceres already exists")
        return()
    endif()
    
    # Ensure Eigen3 dependency is available
    if(NOT TARGET tula::Eigen3)
        verbose_message("Ceres requires Eigen3, loading it first...")
        tula_deps_add(_eigen_dep Eigen3)
    endif()
    
    # Optionally load perflibs for multithreading support
    option(USE_CERES_MULTITHREADING "Enable multithreading inside Ceres" ON)
    if(USE_CERES_MULTITHREADING)
        if(NOT TARGET tula::perflibs)
            verbose_message("Loading perflibs for Ceres multithreading...")
            tula_deps_add(_perflibs_dep perflibs)
        endif()
    endif()
    
    if(MODE STREQUAL "AUTO")
        TULA_Ceres_TRY_CONAN()
        if(NOT TULA_Ceres_CONAN_SUCCESS)
            TULA_Ceres_TRY_CPM()
        endif()
        if(NOT TULA_Ceres_CPM_SUCCESS)
            TULA_Ceres_TRY_SYSTEM()
        endif()
    elseif(MODE STREQUAL "CONAN")
        TULA_Ceres_TRY_CONAN()
    elseif(MODE STREQUAL "CPM")
        TULA_Ceres_TRY_CPM()
    elseif(MODE STREQUAL "SYSTEM")
        TULA_Ceres_TRY_SYSTEM()
    else()
        message(FATAL_ERROR "Invalid MODE for Ceres: ${MODE}")
    endif()
    
    # Create wrapper
    TULA_Ceres_CREATE_WRAPPER()
    verbose_message("tula::Ceres ready")
endfunction()

#[=======================================================================[
@brief Try to find Ceres via Conan
]=======================================================================]
function(TULA_Ceres_TRY_CONAN)
    tula_try_conan_header_only(Ceres Ceres::ceres Ceres)
    set(TULA_Ceres_CONAN_SUCCESS ${TULA_Ceres_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Ceres via CPM (requires glog)
]=======================================================================]
function(TULA_Ceres_TRY_CPM)
    if(NOT DEFINED CERES_CPM_GITHUB_REPO)
        message(FATAL_ERROR "CERES_CPM_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    # First fetch glog (required dependency)
    verbose_message("Fetching glog (Ceres dependency)...")
    _TULA_Ceres_FETCH_GLOG()
    
    # Configure threading model
    set(_threading_model "NO_THREADS")
    if(USE_CERES_MULTITHREADING)
        set(_threading_model "CXX_THREADS")
    endif()
    
    # Set Eigen3 location for Ceres to find
    if(TARGET Eigen3::Eigen)
        get_target_property(_eigen_include Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
        set(Eigen3_DIR "${_eigen_include}/..")
    endif()
    
    include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)
    
    CPMAddPackage(
        NAME ceres
        GITHUB_REPOSITORY "${CERES_CPM_GITHUB_REPO}"
        GIT_TAG "${CERES_CPM_GIT_TAG}"
        OPTIONS
            "GLOG_PREFER_EXPORTED_GLOG_CMAKE_CONFIGURATION ON"
            "MINIGLOG OFF"
            "GFLAGS OFF"
            "EIGENSPARSE ON"
            "SUITESPARSE OFF"
            "CXSPARSE OFF"
            "ACCELERATESPARSE OFF"
            "SCHUR_SPECIALIZATIONS ON"
            "BUILD_DOCUMENTATION OFF"
            "BUILD_TESTING OFF"
            "BUILD_EXAMPLES OFF"
            "BUILD_BENCHMARKS OFF"
            "BUILD_SHARED_LIBS OFF"
            "CERES_THREADING_MODEL ${_threading_model}"
    )
    
    if(ceres_ADDED OR TARGET Ceres::ceres)
        message(STATUS "    Fetched Ceres via CPM")
        
        # Ensure glog is linked to ceres
        if(TARGET ceres AND TARGET glog::glog)
            set_property(TARGET ceres APPEND PROPERTY INTERFACE_LINK_LIBRARIES glog::glog)
            set_property(TARGET ceres APPEND PROPERTY LINK_LIBRARIES glog::glog)
        endif()
        
        set(TULA_Ceres_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        message(STATUS "    CPM fetch failed for Ceres")
        set(TULA_Ceres_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Internal: Fetch glog for Ceres
]=======================================================================]
function(_TULA_Ceres_FETCH_GLOG)
    if(TARGET glog::glog)
        verbose_message("glog already available")
        return()
    endif()
    
    if(NOT DEFINED CERES_GLOG_CPM_GITHUB_REPO)
        message(FATAL_ERROR "CERES_GLOG_CPM_GITHUB_REPO not set")
    endif()
    
    # Configure threading for glog
    set(_glog_threading "OFF")
    set(_glog_tls "OFF")
    if(USE_CERES_MULTITHREADING)
        set(_glog_threading "ON")
        set(_glog_tls "ON")
    endif()
    
    include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)
    
    CPMAddPackage(
        NAME glog
        GITHUB_REPOSITORY "${CERES_GLOG_CPM_GITHUB_REPO}"
        GIT_TAG "${CERES_GLOG_CPM_GIT_TAG}"
        OPTIONS
            "BUILD_SHARED_LIBS OFF"
            "WITH_GFLAGS OFF"
            "WITH_GTEST OFF"
            "WITH_PKGCONFIG OFF"
            "WITH_SYMBOLIZE OFF"
            "WITH_UNWIND OFF"
            "BUILD_TESTING OFF"
            "WITH_THREADS ${_glog_threading}"
            "WITH_TLS ${_glog_tls}"
    )
    
    if(glog_ADDED OR TARGET glog::glog)
        verbose_message("Fetched glog via CPM")
    else()
        message(FATAL_ERROR "Failed to fetch glog (required for Ceres)")
    endif()
endfunction()

#[=======================================================================[
@brief Try to find Ceres via system find_package
]=======================================================================]
function(TULA_Ceres_TRY_SYSTEM)
    tula_try_system(Ceres Ceres::ceres Ceres)
    set(TULA_Ceres_SYSTEM_SUCCESS ${TULA_Ceres_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Ceres wrapper target
]=======================================================================]
function(TULA_Ceres_CREATE_WRAPPER)
    set(_deps Ceres::ceres)
    
    # Add perflibs if multithreading enabled
    if(USE_CERES_MULTITHREADING AND TARGET tula::perflibs)
        list(APPEND _deps tula::perflibs)
    endif()
    
    tula_create_wrapper(Ceres ${_deps})
    verbose_message("Created tula::Ceres wrapper")
endfunction()
