# tula CMake Initialization
# 
# Single unified include for tula CMake infrastructure
# Include this at the beginning of your CMakeLists.txt (before or after project())
#
# Purpose:
#   - Set up CMAKE_MODULE_PATH for tula utilities
#   - Check CMake version requirement  
#   - Configure unified cache directory ($HOME/.tula_cache)
#   - Define tri-modal package management functions (CONAN/CPM/SYSTEM)
#   - Apply sensible build defaults (RPATH, output directories, etc.)
#   - Configure compiler and platform-specific settings
#
# Usage:
#   set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/tula_cmake/cmake" ${CMAKE_MODULE_PATH})
#   include(tula_cmake)
#   project(MyProject LANGUAGES CXX)
#
# CMake 4.1+ required
# Author: tula team

include_guard(GLOBAL)

# ============================================================================
# PART 1: Module Path and Version Check
# ============================================================================

set(CMAKE_MODULE_PATH 
    "${CMAKE_CURRENT_LIST_DIR}" 
    "${CMAKE_CURRENT_LIST_DIR}/utils"
    "${CMAKE_CURRENT_LIST_DIR}/targets"
    ${CMAKE_MODULE_PATH}
)

include(check_cmake_version)
check_cmake_version("4.1" MODULE_NAME "tula_cmake")

include(verbose_message)

# ============================================================================
# PART 2: Unified Cache Directory Configuration  
# ============================================================================

set(TULA_CACHE_ROOT "$ENV{HOME}/.tula_cache" CACHE PATH "Root directory for all tula cache files")

# Create cache directories
file(MAKE_DIRECTORY "${TULA_CACHE_ROOT}")
file(MAKE_DIRECTORY "${TULA_CACHE_ROOT}/cpm")

# CPM source cache (downloaded git repositories)
if(NOT DEFINED CPM_SOURCE_CACHE)
    set(CPM_SOURCE_CACHE "${TULA_CACHE_ROOT}/cpm" CACHE PATH "CPM source cache directory")
endif()

message(STATUS "[cache] CPM source cache: ${CPM_SOURCE_CACHE}")
message(STATUS "[cache] tula cache root: ${TULA_CACHE_ROOT}")
# Note: Conan uses system default cache (~/.conan2) - configure with: conan config home

# ============================================================================
# PART 3: Package Management Functions
# ============================================================================
# Tri-modal package finding with automatic fallback: CONAN → CPM → SYSTEM
# Override per-package with: -DTULA_<PACKAGE>_MODE=<CONAN|CPM|SYSTEM>
#
# Usage (after project() call):
#   1. include(PackageName)           # Registers dependency
#   2. tula_conan_install()           # Runs Conan for registered packages
#   3. tula_deps_create_targets()     # Creates targets via callbacks/CPM/find_package

#[=======================================================================[.rst:
tula_deps_register
------------------

Register a dependency for later resolution (Phase 1 of three-phase workflow).

Simply adds the package name to a global registry. The actual package configuration
is handled by functions defined in the package's .cmake file following the naming
convention: TULA_{PACKAGE_NAME}_*

.. code-block:: cmake

  tula_deps_register(<PackageName>)

**Expected Functions in {PackageName}.cmake:**
  - TULA_{PACKAGE_NAME}_TRY_CONAN()  - Optional: Try to find via Conan
  - TULA_{PACKAGE_NAME}_TRY_CPM()    - Optional: Try to fetch via CPM
  - TULA_{PACKAGE_NAME}_TRY_SYSTEM() - Optional: Try to find via system
  - TULA_{PACKAGE_NAME}_CREATE_WRAPPER() - Optional: Create tula:: wrapper target

**Mode Selection Priority:**
  1. Per-package override: -DTULA_<PackageName>_MODE=<CONAN|CPM|SYSTEM>
  2. Automatic fallback: CONAN → CPM → SYSTEM (tries each available function)

**Workflow:**
  1. Call tula_deps_register() for each dependency (Phase 1)
  2. Call tula_conan_install() to run Conan (Phase 2)
  3. Call tula_deps_create_targets() to create all targets (Phase 3)
  
**Example:**
  # In Eigen3.cmake:
  function(TULA_Eigen3_TRY_CONAN)
      # Search CMAKE_INCLUDE_PATH for Eigen and create target
  endfunction()
  
  function(TULA_Eigen3_TRY_CPM)
      CPMAddPackage(...)
  endfunction()
  
  function(TULA_Eigen3_TRY_SYSTEM)
      find_package(Eigen3 CONFIG)
  endfunction()
  
  tula_deps_register(Eigen3)

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
tula_conan_install
------------------

Run Conan install for all registered CONAN packages (Phase 2).
Must be called after tula_deps_register() and before tula_deps_create_targets().

This function is provided by ConanIntegration.cmake when Conan support is enabled.
If ConanIntegration is not available, this is a no-op.

