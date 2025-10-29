# Logging Package Module for tula v2 (spdlog + fmt)
# Single-include workflow with callback-based target creation
#
# Creates target: tula::logging

include_guard(GLOBAL)
include(verbose_message)
include(make_tula_target)

# Skip if target already exists
if(TARGET tula_logging)
    message(STATUS "(logging) Target tula_logging already exists, skipping")
    return()
endif()

# Determine default log level based on build type
set(default_loglevel "Trace")
if (CMAKE_BUILD_TYPE MATCHES "^(Release|MinSizeRel)$")
    set(default_loglevel "Debug")
endif()

set(LOGLEVEL "${default_loglevel}" CACHE STRING "Choose the minimum log level to enable.")
set_property(CACHE LOGLEVEL PROPERTY STRINGS "Trace" "Debug" "Info" "Warning" "Error")

verbose_message("Minimum log level enabled at compile-time: ${LOGLEVEL}")

#[=======================================================================[
@brief Create spdlog::spdlog target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_spdlog_create_conan_target)
    if(TARGET spdlog::spdlog)
        return()  # Already created
    endif()
    
    # Conan provides include path via CMAKE_INCLUDE_PATH
    set(SPDLOG_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "spdlog")
            set(SPDLOG_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT SPDLOG_INCLUDE_DIR)
        message(STATUS "  ✗ spdlog not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target
    add_library(spdlog::spdlog INTERFACE IMPORTED GLOBAL)
    target_include_directories(spdlog::spdlog INTERFACE "${SPDLOG_INCLUDE_DIR}")
    message(STATUS "  ✓ Created spdlog::spdlog target from Conan: ${SPDLOG_INCLUDE_DIR}")
endfunction()

# Find fmt first (spdlog depends on it)
include(fmt)

# Register spdlog with callback for CONAN mode
tula_deps_register(spdlog
    CONAN_NAME spdlog
    CONAN_TARGET_CALLBACK _tula_spdlog_create_conan_target
    CONAN_TARGET_NAME spdlog::spdlog
    CPM_GITHUB_REPOSITORY gabime/spdlog
    CPM_GIT_TAG v1.x
    CPM_OPTIONS "SPDLOG_FMT_EXTERNAL ON" "SPDLOG_INSTALL ON"
    SYSTEM_NAME spdlog
    FIND_PACKAGE_ARGS CONFIG
)

# Note: Targets are created by tula_deps_create_targets() in CMakeLists.txt
# We defer target validation and wrapper creation until that phase completes

# Wrapper function to create tula::logging after dependencies are resolved
function(_tula_logging_create_wrapper)
    # Check if this function has already been called
    if(TARGET tula_logging)
        return()
    endif()
    
    set(_logging_libs "")

    # Add spdlog
    if(TARGET spdlog::spdlog)
        list(APPEND _logging_libs spdlog::spdlog)
        verbose_message("spdlog configured")
    elseif(TARGET spdlog)
        list(APPEND _logging_libs spdlog)
        verbose_message("spdlog configured")
    else()
        message(FATAL_ERROR "spdlog target not found after dependency resolution")
    endif()

    # Add fmt
    if(TARGET fmt::fmt)
        list(APPEND _logging_libs fmt::fmt)
        verbose_message("fmt configured")
    elseif(TARGET fmt)
        list(APPEND _logging_libs fmt)
        verbose_message("fmt configured")
    else()
        message(FATAL_ERROR "fmt target not found after dependency resolution")
    endif()

    # Create the tula wrapper target
    make_tula_target(logging ${_logging_libs})
    target_compile_definitions(tula_logging INTERFACE LOGLEVEL=${LOGLEVEL})

    verbose_message("Logging configured: tula::logging with LOGLEVEL=${LOGLEVEL}")
endfunction()

# If dependencies have already been created, create wrapper now
# Otherwise, defer to after tula_deps_create_targets()
if(TARGET fmt::fmt OR TARGET fmt)
    _tula_logging_create_wrapper()
endif()
