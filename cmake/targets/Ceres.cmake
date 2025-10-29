# Ceres.cmake - Ceres Solver (nonlinear least squares optimization)
# Single-include workflow with callback-based target creation

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_Ceres)
    message(STATUS "(Ceres) Target tula_Ceres already exists, skipping")
    return()
endif()

option(USE_CERES_MULTITHREADING "Enable multithreading inside Ceres" ON)

# Ceres depends on Eigen3
if (NOT TARGET tula::Eigen3)
    include(Eigen3)
endif()

# Add performance libraries if multithreading enabled
set(_ceres_extra_libs "")
if (USE_CERES_MULTITHREADING)
    if (NOT TARGET tula::perflibs)
        include(perflibs)
    endif()
    list(APPEND _ceres_extra_libs tula::perflibs)
endif()

#[=======================================================================[
@brief Create Ceres::ceres target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_ceres_create_conan_target)
    if(TARGET Ceres::ceres)
        return()  # Already created
    endif()
    
    # Conan provides include/lib paths via CMAKE_INCLUDE_PATH
    set(CERES_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "ceres")
            set(CERES_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT CERES_INCLUDE_DIR)
        message(STATUS "  ✗ Ceres not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target (simplified - full version would link library)
    add_library(Ceres::ceres INTERFACE IMPORTED GLOBAL)
    target_include_directories(Ceres::ceres INTERFACE "${CERES_INCLUDE_DIR}")
    message(STATUS "  ✓ Created Ceres::ceres target from Conan: ${CERES_INCLUDE_DIR}")
endfunction()

# Eigen3 shim helper for CPM mode (Ceres needs to find Eigen3 via find_package)
function(_tula_ceres_create_eigen3_shim)
    if(TARGET Eigen3::Eigen)
        get_target_property(_eigen3_include Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
        if(_eigen3_include)
            string(REGEX REPLACE "\\$<BUILD_INTERFACE:([^>]+)>.*" "\\1" _eigen3_root "${_eigen3_include}")
            # Create minimal Eigen3Config.cmake in build directory for Ceres to find
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
                "set(Eigen3_VERSION_MAJOR 3)\n"
                "set(Eigen3_VERSION_MINOR 4)\n"
                "set(Eigen3_VERSION_PATCH 1)\n"
            )
            file(WRITE "${_eigen3_config_dir}/Eigen3ConfigVersion.cmake"
                "set(PACKAGE_VERSION \"3.4.1\")\n"
                "set(PACKAGE_VERSION_EXACT FALSE)\n"
                "set(PACKAGE_VERSION_COMPATIBLE TRUE)\n"
                "if(\"\${PACKAGE_FIND_VERSION}\" VERSION_GREATER \"3.4.1\")\n"
                "  set(PACKAGE_VERSION_COMPATIBLE FALSE)\n"
                "endif()\n"
                "if(\"\${PACKAGE_FIND_VERSION}\" STREQUAL \"3.4.1\")\n"
                "  set(PACKAGE_VERSION_EXACT TRUE)\n"
                "endif()\n"
            )
            set(CMAKE_PREFIX_PATH "${CMAKE_BINARY_DIR}/cmake" ${CMAKE_PREFIX_PATH} PARENT_SCOPE)
            verbose_message("Created Eigen3 shim config for Ceres at: ${_eigen3_config_dir}")
        endif()
    endif()
endfunction()

# Find or fetch Ceres Solver
tula_deps_register(Ceres
    CONAN_NAME Ceres
    CONAN_TARGET_CALLBACK _tula_ceres_create_conan_target
    CONAN_TARGET_NAME Ceres::ceres
    CPM_GITHUB_REPOSITORY ceres-solver/ceres-solver
    CPM_GIT_TAG master
    CPM_OPTIONS
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
    SYSTEM_NAME Ceres
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::Ceres after dependency is resolved
function(_tula_ceres_create_wrapper)
    if(TARGET tula_Ceres)
        return()  # Already created
    endif()
    
    # Determine which Ceres target is available
    set(_ceres_libs "")
    if(TARGET Ceres::ceres)
        list(APPEND _ceres_libs Ceres::ceres)
    elseif(TARGET ceres)
        list(APPEND _ceres_libs ceres)
    else()
        message(FATAL_ERROR "Ceres target not found after dependency resolution")
    endif()

    # Add extra libraries
    list(APPEND _ceres_libs ${_ceres_extra_libs})

    # Create tula interface library
    include(make_tula_target)
    make_tula_target(Ceres ${_ceres_libs})
    
    verbose_message("Ceres configured: tula::Ceres")
endfunction()

# If Ceres already exists, create wrapper now
if(TARGET Ceres::ceres OR TARGET ceres)
    _tula_ceres_create_wrapper()
endif()
