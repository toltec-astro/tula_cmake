include_guard(GLOBAL)

include(TulaCPM)

function(_tula_logging_cpm)
    tula_load_cpm()
    CPMAddPackage(
        NAME fmt
        URL "${TULA_FEATURE_logging_FMT_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_logging_FMT_SHA256}"
        OPTIONS
            "FMT_TEST OFF"
            "FMT_DOC OFF"
            "FMT_INSTALL OFF"
    )
    CPMAddPackage(
        NAME spdlog
        URL "${TULA_FEATURE_logging_SPDLOG_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_logging_SPDLOG_SHA256}"
        OPTIONS
            "SPDLOG_BUILD_TESTS OFF"
            "SPDLOG_BUILD_EXAMPLE OFF"
            "SPDLOG_BUILD_BENCH OFF"
            "SPDLOG_FMT_EXTERNAL ON"
            "SPDLOG_INSTALL OFF"
    )
endfunction()

function(_tula_logging_installed)
    find_package(fmt CONFIG REQUIRED)
    find_package(spdlog CONFIG REQUIRED)
endfunction()

function(_tula_logging_finalize)
    if(TARGET tula::logging)
        return()
    endif()

    if(TARGET spdlog::spdlog)
        set(_spdlog_target spdlog::spdlog)
    elseif(TARGET spdlog::spdlog_header_only)
        set(_spdlog_target spdlog::spdlog_header_only)
    else()
        message(FATAL_ERROR "logging: spdlog provider target is unavailable")
    endif()
    if(TARGET fmt::fmt-header-only)
        set(_fmt_target fmt::fmt-header-only)
    elseif(TARGET fmt::fmt)
        set(_fmt_target fmt::fmt)
    else()
        message(FATAL_ERROR "logging: fmt provider target is unavailable")
    endif()
    string(TOUPPER "${TULA_LOGGING_LEVEL}" _level)
    if(_level STREQUAL "WARNING")
        set(_level "WARN")
    endif()
    set(_valid_levels TRACE DEBUG INFO WARN ERROR CRITICAL OFF)
    if(NOT _level IN_LIST _valid_levels)
        message(FATAL_ERROR "logging: invalid level ${TULA_LOGGING_LEVEL}")
    endif()

    add_library(tula_logging INTERFACE)
    target_link_libraries(
        tula_logging
        INTERFACE "${_spdlog_target}" "${_fmt_target}"
    )
    target_compile_definitions(
        tula_logging
        INTERFACE "SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_${_level}"
    )
    add_library(tula::logging ALIAS tula_logging)
endfunction()

function(tula_resolve_logging_conan)
    _tula_logging_installed()
    _tula_logging_finalize()
endfunction()

function(tula_resolve_logging_cpm)
    _tula_logging_cpm()
    _tula_logging_finalize()
endfunction()

function(tula_resolve_logging_system)
    _tula_logging_installed()
    _tula_logging_finalize()
endfunction()
