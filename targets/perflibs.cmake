# perflibs.cmake - Performance libraries metapackage (OpenMP + Threads)

include_guard(GLOBAL)

# Include utilities
include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)

#[=======================================================================[
@brief Main setup function for perflibs metapackage (stateless, mode as parameter)

This is the entry point called by tula_deps_add().
Mode is passed as parameter (not global variable).

perflibs provides centralized access to performance libraries:
- OpenMP (optional, for parallel loops)
- Threads (required for most parallel libraries)

Default mode is SYSTEM since these are typically system-provided.

@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_perflibs MODE)
    verbose_message("Setting up tula::perflibs metapackage (mode=${MODE})")
    
    # Idempotency check
    if(TARGET tula::perflibs)
        verbose_message("tula::perflibs already exists, skipping")
        return()
    endif()
    
    # perflibs is SYSTEM-only (OpenMP and Threads are CMake built-in)
    # CONAN, CPM, and AUTO all fall back to SYSTEM
    if(MODE MATCHES "CONAN|CPM|AUTO|SYSTEM")
        _tula_perflibs_try_system()
    else()
        message(FATAL_ERROR "Unknown perflibs mode: ${MODE}")
    endif()
    
    # Create metapackage wrapper
    _tula_perflibs_create_wrapper()
    
    verbose_message("tula::perflibs ready")
endfunction()

#[=======================================================================[
@brief Find OpenMP and Threads via system (CMake built-in modules)
]=======================================================================]
function(_tula_perflibs_try_system)
    # Find OpenMP (optional)
    find_package(OpenMP QUIET)
    if(OpenMP_FOUND)
        verbose_message("Found OpenMP")
    else()
        verbose_message("OpenMP not found (optional)")
    endif()
    
    # Find Threads (required for most parallel libraries)
    find_package(Threads QUIET)
    if(Threads_FOUND)
        verbose_message("Found Threads")
    else()
        verbose_message("Threads not found (optional)")
    endif()
endfunction()

#[=======================================================================[
@brief Create tula::perflibs metapackage wrapper
]=======================================================================]
function(_tula_perflibs_create_wrapper)
    if(TARGET tula_perflibs)
        return()  # Already created
    endif()
    
    set(_perflibs "")
    
    # Add OpenMP if available
    if(TARGET OpenMP::OpenMP_CXX)
        list(APPEND _perflibs OpenMP::OpenMP_CXX)
        verbose_message("Using OpenMP::OpenMP_CXX")
        set(has_openmp 1)
    else()
        verbose_message("OpenMP not available")
        set(has_openmp 0)
    endif()
    
    # Add Threads if available
    if(TARGET Threads::Threads)
        list(APPEND _perflibs Threads::Threads)
        verbose_message("Using Threads::Threads")
        set(has_threads 1)
    else()
        verbose_message("Threads not available")
        set(has_threads 0)
    endif()
    
    # Create metapackage wrapper (even if empty, for consistency)
    make_tula_target(perflibs ${_perflibs})
    
    # Add compile definitions to indicate availability
    target_compile_definitions(tula_perflibs INTERFACE
        HAS_OPENMP=${has_openmp}
        HAS_THREADS=${has_threads}
    )
    
    verbose_message("Created tula::perflibs metapackage (OpenMP=${has_openmp}, Threads=${has_threads})")
endfunction()
