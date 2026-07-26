include_guard(GLOBAL)

include(TulaCPM)

function(tula_resolve_meta_enum_cpm)
    if(TARGET tula::meta_enum)
        return()
    endif()

    tula_load_cpm()
    CPMAddPackage(
        NAME meta_enum
        URL "${TULA_FEATURE_meta_enum_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_meta_enum_SHA256}"
        DOWNLOAD_ONLY YES
    )
    if(NOT meta_enum_SOURCE_DIR)
        message(FATAL_ERROR "meta_enum: CPM did not provide a source directory")
    endif()
    tula_register_bundled_headers(meta_enum "${meta_enum_SOURCE_DIR}")

    add_library(tula_meta_enum INTERFACE)
    target_include_directories(
        tula_meta_enum
        INTERFACE "${meta_enum_SOURCE_DIR}/include"
    )
    add_library(tula::meta_enum ALIAS tula_meta_enum)
endfunction()
