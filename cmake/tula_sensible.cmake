# tula_sensible - Sensible build defaults and utilities
#
# Public-facing file for projects that want tula's build configuration
# without dependency management. Can be used standalone.
#
# Provides:
#   - CMake version check (4.1+)
#   - Module path setup for utils/
#   - Build type detection
#   - Sensible defaults (C++23, RPATH, output dirs, etc.)
#   - Platform-specific compiler settings
#
# REQUIREMENT: Must be included AFTER project() call
#
# Usage:
#   project(MyProject LANGUAGES CXX)
#   include(tula_sensible)

include_guard(GLOBAL)

# ============================================================================
# Module Path and Version Check
# ============================================================================

set(CMAKE_MODULE_PATH 
    "${CMAKE_CURRENT_LIST_DIR}/utils"
    ${CMAKE_MODULE_PATH}
)

include(check_cmake_version)
check_cmake_version("4.1" MODULE_NAME "tula_sensible")

include(verbose_message)

# ============================================================================
# Sensible Build Defaults
# ============================================================================
# REQUIREMENT: This file must be included AFTER project() call

if(NOT PROJECT_NAME)
    message(FATAL_ERROR "tula_sensible must be included AFTER project() call")
endif()

# Build-in-source guard
file(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}/CMakeLists.txt" LOC_PATH)
if(EXISTS "${LOC_PATH}")
    message(FATAL_ERROR "You cannot build in a source directory (or any directory with a CMakeLists.txt file). Please make a build subdirectory. Feel free to remove CMakeCache.txt and CMakeFiles.")
endif()
    
    # Detect build type if not specified
    include(detect_build_type)
    
    # General settings
    set_property(GLOBAL PROPERTY ALLOW_DUPLICATE_CUSTOM_TARGETS TRUE)
    set(CMAKE_FIND_REQUIRED OFF)
    
    # RPATH configuration
    set(CMAKE_SKIP_BUILD_RPATH FALSE)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
    set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    
    # Output directories
    include(GNUInstallDirs)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    
    # Language settings
    enable_language(CXX)
    enable_language(C)
    
    # C++23 with no extensions
    set(CMAKE_CXX_STANDARD 23 CACHE STRING "C++ standard to use")
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    
    # Platform-specific settings
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        # macOS
        set(CMAKE_MACOSX_RPATH TRUE)
        
        # Homebrew LLVM support
        if(CMAKE_CXX_COMPILER_ID STREQUAL Clang)
            get_filename_component(compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
            get_filename_component(compiler_libdir ${compiler_bindir}/../lib ABSOLUTE)
            verbose_message("(tula_sensible) Link CXX libs from ${compiler_libdir}")
            set(CMAKE_EXE_LINKER_FLAGS "-L${compiler_libdir}/c++ -L${compiler_libdir} -Wl,-rpath,${compiler_libdir}")
        endif()
    else()
        # Linux and Unix-like systems
        set(CMAKE_LINK_WHAT_YOU_USE TRUE)
        
        # Non-standard GCC paths
        if(CMAKE_CXX_COMPILER_ID STREQUAL GNU)
            get_filename_component(compiler_bindir ${CMAKE_CXX_COMPILER} DIRECTORY)
            get_filename_component(compiler_libdir ${compiler_bindir}/../lib ABSOLUTE)
            get_filename_component(compiler_lib64dir ${compiler_bindir}/../lib64 ABSOLUTE)
            verbose_message("(tula_sensible) Link CXX libs from ${compiler_libdir} ${compiler_lib64dir}")
            set(CMAKE_EXE_LINKER_FLAGS "-L${compiler_libdir} -Wl,-rpath,${compiler_libdir} -Wl,-rpath,${compiler_lib64dir}")
        endif()
    endif()
    
    verbose_message("(tula_sensible) tula build configuration loaded:")
    verbose_message("(tula_sensible)   CMake version: ${CMAKE_VERSION}")
    verbose_message("(tula_sensible)   Build type: ${CMAKE_BUILD_TYPE}")
    verbose_message("(tula_sensible)   C++ standard: ${CMAKE_CXX_STANDARD}")
    verbose_message("(tula_sensible)   Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")

