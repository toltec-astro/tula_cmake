# Yaml.cmake - YAML configuration file parsing support (yaml-cpp library)
# Adapted for v3 Conan-centric architecture with stateless functions

include_guard(GLOBAL)

# Include utilities
include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Main setup function for Yaml (stateless, mode as parameter)

This is the entry point called by tula_deps_add().
Mode is passed as parameter (not global variable).

@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_Yaml MODE)
    verbose_message("Setting up tula::Yaml (mode=${MODE})")
    
    # Idempotency check
    if(TARGET tula::Yaml)
        verbose_message("tula::Yaml already exists, skipping")
        return()
    endif()
    
    # Mode-driven resolution (reuses existing helper functions)
    if(MODE MATCHES "CONAN|AUTO")
        TULA_Yaml_TRY_CONAN()
    elseif(MODE STREQUAL "CPM")
        TULA_Yaml_TRY_CPM()
    elseif(MODE STREQUAL "SYSTEM")
        TULA_Yaml_TRY_SYSTEM()
    else()
        message(FATAL_ERROR "Unknown Yaml mode: ${MODE}")
    endif()
    
    # Create wrapper target
    TULA_Yaml_CREATE_WRAPPER()
    
    verbose_message("tula::Yaml ready")
endfunction()

#[=======================================================================[
@brief Try to find yaml-cpp via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_Yaml_TRY_CONAN)
    # Use existing helper from _deps_callbacks.cmake
    # Third parameter is the find_package name (yaml-cpp vs Yaml)
    tula_try_conan_header_only(Yaml yaml-cpp::yaml-cpp yaml-cpp)
    set(TULA_Yaml_CONAN_SUCCESS ${TULA_Yaml_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch yaml-cpp via CPM
]=======================================================================]
function(TULA_Yaml_TRY_CPM)
    # Use variables set by toolchain (from Yaml.py get_cmake_vars)
    if(NOT DEFINED YAML_CPM_GITHUB_REPO)
        message(FATAL_ERROR "YAML_CPM_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    # Use existing helper from _deps_callbacks.cmake
    tula_try_cpm(Yaml yaml-cpp::yaml-cpp
        NAME yaml-cpp
        GITHUB_REPOSITORY "${YAML_CPM_GITHUB_REPO}"
        GIT_TAG "${YAML_CPM_GIT_TAG}"
        OPTIONS ${YAML_CPM_OPTIONS}
    )
    set(TULA_Yaml_CPM_SUCCESS ${TULA_Yaml_CPM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find yaml-cpp via system find_package
]=======================================================================]
function(TULA_Yaml_TRY_SYSTEM)
    # Use existing helper from _deps_callbacks.cmake
    tula_try_system(Yaml yaml-cpp::yaml-cpp yaml-cpp)
    set(TULA_Yaml_SYSTEM_SUCCESS ${TULA_Yaml_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Yaml wrapper target
]=======================================================================]
function(TULA_Yaml_CREATE_WRAPPER)
    if(TARGET tula_Yaml)
        return()  # Already created
    endif()
    
    if(NOT TARGET yaml-cpp::yaml-cpp)
        message(FATAL_ERROR "Cannot create wrapper: yaml-cpp::yaml-cpp target does not exist")
    endif()
    
    # Create wrapper target using utility
    make_tula_target(Yaml yaml-cpp::yaml-cpp)
    
    verbose_message("Created tula::Yaml wrapper")
endfunction()

