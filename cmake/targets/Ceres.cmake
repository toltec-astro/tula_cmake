# Ceres.cmake - Ceres Solver (nonlinear least squares optimization)

include(_deps_callbacks)

# Skip if target already exists
if(TARGET tula_Ceres)
    message(STATUS "(Ceres) Target tula_Ceres already exists, skipping")
    return()
endif()

option(USE_CERES_MULTITHREADING "Enable multithreading inside Ceres" ON)

# Ceres depends on Eigen3
if(NOT TARGET tula::Eigen3)
    include(Eigen3)
endif()

# Add performance libraries if multithreading enabled
if(USE_CERES_MULTITHREADING)
    if(NOT TARGET tula::perflibs)
        include(perflibs)
    endif()
endif()

# Add performance libraries if multithreading enabled
if(USE_CERES_MULTITHREADING)
    if(NOT TARGET tula::perflibs)
        include(perflibs)
    endif()
endif()

#[=======================================================================[
@brief Helper to create Eigen3 shim config for Ceres CPM mode
Ceres needs to find Eigen3 via find_package during its CMake configuration
]=======================================================================]
function(_tula_ceres_create_eigen3_shim)
    if(TARGET Eigen3::Eigen)
        get_target_property(_eigen3_include Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
        if(_eigen3_include)
            string(REGEX REPLACE "\\$<BUILD_INTERFACE:([^>]+)>.*" "\\1" _eigen3_root "${_eigen3_include}")
            
            # Create minimal Eigen3Config.cmake in build directory
            set(_eigen3_config_dir "${CMAKE_BINARY_DIR}/cmake/Eigen3")
            file(MAKE_DIRECTORY "${_eigen3_config_dir}")
            file(WRITE "${_eigen3_config_dir}/Eigen3Config.cmake"
                "if(NOT TARGET Eigen3::Eigen)\n"
                "  add_library(Eigen3::Eigen INTERFACE IMPORTED)\n"
                "  set_target_properties(Eigen3::Eigen PROPERTIES\n"
                "    INTERFACE_INCLUDE_DIRECTORIES \"${_eigen3_root}\"\n"
                "  )\n"
                "endif()\n"
                "set(Eigen3_FOUND TRUE)\n"
                "set(EIGEN3_FOUND TRUE)\n"
                "set(EIGEN3_INCLUDE_DIR \"${_eigen3_root}\")\n"
                "set(Eigen3_VERSION \"3.4.1\")\n"
            )
            file(WRITE "${_eigen3_config_dir}/Eigen3ConfigVersion.cmake"
                "set(PACKAGE_VERSION \"3.4.1\")\n"
                "set(PACKAGE_VERSION_COMPATIBLE TRUE)\n"
            )
            set(CMAKE_PREFIX_PATH "${CMAKE_BINARY_DIR}/cmake" ${CMAKE_PREFIX_PATH} PARENT_SCOPE)
            
            if(VERBOSE_MESSAGE)
                include(verbose_message)
                verbose_message("Created Eigen3 shim for Ceres: ${_eigen3_config_dir}")
            endif()
        endif()
    endif()
endfunction()

#[=======================================================================[
@brief Try to find Ceres via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_Ceres_TRY_CONAN)
    tula_try_conan_header_only(Ceres Ceres::ceres)
    set(TULA_Ceres_CONAN_SUCCESS ${TULA_Ceres_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Ceres via CPM
Complexity: Needs glog dependency and Eigen3 shim
]=======================================================================]
function(TULA_Ceres_TRY_CPM)
    _tula_check_target_exists(Ceres Ceres::ceres CPM)
    if(_TULA_TARGET_EXISTS)
        return()
    endif()
    
    include(_ensure_cpm)
    
    # Create Eigen3 shim so Ceres can find it
    _tula_ceres_create_eigen3_shim()
    
    # Fetch glog first (Ceres dependency when not using MINIGLOG)
    # For simplicity, we'll use MINIGLOG=ON to avoid glog complexity
    set(_ceres_threading_model "NO_THREADS")
    if(USE_CERES_MULTITHREADING)
        set(_ceres_threading_model "CXX_THREADS")
    endif()
    
    CPMAddPackage(
        NAME ceres-solver
        GITHUB_REPOSITORY ceres-solver/ceres-solver
        GIT_TAG 2.2.0
        OPTIONS
            "BUILD_SHARED_LIBS OFF"
            "BUILD_TESTING OFF"
            "BUILD_DOCUMENTATION OFF"
            "BUILD_EXAMPLES OFF"
            "BUILD_BENCHMARKS OFF"
            "GFLAGS OFF"
            "MINIGLOG ON"
            "EIGENSPARSE ON"
            "SUITESPARSE OFF"
            "CXSPARSE OFF"
            "ACCELERATESPARSE OFF"
            "LAPACK OFF"
            "SCHUR_SPECIALIZATIONS ON"
            "PROVIDE_UNINSTALL_TARGET OFF"
            "EXPORT_BUILD_DIR OFF"
            "CMAKE_SKIP_INSTALL_RULES ON"
            "CERES_THREADING_MODEL ${_ceres_threading_model}"
    )
    
    if(ceres-solver_ADDED)
        # Check if Ceres::ceres alias exists
        if(NOT TARGET Ceres::ceres AND TARGET ceres)
            add_library(Ceres::ceres ALIAS ceres)
        endif()
        
        message(STATUS "    Fetched ceres-solver via CPM")
        set(TULA_Ceres_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        message(STATUS "    CPM fetch failed for ceres-solver")
        set(TULA_Ceres_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Try to find Ceres via system find_package
]=======================================================================]
function(TULA_Ceres_TRY_SYSTEM)
    tula_try_system(Ceres Ceres::ceres)
    set(TULA_Ceres_SYSTEM_SUCCESS ${TULA_Ceres_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Ceres wrapper target
]=======================================================================]
function(TULA_Ceres_CREATE_WRAPPER)
    if(TARGET tula_Ceres)
        return()  # Already created
    endif()
    
    if(NOT TARGET Ceres::ceres)
        message(FATAL_ERROR "Cannot create wrapper: Ceres::ceres target does not exist")
    endif()
    
    # Build dependency list
    set(_ceres_deps Ceres::ceres)
    if(USE_CERES_MULTITHREADING AND TARGET tula::perflibs)
        list(APPEND _ceres_deps tula::perflibs)
    endif()
    
    include(make_tula_target)
    make_tula_target(Ceres ${_ceres_deps})
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        verbose_message("Ceres configured: tula::Ceres (multithreading=${USE_CERES_MULTITHREADING})")
    endif()
endfunction()

# Register Ceres for tri-modal resolution
tula_deps_register(Ceres)
