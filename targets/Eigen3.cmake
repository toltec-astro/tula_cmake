# Eigen3.cmake - Eigen linear algebra library
# Adapted for v3 Conan-centric architecture with stateless functions

include_guard(GLOBAL)

# Include utilities
include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Main setup function for Eigen3 (stateless, mode as parameter)

This is the entry point called by tula_deps_add().
Mode is passed as parameter (not global variable).

@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_Eigen3 MODE)
    verbose_message("Setting up tula::Eigen3 (mode=${MODE})")
    
    # Idempotency check
    if(TARGET tula::Eigen3)
        verbose_message("tula::Eigen3 already exists, skipping")
        return()
    endif()
    
    # Mode-driven resolution (reuses existing helper functions)
    if(MODE MATCHES "CONAN|AUTO")
        TULA_Eigen3_TRY_CONAN()
    elseif(MODE STREQUAL "CPM")
        TULA_Eigen3_TRY_CPM()
    elseif(MODE STREQUAL "SYSTEM")
        TULA_Eigen3_TRY_SYSTEM()
    else()
        message(FATAL_ERROR "Unknown Eigen3 mode: ${MODE}")
    endif()
    
    # Create wrapper target with optional MKL/threading support
    TULA_Eigen3_CREATE_WRAPPER()
    
    verbose_message("tula::Eigen3 ready")
endfunction()

#[=======================================================================[
@brief Try to find Eigen3 via Conan (searches CMAKE_INCLUDE_PATH)
]=======================================================================]
function(TULA_Eigen3_TRY_CONAN)
    # Use existing helper from _deps_callbacks.cmake
    tula_try_conan_header_only(Eigen3 Eigen3::Eigen)
    set(TULA_Eigen3_CONAN_SUCCESS ${TULA_Eigen3_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Eigen3 via CPM
]=======================================================================]
function(TULA_Eigen3_TRY_CPM)
    # Use variables set by toolchain (from Eigen3.py get_cmake_vars)
    if(NOT DEFINED EIGEN3_CPM_URL)
        message(FATAL_ERROR "EIGEN3_CPM_URL not set. Check toolchain configuration.")
    endif()
    
    # Use existing helper from _deps_callbacks.cmake
    tula_try_cpm(Eigen3 Eigen3::Eigen
        NAME Eigen3
        URL "${EIGEN3_CPM_URL}"
        OPTIONS ${EIGEN3_CPM_OPTIONS}
    )
    set(TULA_Eigen3_CPM_SUCCESS ${TULA_Eigen3_CPM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find Eigen3 via system find_package
]=======================================================================]
function(TULA_Eigen3_TRY_SYSTEM)
    # Use existing helper from _deps_callbacks.cmake
    tula_try_system(Eigen3 Eigen3::Eigen)
    set(TULA_Eigen3_SYSTEM_SUCCESS ${TULA_Eigen3_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Eigen3 wrapper target with optional MKL/threading support
]=======================================================================]
function(TULA_Eigen3_CREATE_WRAPPER)
    if(TARGET tula_Eigen3)
        return()  # Already created
    endif()
    
    if(NOT TARGET Eigen3::Eigen)
        message(FATAL_ERROR "Cannot create wrapper: Eigen3::Eigen target does not exist")
    endif()
    
    # Optional MKL and multithreading support
    option(USE_EIGEN3_WITH_MKL "Use Intel MKL library if installed" ON)
    option(USE_EIGEN3_MULTITHREADING "Enable multithreading inside Eigen3" ON)
    
    set(eigen3_libs Eigen3::Eigen)
    set(eigen3_defs "")
    
    if(USE_EIGEN3_MULTITHREADING OR USE_EIGEN3_WITH_MKL)
        # Conditional dependency on perflibs
        if(TARGET tula::perflibs)
            list(APPEND eigen3_libs tula::perflibs)
            
            # Check MKL availability
            if(NOT MKL_FOUND AND USE_EIGEN3_WITH_MKL)
                message(WARNING 
                    "USE_EIGEN3_WITH_MKL=ON but MKL is not found. Setting to OFF.\n"
                    "To enable MKL, set USE_INTEL_ONEAPI=ON")
                set_property(CACHE USE_EIGEN3_WITH_MKL PROPERTY VALUE OFF)
            endif()
            
            if(USE_EIGEN3_WITH_MKL)
                list(APPEND eigen3_defs EIGEN_USE_MKL_ALL)
            endif()
            
            if(NOT USE_EIGEN3_MULTITHREADING)
                list(APPEND eigen3_defs EIGEN_DONT_PARALLELIZE)
            endif()
        else()
            verbose_message("perflibs not available, skipping MKL/threading support")
        endif()
    endif()
    
    # Create wrapper target using utility
    make_tula_target(Eigen3 ${eigen3_libs})
    
    # Add compile definitions if any
    if(eigen3_defs)
        target_compile_definitions(tula_Eigen3 INTERFACE ${eigen3_defs})
        foreach(def ${eigen3_defs})
            verbose_message("Eigen3 defined: ${def}")
        endforeach()
    endif()
    
    verbose_message("Created tula::Eigen3 wrapper")
endfunction()

