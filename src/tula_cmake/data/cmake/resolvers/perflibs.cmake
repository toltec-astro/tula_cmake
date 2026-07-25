include_guard(GLOBAL)

function(_tula_perflibs_validate)
    set(_openmp_modes auto disabled required)
    if(NOT TULA_PERFLIBS_OPENMP IN_LIST _openmp_modes)
        message(FATAL_ERROR
            "perflibs: invalid OpenMP policy ${TULA_PERFLIBS_OPENMP}")
    endif()
    set(_openmp_runtimes auto gnu intel llvm)
    if(NOT TULA_PERFLIBS_OPENMP_RUNTIME IN_LIST _openmp_runtimes)
        message(FATAL_ERROR
            "perflibs: invalid OpenMP runtime ${TULA_PERFLIBS_OPENMP_RUNTIME}")
    endif()
    set(_mkl_threading_modes sequential openmp tbb)
    if(NOT TULA_PERFLIBS_MKL_THREADING IN_LIST _mkl_threading_modes)
        message(FATAL_ERROR
            "perflibs: invalid MKL threading ${TULA_PERFLIBS_MKL_THREADING}")
    endif()
    if(TULA_PERFLIBS_OPENMP_RUNTIME STREQUAL "intel"
       AND NOT TULA_PERFLIBS_ONEAPI STREQUAL "enabled")
        message(FATAL_ERROR
            "perflibs: Intel OpenMP requires perflibs_oneapi=enabled")
    endif()
    if(TULA_PERFLIBS_MKL_THREADING STREQUAL "openmp"
       AND TULA_PERFLIBS_OPENMP STREQUAL "disabled")
        message(FATAL_ERROR
            "perflibs: MKL OpenMP threading requires OpenMP")
    endif()
endfunction()

function(_tula_perflibs_resolve_openmp OUT_TARGET OUT_FOUND)
    if(TULA_PERFLIBS_OPENMP STREQUAL "disabled")
        set("${OUT_TARGET}" "" PARENT_SCOPE)
        set("${OUT_FOUND}" 0 PARENT_SCOPE)
        return()
    endif()

    if(TULA_PERFLIBS_OPENMP STREQUAL "required")
        find_package(OpenMP REQUIRED COMPONENTS CXX)
    else()
        find_package(OpenMP QUIET COMPONENTS CXX)
    endif()
    if(OpenMP_CXX_FOUND)
        set("${OUT_TARGET}" OpenMP::OpenMP_CXX PARENT_SCOPE)
        set("${OUT_FOUND}" 1 PARENT_SCOPE)
    else()
        set("${OUT_TARGET}" "" PARENT_SCOPE)
        set("${OUT_FOUND}" 0 PARENT_SCOPE)
    endif()
endfunction()

function(_tula_perflibs_resolve_mkl OUT_TARGET OUT_FOUND)
    if(NOT TULA_PERFLIBS_ONEAPI STREQUAL "enabled")
        set("${OUT_TARGET}" "" PARENT_SCOPE)
        set("${OUT_FOUND}" 0 PARENT_SCOPE)
        return()
    endif()

    set(MKL_LINK dynamic)
    if(TULA_PERFLIBS_MKL_THREADING STREQUAL "sequential")
        set(MKL_THREADING sequential)
    elseif(TULA_PERFLIBS_MKL_THREADING STREQUAL "tbb")
        set(MKL_THREADING tbb_thread)
    elseif(TULA_PERFLIBS_OPENMP_RUNTIME STREQUAL "gnu")
        set(MKL_THREADING gnu_thread)
    else()
        set(MKL_THREADING intel_thread)
    endif()
    find_package(MKL CONFIG REQUIRED)
    if(NOT TARGET MKL::MKL)
        message(FATAL_ERROR "perflibs: MKL config did not define MKL::MKL")
    endif()
    set("${OUT_TARGET}" MKL::MKL PARENT_SCOPE)
    set("${OUT_FOUND}" 1 PARENT_SCOPE)
endfunction()

function(tula_resolve_perflibs FEATURE MODE)
    if(TARGET tula::perflibs)
        return()
    endif()
    if(NOT MODE STREQUAL "system")
        message(FATAL_ERROR "perflibs: unsupported provider ${MODE}")
    endif()

    _tula_perflibs_validate()
    find_package(Threads REQUIRED)
    _tula_perflibs_resolve_openmp(_openmp_target _has_openmp)
    _tula_perflibs_resolve_mkl(_mkl_target _has_mkl)

    add_library(tula_perflibs INTERFACE)
    target_link_libraries(tula_perflibs INTERFACE Threads::Threads)
    if(_openmp_target)
        target_link_libraries(tula_perflibs INTERFACE "${_openmp_target}")
    endif()
    if(_mkl_target)
        target_link_libraries(tula_perflibs INTERFACE "${_mkl_target}")
    endif()
    target_compile_definitions(
        tula_perflibs
        INTERFACE
            "TULA_PERFLIBS_HAS_THREADS=1"
            "TULA_PERFLIBS_HAS_OPENMP=${_has_openmp}"
            "TULA_PERFLIBS_HAS_MKL=${_has_mkl}"
            "TULA_PERFLIBS_OPENMP_RUNTIME=\"${TULA_PERFLIBS_OPENMP_RUNTIME}\""
            "TULA_PERFLIBS_MKL_THREADING=\"${TULA_PERFLIBS_MKL_THREADING}\""
    )
    add_library(tula::perflibs ALIAS tula_perflibs)
endfunction()
