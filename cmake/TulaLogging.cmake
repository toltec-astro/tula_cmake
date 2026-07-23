include_guard(GLOBAL)

function(_tula_load_cpm)
    if(COMMAND CPMAddPackage)
        return()
    endif()
    set(_cpm_version "0.42.0")
    set(_cpm_hash "2020b4fc42dba44817983e06342e682ecfc3d2f484a581f11cc5731fbe4dce8a")
    set(_cpm_file "${CMAKE_BINARY_DIR}/_tula/CPM_${_cpm_version}.cmake")
    if(NOT EXISTS "${_cpm_file}")
        file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/_tula")
        file(DOWNLOAD
            "https://github.com/cpm-cmake/CPM.cmake/releases/download/v${_cpm_version}/CPM.cmake"
            "${_cpm_file}"
            EXPECTED_HASH "SHA256=${_cpm_hash}"
            TLS_VERIFY ON
            STATUS _download_status
        )
        list(GET _download_status 0 _download_code)
        if(NOT _download_code EQUAL 0)
            list(GET _download_status 1 _download_message)
            message(FATAL_ERROR "Unable to download CPM.cmake: ${_download_message}")
        endif()
    endif()
    if(NOT CPM_SOURCE_CACHE AND DEFINED ENV{CPM_SOURCE_CACHE})
        set(CPM_SOURCE_CACHE "$ENV{CPM_SOURCE_CACHE}" CACHE PATH "CPM source cache")
    endif()
    include("${_cpm_file}")
endfunction()

function(_tula_logging_cpm)
    _tula_load_cpm()
    CPMAddPackage(
        NAME fmt
        URL "${TULA_FEATURE_logging_FMT_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_logging_FMT_SHA256}"
        OPTIONS "FMT_TEST OFF" "FMT_DOC OFF" "FMT_INSTALL OFF"
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

function(tula_resolve_logging MODE)
    if(TARGET tula::logging)
        return()
    endif()
    if(MODE STREQUAL "conan" OR MODE STREQUAL "system")
        _tula_logging_installed()
    elseif(MODE STREQUAL "cpm")
        _tula_logging_cpm()
    else()
        message(FATAL_ERROR "logging: unsupported provider ${MODE}")
    endif()

    if(TARGET spdlog::spdlog)
        set(_spdlog_target spdlog::spdlog)
    elseif(TARGET spdlog::spdlog_header_only)
        set(_spdlog_target spdlog::spdlog_header_only)
    else()
        message(FATAL_ERROR "logging: spdlog provider target is unavailable")
    endif()
    if(NOT TARGET fmt::fmt)
        message(FATAL_ERROR "logging: fmt::fmt provider target is unavailable")
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
    target_link_libraries(tula_logging INTERFACE "${_spdlog_target}" fmt::fmt)
    target_compile_definitions(
        tula_logging
        INTERFACE "SPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_${_level}"
    )
    add_library(tula::logging ALIAS tula_logging)
endfunction()
