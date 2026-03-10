# logging.cmake - Logging metapackage (spdlog + fmt)
#
# Defines: tula_logging_add_conan(), tula_logging_add_cpm(), tula_logging_add_system()
# Called by: tula_deps_add(deps logging) from tula_deps.cmake

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Load spdlog and fmt from Conan
]=======================================================================]
function(tula_logging_add_conan)
    # Configure log level
    _tula_logging_configure_loglevel()
    
    # Try spdlog first (may bring fmt transitively)
    find_package(spdlog QUIET CONFIG)
    if(NOT TARGET spdlog::spdlog AND NOT TARGET spdlog)
        return()
    endif()
    
    # Try fmt (should be available transitively from spdlog, or separately)
    find_package(fmt QUIET CONFIG)
    if(NOT TARGET fmt::fmt AND NOT TARGET fmt)
        message(WARNING "fmt not found via Conan CONFIG, but spdlog may provide it transitively")
    endif()
    
    verbose_message("Found spdlog and fmt via Conan")
    _tula_logging_create_wrapper()
endfunction()

#[=======================================================================[
@brief Fetch spdlog and fmt via CPM
]=======================================================================]
function(tula_logging_add_cpm)
    # Configure log level
    _tula_logging_configure_loglevel()

    if(NOT DEFINED TULA_LOGGING_SPDLOG_GITHUB_REPO)
        return()
    endif()

    # CPM requires CXX language (compiles spdlog/fmt). Defer to post-project().
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        message(STATUS "    Toolchain phase: deferring logging CPM to post-project() phase")
        return()
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
        GITHUB_REPOSITORY "${TULA_LOGGING_SPDLOG_GITHUB_REPO}"
        GIT_TAG "${TULA_LOGGING_SPDLOG_GIT_TAG}"
        OPTIONS ${TULA_LOGGING_SPDLOG_OPTIONS}
    )
    
    if(NOT TARGET spdlog::spdlog AND NOT TARGET spdlog)
        return()
    endif()
    
    verbose_message("Fetched spdlog and fmt via CPM")
    _tula_logging_create_wrapper()
endfunction()

#[=======================================================================[
@brief Find spdlog and fmt via system
]=======================================================================]
function(tula_logging_add_system)
    # Configure log level
    _tula_logging_configure_loglevel()

    # spdlogConfig.cmake calls find_package(Threads) which requires CXX language.
    # Skip entirely during toolchain phase; tula_deps.cmake will defer and retry.
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        message(STATUS "    Toolchain phase: deferring logging system to post-project() phase")
        return()
    endif()

    find_package(fmt QUIET CONFIG)
    find_package(spdlog QUIET CONFIG)

    if(NOT TARGET fmt::fmt AND NOT TARGET fmt)
        message(STATUS "    fmt not found via system CONFIG")
        return()
    endif()
    if(NOT TARGET spdlog::spdlog AND NOT TARGET spdlog)
        message(STATUS "    spdlog not found via system CONFIG")
        return()
    endif()

    verbose_message("Found spdlog and fmt via system")
    _tula_logging_create_wrapper()
endfunction()

#[=======================================================================[
@brief Configure log level cache variable
]=======================================================================]
function(_tula_logging_configure_loglevel)
    set(default_loglevel "Trace")
    if(CMAKE_BUILD_TYPE MATCHES "^(Release|MinSizeRel)$")
        set(default_loglevel "Debug")
    endif()
    
    set(LOGLEVEL "${default_loglevel}" CACHE STRING "Minimum log level to enable at compile-time")
    set_property(CACHE LOGLEVEL PROPERTY STRINGS "Trace" "Debug" "Info" "Warning" "Error")
    
    verbose_message("Log level: ${LOGLEVEL}")
endfunction()

#[=======================================================================[
@brief Create tula::logging metapackage wrapper
]=======================================================================]
function(_tula_logging_create_wrapper)
    if(TARGET tula_logging)
        return()
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
        message(WARNING "fmt target not found, but may be available transitively from spdlog")
    endif()
    
    make_tula_target(logging ${_logging_libs})
    
    # Add log level compile definition
    target_compile_definitions(tula_logging INTERFACE LOGLEVEL=${LOGLEVEL})
    
    verbose_message("Created tula::logging metapackage with LOGLEVEL=${LOGLEVEL}")
endfunction()

