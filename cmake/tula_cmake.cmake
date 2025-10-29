# tula_cmake - Tri-modal dependency management
#
# Extends tula_sensible with dependency management features.
# Provides CONAN/CPM/SYSTEM resolution for external packages.
#
# REQUIREMENT: Must be included AFTER project() call
#
# Usage:
#   project(MyProject LANGUAGES CXX)
#   include(tula_cmake)
#   include(Eigen3)
#   tula_deps_create_targets()

include_guard(GLOBAL)

# Include sensible defaults first
include(tula_sensible)

# ============================================================================
# Dependency Management Setup
# ============================================================================

# Add targets to module path
set(CMAKE_MODULE_PATH 
    "${CMAKE_CURRENT_LIST_DIR}/targets"
    ${CMAKE_MODULE_PATH}
)

# Configure cache for CPM
set(TULA_CACHE_ROOT "$ENV{HOME}/.tula_cache" CACHE PATH "Root directory for all tula cache files")
file(MAKE_DIRECTORY "${TULA_CACHE_ROOT}")
file(MAKE_DIRECTORY "${TULA_CACHE_ROOT}/cpm")

if(NOT DEFINED CPM_SOURCE_CACHE)
    set(CPM_SOURCE_CACHE "${TULA_CACHE_ROOT}/cpm" CACHE PATH "CPM source cache directory")
endif()

message(STATUS "[cache] CPM source cache: ${CPM_SOURCE_CACHE}")
message(STATUS "[cache] tula cache root: ${TULA_CACHE_ROOT}")
# Note: Conan uses system default cache (~/.conan2)

# ============================================================================
# Package Management - Tri-modal resolution: CONAN → CPM → SYSTEM
# ============================================================================
# Override per-package: -DTULA_{PACKAGE}_MODE=CONAN|CPM|SYSTEM
#
# Workflow:
#   1. include(PackageName)         → Calls tula_deps_register()
#   2. tula_deps_create_targets()   → Runs conan install, tries modes, creates targets

#[=======================================================================[.rst:
tula_deps_register
------------------
Register a package for tri-modal resolution.

Called automatically by target files (e.g., Eigen3.cmake).
Adds package to registry and tracks if Conan is needed.

Mode override: -DTULA_{PACKAGE}_MODE=CONAN|CPM|SYSTEM
#]=======================================================================]
function(tula_deps_register PACKAGE_NAME)
    # Check for per-package mode override
    if(DEFINED TULA_${PACKAGE_NAME}_MODE)
        set(FORCE_MODE "${TULA_${PACKAGE_NAME}_MODE}")
        message(STATUS "tula_deps_register(${PACKAGE_NAME}): User forced to ${FORCE_MODE} mode")
    else()
        message(STATUS "tula_deps_register(${PACKAGE_NAME}): Registered for later resolution")
    endif()
    
    # Store only the package name and optional forced mode
    set_property(GLOBAL PROPERTY TULA_DEP_${PACKAGE_NAME}_FORCE_MODE "${FORCE_MODE}")
    
    # Add to global list of registered packages
    get_property(_registered_packages GLOBAL PROPERTY TULA_REGISTERED_PACKAGES)
    if(NOT _registered_packages)
        set(_registered_packages "")
    endif()
    list(APPEND _registered_packages ${PACKAGE_NAME})
    list(REMOVE_DUPLICATES _registered_packages)
    set_property(GLOBAL PROPERTY TULA_REGISTERED_PACKAGES "${_registered_packages}")
    
    # Track packages that might need Conan (for Phase 2)
    if(COMMAND TULA_${PACKAGE_NAME}_TRY_CONAN AND (NOT FORCE_MODE OR FORCE_MODE STREQUAL "CONAN"))
        get_property(_conan_packages GLOBAL PROPERTY TULA_CONAN_PACKAGES)
        if(NOT _conan_packages)
            set(_conan_packages "")
        endif()
        list(APPEND _conan_packages ${PACKAGE_NAME})
        list(REMOVE_DUPLICATES _conan_packages)
        set_property(GLOBAL PROPERTY TULA_CONAN_PACKAGES "${_conan_packages}")
    endif()
endfunction()

#[=======================================================================[.rst:
tula_deps_create_targets
-------------------------
Create targets for all registered packages.

1. Runs conan install for packages needing CONAN mode
2. For each package, tries modes: CONAN → CPM → SYSTEM
3. Calls TULA_{PACKAGE}_CREATE_WRAPPER() if available

Each target file must define:
  - TULA_{PACKAGE}_TRY_CONAN()  - optional
  - TULA_{PACKAGE}_TRY_CPM()    - optional
  - TULA_{PACKAGE}_TRY_SYSTEM() - optional
  - TULA_{PACKAGE}_CREATE_WRAPPER() - optional

