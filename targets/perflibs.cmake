# perflibs.cmake - Performance libraries metapackage (OpenMP + Threads)
#
# Defines: tula_perflibs_add_system()
# Called by: tula_deps_add(deps perflibs) from tula_deps.cmake
# Note: SYSTEM only - OpenMP and Threads are CMake built-in modules

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)

#[=======================================================================[
@brief Load OpenMP and Threads via system (CMake built-in modules)
Note: All modes (conan, cpm, auto) fall back to system for perflibs
]=======================================================================]
function(tula_perflibs_add_system)
    # FindOpenMP and FindThreads require C/CXX to be enabled.
    # During the CMake toolchain phase (before project() enables languages),
    # these find modules will error. Create an empty wrapper and return.
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        verbose_message("Toolchain phase: skipping FindOpenMP/FindThreads (languages not yet loaded)")
        _tula_perflibs_create_wrapper()
        return()
    endif()

    # Find OpenMP (optional)
    find_package(OpenMP QUIET)
    if(OpenMP_FOUND)
        verbose_message("Found OpenMP")
    else()
        verbose_message("OpenMP not found (optional)")
    endif()

    # Find Threads
    find_package(Threads QUIET)
    if(Threads_FOUND)
        verbose_message("Found Threads")
    else()
        verbose_message("Threads not found (optional)")
    endif()

    _tula_perflibs_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::perflibs metapackage wrapper
]=======================================================================]
function(_tula_perflibs_create_wrapper)
    if(TARGET tula_perflibs)
        return()
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
    
    make_tula_target(perflibs ${_perflibs})
    
    # Add compile definitions to indicate availability
    target_compile_definitions(tula_perflibs INTERFACE
        HAS_OPENMP=${has_openmp}
        HAS_THREADS=${has_threads}
    )
    
    verbose_message("Created tula::perflibs metapackage (OpenMP=${has_openmp}, Threads=${has_threads})")
endfunction()
