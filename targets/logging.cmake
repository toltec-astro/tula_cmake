# logging.cmake - Logging metapackage (spdlog + fmt)
# Adapted for v3 Conan-centric architecture with stateless functions

include_guard(GLOBAL)

# Include utilities
include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Main setup function for logging metapackage (stateless, mode as parameter)

This is the entry point called by tula_deps_add().
Mode is passed as parameter (not global variable).

@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_logging MODE)
    verbose_message("Setting up tula::logging metapackage (mode=${MODE})")
    
    # Idempotency check
    if(TARGET tula::logging)
        verbose_message("tula::logging already exists, skipping")
        return()
    endif()
    
    # Configure log level
    set(default_loglevel "Trace")
    if(CMAKE_BUILD_TYPE MATCHES "^(Release|MinSizeRel)$")
        set(default_loglevel "Debug")
    endif()
    
    set(LOGLEVEL "${default_loglevel}" CACHE STRING "Minimum log level to enable at compile-time")
    set_property(CACHE LOGLEVEL PROPERTY STRINGS "Trace" "Debug" "Info" "Warning" "Error")
    
    verbose_message("Log level: ${LOGLEVEL}")
    
    # Mode-driven resolution
    if(MODE MATCHES "CONAN|AUTO")
        _tula_logging_try_conan()
    elseif(MODE STREQUAL "CPM")
        _tula_logging_try_cpm()
    elseif(MODE STREQUAL "SYSTEM")
        _tula_logging_try_system()
    else()
        message(FATAL_ERROR "Unknown logging mode: ${MODE}")
    endif()
    
    # Create metapackage wrapper
    _tula_logging_create_wrapper()
    
    verbose_message("tula::logging ready")
endfunction()

#[=======================================================================[
@brief Try to find spdlog and fmt via Conan
]=======================================================================]
function(_tula_logging_try_conan)
    # Try spdlog first (may bring fmt transitively)
    find_package(spdlog QUIET CONFIG)
    if(NOT TARGET spdlog::spdlog AND NOT TARGET spdlog)
        message(FATAL_ERROR "spdlog not found via Conan CONFIG. Ensure it's in Conan requirements.")
    endif()
    
    # Try fmt (should be available transitively from spdlog, or separately)
    find_package(fmt QUIET CONFIG)
    if(NOT TARGET fmt::fmt AND NOT TARGET fmt)
        message(WARNING "fmt not found via Conan CONFIG, but spdlog may provide it transitively")
    endif()
    
    verbose_message("Found spdlog and fmt via Conan")
endfunction()

#[=======================================================================[
@brief Fetch spdlog and fmt via CPM
]=======================================================================]
function(_tula_logging_try_cpm)
    if(NOT DEFINED LOGGING_SPDLOG_GITHUB_REPO)
        message(FATAL_ERROR "LOGGING_SPDLOG_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    # Fetch fmt first (spdlog dependency)
    if(NOT TARGET fmt::fmt AND NOT TARGET fmt)
        CPMAddPackage(
            NAME fmt
            GITHUB_REPOSITORY "fmtlib/fmt"
            GIT_TAG "master"
            OPTIONS
                "FMT_TEST OFF"
                "FMT_DOC OFF"
                "FMT_INSTALL ON"
        )
    endif()
    
    # Fetch spdlog
    CPMAddPackage(
        NAME spdlog
        GITHUB_REPOSITORY "${LOGGING_SPDLOG_GITHUB_REPO}"
        GIT_TAG "${LOGGING_SPDLOG_GIT_TAG}"
        OPTIONS ${LOGGING_SPDLOG_OPTIONS}
    )
    
    verbose_message("Fetched spdlog and fmt via CPM")
endfunction()

#[=======================================================================[
@brief Find spdlog and fmt via system
]=======================================================================]
function(_tula_logging_try_system)
    find_package(fmt REQUIRED CONFIG)
    find_package(spdlog REQUIRED CONFIG)
    
    verbose_message("Found spdlog and fmt via system")
endfunction()

#[=======================================================================[
@brief Create tula::logging metapackage wrapper
]=======================================================================]
function(_tula_logging_create_wrapper)
    if(TARGET tula_logging)
        return()  # Already created
    endif()
    
    set(_logging_libs "")
    
    # Add spdlog (check both possible target names)
    if(TARGET spdlog::spdlog)
        list(APPEND _logging_libs spdlog::spdlog)
        verbose_message("Using spdlog::spdlog")
    elseif(TARGET spdlog)
        list(APPEND _logging_libs spdlog)
        verbose_message("Using spdlog")
    else()
        message(FATAL_ERROR "spdlog target not found. Cannot create logging metapackage.")
    endif()
    
    # Add fmt (check both possible target names)
    if(TARGET fmt::fmt)
        list(APPEND _logging_libs fmt::fmt)
        verbose_message("Using fmt::fmt")
    elseif(TARGET fmt)
        list(APPEND _logging_libs fmt)
        verbose_message("Using fmt")
    else()
        # fmt might be provided transitively by spdlog, so just warn
        message(WARNING "fmt target not found, but may be available transitively from spdlog")
    endif()
    
    # Create metapackage wrapper
    make_tula_target(logging ${_logging_libs})
    
    # Add log level compile definition
    target_compile_definitions(tula_logging INTERFACE LOGLEVEL=${LOGLEVEL})
    
    verbose_message("Created tula::logging metapackage with LOGLEVEL=${LOGLEVEL}")
endfunction()

