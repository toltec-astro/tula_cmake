include_guard(GLOBAL)

include(TulaCPM)

function(tula_resolve_bitmask_cpm)
    if(TARGET tula::bitmask)
        return()
    endif()

    tula_load_cpm()
    CPMAddPackage(
        NAME bitmask
        URL "${TULA_FEATURE_bitmask_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_bitmask_SHA256}"
        DOWNLOAD_ONLY YES
    )
    if(NOT bitmask_SOURCE_DIR)
        message(FATAL_ERROR "bitmask: CPM did not provide a source directory")
    endif()
    tula_register_bundled_headers(bitmask "${bitmask_SOURCE_DIR}")

    add_library(tula_bitmask INTERFACE)
    target_include_directories(
        tula_bitmask
        INTERFACE "${bitmask_SOURCE_DIR}/include"
    )
    add_library(tula::bitmask ALIAS tula_bitmask)
endfunction()
