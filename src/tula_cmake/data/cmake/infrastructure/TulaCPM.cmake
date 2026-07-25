include_guard(GLOBAL)

function(tula_load_cpm)
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