Each TRY_* function sets TULA_{PACKAGE}_{MODE}_SUCCESS=TRUE/FALSE
#]=======================================================================]
function(tula_deps_create_targets)
    # Get list of all registered packages
    get_property(_registered_packages GLOBAL PROPERTY TULA_REGISTERED_PACKAGES)
    
    if(NOT _registered_packages)
        message(STATUS "tula_deps_create_targets(): No packages registered")
        return()
    endif()
    
    # Check if any packages need Conan and run conan install if needed
    get_property(_conan_packages GLOBAL PROPERTY TULA_CONAN_PACKAGES)
    if(_conan_packages)
        list(LENGTH _conan_packages _num_conan_packages)
        message(STATUS "Running Conan for ${_num_conan_packages} package(s): ${_conan_packages}")
        
        # Find conan command
        if(NOT DEFINED CONAN_COMMAND OR NOT CONAN_COMMAND)
            find_program(CONAN_COMMAND conan)
            if(NOT CONAN_COMMAND)
                message(WARNING "Conan command not found. Set CONAN_COMMAND or add conan to PATH.")
                message(STATUS "Will skip CONAN mode and try CPM/SYSTEM fallback")
                set(_conan_packages "")  # Clear to skip conan install
            endif()
        endif()
    endif()
    
    if(_conan_packages)
        # Build conan install command with package options
        # Use tula/*: scope to explicitly target tula's conanfile options
        set(_conan_options "")
        foreach(_pkg IN LISTS _conan_packages)
            # Package names in conanfile.py match CMake package names (e.g., Eigen3, Yaml)
            # Use tula/*:PackageName=True to scope options to tula
            list(APPEND _conan_options "-o" "tula/*:${_pkg}=True")
        endforeach()
        
        # Run conan install
        execute_process(
            COMMAND ${CONAN_COMMAND} install ${CMAKE_SOURCE_DIR}
                --build=missing
                --output-folder=${CMAKE_BINARY_DIR}
                -s build_type=${CMAKE_BUILD_TYPE}
                ${_conan_options}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            RESULT_VARIABLE _conan_result
            OUTPUT_VARIABLE _conan_output
            ERROR_VARIABLE _conan_error
        )
        
        if(NOT _conan_result EQUAL 0)
            message(WARNING "Conan install failed (exit code: ${_conan_result})")
            message(WARNING "Conan output: ${_conan_output}")
            message(WARNING "Conan error: ${_conan_error}")
            message(STATUS "Will try CPM/SYSTEM fallback for affected packages")
        else()
            message(STATUS "Conan install completed successfully")
            # Include the generated toolchain
            if(EXISTS "${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
                include("${CMAKE_BINARY_DIR}/conan_toolchain.cmake")
            endif()
        endif()
        message(STATUS "")
    endif()
    
    list(LENGTH _registered_packages _num_packages)
    message(STATUS "Creating targets for ${_num_packages} registered package(s)...")
    message(STATUS "")
    
    foreach(PACKAGE_NAME IN LISTS _registered_packages)
        message(STATUS "tula_deps_create_targets(${PACKAGE_NAME}):")
        
        # Get forced mode if any
        get_property(FORCE_MODE GLOBAL PROPERTY TULA_DEP_${PACKAGE_NAME}_FORCE_MODE)
        
        # Determine modes to try based on available functions
        set(_modes_to_try "")
        set(USER_FORCED_MODE FALSE)
        
        if(FORCE_MODE)
            list(APPEND _modes_to_try ${FORCE_MODE})
            set(USER_FORCED_MODE TRUE)
            message(STATUS "  User forced to ${FORCE_MODE} mode")
        else()
            # Automatic fallback: check which functions exist
            if(COMMAND TULA_${PACKAGE_NAME}_TRY_CONAN)
                list(APPEND _modes_to_try CONAN)
            endif()
            if(COMMAND TULA_${PACKAGE_NAME}_TRY_CPM)
                list(APPEND _modes_to_try CPM)
            endif()
            if(COMMAND TULA_${PACKAGE_NAME}_TRY_SYSTEM)
                list(APPEND _modes_to_try SYSTEM)
            endif()
            
            if(_modes_to_try)
                message(STATUS "  Available modes: ${_modes_to_try}")
            else()
                message(WARNING "  No TULA_${PACKAGE_NAME}_TRY_* functions found!")
                continue()
            endif()
        endif()
        
        # Try each mode until one succeeds
        set(_package_found FALSE)
        
        foreach(_try_mode IN LISTS _modes_to_try)
            message(STATUS "  Trying ${_try_mode} mode...")
            
            # Call the package-specific function
            set(_function_name "TULA_${PACKAGE_NAME}_TRY_${_try_mode}")
            
            if(COMMAND ${_function_name})
                cmake_language(CALL ${_function_name})
                
                # Check if a return value was set by the function
                # Convention: function sets TULA_${PACKAGE_NAME}_${MODE}_SUCCESS to TRUE/FALSE
                set(_success_var "TULA_${PACKAGE_NAME}_${_try_mode}_SUCCESS")
                if(DEFINED ${_success_var} AND ${_success_var})
                    message(STATUS "  ✓ ${_try_mode} mode succeeded")
                    set(${PACKAGE_NAME}_MODE "${_try_mode}" PARENT_SCOPE)
                    set(_package_found TRUE)
                    break()
                else()
                    message(STATUS "  ✗ ${_try_mode} mode failed, trying next mode")
                endif()
            else()
                message(STATUS "  ✗ Function ${_function_name} not found")
            endif()
        endforeach()
        
        if(NOT _package_found)
            if(USER_FORCED_MODE)
                message(FATAL_ERROR "${PACKAGE_NAME} not found in forced ${FORCE_MODE} mode")
            else()
                message(FATAL_ERROR "${PACKAGE_NAME} not found in any mode (tried: ${_modes_to_try})")
            endif()
        endif()
        
        # Call wrapper creation function if it exists
        if(COMMAND TULA_${PACKAGE_NAME}_CREATE_WRAPPER)
            cmake_language(CALL TULA_${PACKAGE_NAME}_CREATE_WRAPPER)
        endif()
        
        message(STATUS "")
    endforeach()
endfunction()