#]=======================================================================]
# The actual implementation is in ConanIntegration.cmake
# We just document it here for completeness

#[=======================================================================[.rst:
tula_deps_create_targets
-------------------------

Create targets for all registered dependencies (Phase 3).
Must be called after tula_conan_install().

For each registered package, tries modes in priority order:
  1. CONAN - Invokes package callback to create target from Conan paths
  2. CPM - Downloads and builds with CPMAddPackage
  3. SYSTEM - Uses find_package to locate system installation

#[=======================================================================[.rst:
tula_deps_create_targets
-------------------------

Create targets for all registered dependencies (Phase 3).
Must be called after tula_conan_install().

For each registered package, invokes package-specific functions based on naming convention:
  1. CONAN - Calls TULA_{PACKAGE}_TRY_CONAN() if it exists
  2. CPM - Calls TULA_{PACKAGE}_TRY_CPM() if it exists
  3. SYSTEM - Calls TULA_{PACKAGE}_TRY_SYSTEM() if it exists

Each TRY_* function should:
  - Attempt to find/fetch the package in that mode
  - Create the necessary CMake targets
  - Return success (target created) or failure (try next mode)

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
        set(_conan_options "")
        foreach(_pkg IN LISTS _conan_packages)
            # Convert package name to lowercase for conan option
            string(TOLOWER "${_pkg}" _pkg_lower)
            list(APPEND _conan_options "-o" "${_pkg_lower}=True")
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

# ============================================================================
# PART 4: Sensible Build Defaults
# ============================================================================
# This section is only applied after project() is called

# Detect if project() has been called by checking if PROJECT_NAME is set
if(PROJECT_NAME)
    # No build-in-src guard
    file(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}/CMakeLists.txt" LOC_PATH)
    if(EXISTS "${LOC_PATH}")
        message(FATAL_ERROR "You cannot build in a source directory (or any directory with a CMakeLists.txt file). Please make a build subdirectory. Feel free to remove CMakeCache.txt and CMakeFiles.")
    endif()
    
    # Detect build type if not specified
    include(detect_build_type)
    
    # Some sensible settings
    set_property(GLOBAL PROPERTY ALLOW_DUPLICATE_CUSTOM_TARGETS TRUE)
    set(CMAKE_FIND_REQUIRED OFF)  # Manage per-package via tula_deps_register()
    
    # Paths and directories
    SET(CMAKE_SKIP_BUILD_RPATH FALSE)
    SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
    SET(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)  # Use relative paths in build RPATH
    SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    include(GNUInstallDirs)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    
    # Language settings
    enable_language(CXX)
    enable_language(C)
    
    # Individual targets can override with target_compile_features(target PUBLIC cxx_std_23)
    set(CMAKE_CXX_STANDARD 23 CACHE STRING "C++ standard to use")
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    
    # Platform specifics
    if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        # macOS-specific settings
        set(CMAKE_MACOSX_RPATH TRUE)
        
        # For Homebrew-installed LLVM
        if (CMAKE_CXX_COMPILER_ID STREQUAL Clang)
            get_filename_component(compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
            get_filename_component(compiler_libdir ${compiler_bindir}/../lib ABSOLUTE)
            verbose_message("Link CXX libs from ${compiler_libdir}")
            set(CMAKE_EXE_LINKER_FLAGS "-L${compiler_libdir}/c++ -L${compiler_libdir} -Wl,-rpath,${compiler_libdir}")
        endif()
    else()
        # Linux and other Unix-like systems
        set(CMAKE_LINK_WHAT_YOU_USE TRUE)
        
        # Non-standard GCC path
        if (CMAKE_CXX_COMPILER_ID STREQUAL GNU)
            get_filename_component(compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
            get_filename_component(compiler_libdir ${compiler_bindir}/../lib ABSOLUTE)
            get_filename_component(compiler_lib64dir ${compiler_bindir}/../lib64 ABSOLUTE)
            verbose_message("Link CXX libs from ${compiler_libdir} ${compiler_lib64dir}")
            set(CMAKE_EXE_LINKER_FLAGS "-L${compiler_libdir} -Wl,-rpath,${compiler_libdir} -Wl,-rpath,${compiler_lib64dir}")
        endif()
    endif()
    
    # Informational messages
    verbose_message("tula build configuration loaded:")
    verbose_message("  CMake version: ${CMAKE_VERSION}")
    verbose_message("  Build type: ${CMAKE_BUILD_TYPE}")
    verbose_message("  C++ standard: ${CMAKE_CXX_STANDARD}")
    verbose_message("  Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
else()
    # project() not called yet - sensible defaults will be applied when this file is included again
    # or the user should call them manually after project()
    verbose_message("tula_cmake: project() not yet called, deferring sensible defaults")
endif()
