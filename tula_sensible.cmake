# tula_sensible.cmake - Sensible defaults for tula projects
#
# This file is automatically included by the Conan toolchain.
# It provides sensible defaults that complement (not override) Conan settings.
#
# Checks performed:
#   - CMake minimum version (4.1+)
#   - Project name is set (deferred until after project())
#   - Language includes CXX (deferred)
#   - Build-in-source guard (deferred)
#   - Build type detection (deferred)

include_guard(GLOBAL)

# ============================================================================
# Pre-Project Checks (before project() call)
# ============================================================================

# Internal minimum CMake version requirement
set(TULA_CMAKE_MINIMUM_VERSION "4.1")

# Check CMake version meets tula requirements
if(CMAKE_VERSION VERSION_LESS ${TULA_CMAKE_MINIMUM_VERSION})
    message(FATAL_ERROR 
        "tula requires CMake ${TULA_CMAKE_MINIMUM_VERSION} or higher, "
        "but you are using CMake ${CMAKE_VERSION}. "
        "Please upgrade CMake.")
endif()

# ============================================================================
# Post-Project Setup (deferred until after project() call)
# ============================================================================

# Define a macro that will run checks and setup after project()
macro(_tula_post_project_checks)
    # Only run once
    if(NOT DEFINED _TULA_POST_PROJECT_DONE)
        set(_TULA_POST_PROJECT_DONE TRUE)
        
        # Check cmake_minimum_required was called with acceptable version
        if(CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS ${TULA_CMAKE_MINIMUM_VERSION})
            message(FATAL_ERROR 
                "tula requires CMake ${TULA_CMAKE_MINIMUM_VERSION} or higher, "
                "but cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION}) was specified. "
                "Please update cmake_minimum_required(VERSION ...) to at least ${TULA_CMAKE_MINIMUM_VERSION}")
        endif()
        
        # Check project name is set
        if(NOT PROJECT_NAME)
            message(FATAL_ERROR "PROJECT_NAME not set. Did you call project()?")
        endif()
        
        # Check language includes CXX
        get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
        if(NOT "CXX" IN_LIST languages)
            message(FATAL_ERROR 
                "tula requires C++ language. "
                "Please use: project(${PROJECT_NAME} LANGUAGES CXX)")
        endif()
        
        # Build-in-source guard
        file(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}/CMakeLists.txt" _tula_loc_path)
        if(EXISTS "${_tula_loc_path}")
            message(FATAL_ERROR 
                "You cannot build in a source directory (or any directory with a CMakeLists.txt file). "
                "Please make a build subdirectory. Feel free to remove CMakeCache.txt and CMakeFiles.")
        endif()
        unset(_tula_loc_path)
    
    # Detect and validate build type using utility
    include(detect_build_type)
    
    # Sensible defaults that don't conflict with Conan
        # (Conan already sets: CMAKE_CXX_STANDARD, CMAKE_CXX_EXTENSIONS, CMAKE_CXX_STANDARD_REQUIRED)
        
        if(NOT DEFINED CMAKE_POSITION_INDEPENDENT_CODE)
            set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL "Build position independent code")
        endif()
        
        if(NOT DEFINED CMAKE_EXPORT_COMPILE_COMMANDS)
            set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Generate compile_commands.json")
        endif()
        
        # RPATH configuration (if not already set)
        if(NOT DEFINED CMAKE_SKIP_BUILD_RPATH)
            set(CMAKE_SKIP_BUILD_RPATH FALSE)
        endif()
        if(NOT DEFINED CMAKE_BUILD_WITH_INSTALL_RPATH)
            set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
        endif()
        if(NOT DEFINED CMAKE_BUILD_RPATH_USE_ORIGIN)
            set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
        endif()
        if(NOT DEFINED CMAKE_INSTALL_RPATH_USE_LINK_PATH)
            set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
        endif()
        
        # Output directories (if not already set)
        if(NOT DEFINED CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
            set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
        endif()
        if(NOT DEFINED CMAKE_LIBRARY_OUTPUT_DIRECTORY)
            set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
        endif()
        if(NOT DEFINED CMAKE_RUNTIME_OUTPUT_DIRECTORY)
            set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
        endif()
        
        # Platform-specific settings
        if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
            # macOS
            set(CMAKE_MACOSX_RPATH TRUE)
            
            # Homebrew LLVM support (if using Clang from Homebrew)
            if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
                get_filename_component(_tula_compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
                get_filename_component(_tula_compiler_libdir ${_tula_compiler_bindir}/../lib ABSOLUTE)
                
                # Only add if it's a Homebrew LLVM installation
                if(_tula_compiler_libdir MATCHES "/opt/homebrew" OR _tula_compiler_libdir MATCHES "/usr/local")
                    message(STATUS "(tula) Detected Homebrew LLVM, adding rpath: ${_tula_compiler_libdir}")
                    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${_tula_compiler_libdir}/c++ -L${_tula_compiler_libdir} -Wl,-rpath,${_tula_compiler_libdir}")
                endif()
                
                unset(_tula_compiler_bindir)
                unset(_tula_compiler_libdir)
            endif()
        else()
            # Linux and Unix-like systems
            if(NOT DEFINED CMAKE_LINK_WHAT_YOU_USE)
                set(CMAKE_LINK_WHAT_YOU_USE TRUE)
            endif()
            
            # Non-standard GCC paths
            if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
                get_filename_component(_tula_compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
                get_filename_component(_tula_compiler_libdir ${_tula_compiler_bindir}/../lib ABSOLUTE)
                get_filename_component(_tula_compiler_lib64dir ${_tula_compiler_bindir}/../lib64 ABSOLUTE)
                
                if(EXISTS ${_tula_compiler_libdir} OR EXISTS ${_tula_compiler_lib64dir})
                    message(STATUS "(tula) Adding GCC library paths: ${_tula_compiler_libdir} ${_tula_compiler_lib64dir}")
                    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${_tula_compiler_libdir} -Wl,-rpath,${_tula_compiler_libdir} -Wl,-rpath,${_tula_compiler_lib64dir}")
                endif()
                
                unset(_tula_compiler_bindir)
                unset(_tula_compiler_libdir)
                unset(_tula_compiler_lib64dir)
            endif()
        endif()
        
        # Report configuration
        message(STATUS "(tula) Configuration loaded:")
        message(STATUS "(tula)   CMake version: ${CMAKE_VERSION}")
        message(STATUS "(tula)   Project: ${PROJECT_NAME}")
        message(STATUS "(tula)   Build type: ${CMAKE_BUILD_TYPE}")
        message(STATUS "(tula)   C++ standard: ${CMAKE_CXX_STANDARD}")
        message(STATUS "(tula)   Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
        message(STATUS "(tula)   System: ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}")
    endif()
endmacro()

# Hook into project() command via variable_watch on PROJECT_NAME
# This ensures our checks run after project() is called
variable_watch(PROJECT_NAME _tula_project_name_watcher)

function(_tula_project_name_watcher variable access value current_list_file stack)
    if(access STREQUAL "MODIFIED_ACCESS" AND value)
        # Only run checks for top-level project, not sub-projects
        if(CMAKE_PROJECT_NAME STREQUAL value OR NOT DEFINED CMAKE_PROJECT_NAME)
            # PROJECT_NAME was just set by project() command
            _tula_post_project_checks()
        endif()
        # Unwatch to avoid multiple calls
        variable_watch(PROJECT_NAME)
    endif()
endfunction()
