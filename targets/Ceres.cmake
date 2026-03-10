# Ceres.cmake - Ceres Solver (non-linear least squares optimization)
#
# Defines: tula_Ceres_add_conan(), tula_Ceres_add_cpm(), tula_Ceres_add_system()
# Called by: tula_deps_add(deps Ceres) from tula_deps.cmake
# Note: Ceres requires Eigen3 and optionally perflibs for multithreading

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Load Ceres from Conan
]=======================================================================]
function(tula_Ceres_add_conan)
    tula_try_conan_header_only(Ceres Ceres::ceres Ceres)
    if(NOT TULA_Ceres_CONAN_SUCCESS)
        return()
    endif()
    _tula_Ceres_create_wrapper()
endfunction()

#[=======================================================================[
@brief Fetch Ceres via CPM (requires glog)
]=======================================================================]
function(tula_Ceres_add_cpm)
    if(NOT DEFINED TULA_CERES_CPM_GITHUB_REPO)
        return()
    endif()
    
    # First fetch glog (required dependency)
    verbose_message("Fetching glog (Ceres dependency)...")
    _tula_Ceres_fetch_glog()
    
    # Configure threading model
    option(USE_CERES_MULTITHREADING "Enable multithreading inside Ceres" ON)
    set(_threading_model "NO_THREADS")
    if(USE_CERES_MULTITHREADING)
        set(_threading_model "CXX_THREADS")
    endif()
    
    # Set Eigen3 location for Ceres to find
    if(TARGET Eigen3::Eigen)
        get_target_property(_eigen_include Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
        set(Eigen3_DIR "${_eigen_include}/..")
    endif()
    
    CPMAddPackage(
        NAME ceres
        GITHUB_REPOSITORY "${TULA_CERES_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_CERES_CPM_GIT_TAG}"
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
        verbose_message("Fetched Ceres via CPM")
        
        # Ensure glog is linked to ceres
        if(TARGET ceres AND TARGET glog::glog)
            set_property(TARGET ceres APPEND PROPERTY INTERFACE_LINK_LIBRARIES glog::glog)
            set_property(TARGET ceres APPEND PROPERTY LINK_LIBRARIES glog::glog)
        endif()
    else()
        return()
    endif()
    _tula_Ceres_create_wrapper()
endfunction()

#[=======================================================================[
@brief Internal: Fetch glog for Ceres
]=======================================================================]
function(_tula_Ceres_fetch_glog)
    if(TARGET glog::glog)
        verbose_message("glog already available")
        return()
    endif()
    
    if(NOT DEFINED TULA_CERES_GLOG_CPM_GITHUB_REPO)
        return()
    endif()
    
    # Configure threading for glog
    option(USE_CERES_MULTITHREADING "Enable multithreading inside Ceres" ON)
    set(_glog_threading "OFF")
    set(_glog_tls "OFF")
    if(USE_CERES_MULTITHREADING)
        set(_glog_threading "ON")
        set(_glog_tls "ON")
    endif()
    
    CPMAddPackage(
        NAME glog
        GITHUB_REPOSITORY "${TULA_CERES_GLOG_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_CERES_GLOG_CPM_GIT_TAG}"
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
        return()
    endif()
endfunction()

#[=======================================================================[
@brief Find Ceres via system find_package
]=======================================================================]
function(tula_Ceres_add_system)
    # During toolchain phase (before project()/language enabled), the system
    # Ceres CMake config calls CheckLibraryExists which requires C/CXX language.
    # Fall back to find_library + find_path to create the target directly.
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        _tula_Ceres_add_system_manual()
        return()
    endif()
    tula_try_system(Ceres Ceres::ceres Ceres)
    if(NOT TULA_Ceres_SYSTEM_SUCCESS)
        return()
    endif()
    # Ubuntu's CeresConfig.cmake does not declare glog as a public dependency.
    # Find glog and link it explicitly so executables don't get undefined references.
    find_package(glog QUIET CONFIG)
    if(NOT TARGET glog::glog)
        find_library(_glog_lib NAMES glog PATHS /usr/lib /usr/lib/aarch64-linux-gnu /usr/lib/x86_64-linux-gnu /usr/local/lib)
        if(_glog_lib)
            add_library(glog::glog UNKNOWN IMPORTED)
            set_target_properties(glog::glog PROPERTIES IMPORTED_LOCATION "${_glog_lib}")
        endif()
    endif()
    if(TARGET glog::glog AND TARGET Ceres::ceres)
        set_property(TARGET Ceres::ceres APPEND PROPERTY INTERFACE_LINK_LIBRARIES glog::glog)
    endif()
    _tula_Ceres_create_wrapper()
endfunction()

function(_tula_Ceres_add_system_manual)
    if(TARGET Ceres::ceres)
        _tula_Ceres_create_wrapper()
        return()
    endif()
    find_library(CERES_LIBRARY NAMES ceres
        PATHS /usr/lib /usr/lib/aarch64-linux-gnu /usr/local/lib)
    find_path(CERES_INCLUDE_DIR NAMES ceres/ceres.h
        PATHS /usr/include /usr/local/include)
    if(CERES_LIBRARY AND CERES_INCLUDE_DIR)
        add_library(Ceres::ceres UNKNOWN IMPORTED)
        # Also find glog (Ceres depends on it but Ubuntu CeresConfig may not declare it)
        find_library(GLOG_LIBRARY NAMES glog
            PATHS /usr/lib /usr/lib/aarch64-linux-gnu /usr/lib/x86_64-linux-gnu /usr/local/lib)
        set(_ceres_iface_libs "")
        if(GLOG_LIBRARY)
            list(APPEND _ceres_iface_libs "${GLOG_LIBRARY}")
        endif()
        set_target_properties(Ceres::ceres PROPERTIES
            IMPORTED_LOCATION "${CERES_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${CERES_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "${_ceres_iface_libs}"
        )
        message(STATUS "    Found Ceres (manual): ${CERES_LIBRARY}")
        set(TULA_Ceres_SYSTEM_SUCCESS TRUE PARENT_SCOPE)
        _tula_Ceres_create_wrapper()
    else()
        message(STATUS "    Ceres not found (manual search)")
    endif()
endfunction()

#[=======================================================================[
@brief Create tula::Ceres wrapper target
]=======================================================================]
function(_tula_Ceres_create_wrapper)
    if(TARGET tula_Ceres)
        return()
    endif()
    
    if(NOT TARGET Ceres::ceres)
        message(FATAL_ERROR "Cannot create wrapper: Ceres::ceres target does not exist")
    endif()
    
    set(_deps Ceres::ceres)
    if(TARGET tula::Eigen3)
        list(APPEND _deps tula::Eigen3)
    endif()
    
    # Add perflibs if multithreading enabled and available
    option(USE_CERES_MULTITHREADING "Enable multithreading inside Ceres" ON)
    if(USE_CERES_MULTITHREADING AND TARGET tula::perflibs)
        list(APPEND _deps tula::perflibs)
    endif()
    
    make_tula_target(Ceres ${_deps})
    
    verbose_message("Created tula::Ceres wrapper")
endfunction()
