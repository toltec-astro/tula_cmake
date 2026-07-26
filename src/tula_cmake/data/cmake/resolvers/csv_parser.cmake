include_guard(GLOBAL)

include(TulaCPM)

function(tula_resolve_csv_parser_cpm)
    if(TARGET tula::csv_parser)
        return()
    endif()

    tula_load_cpm()
    CPMAddPackage(
        NAME csv_parser
        URL "${TULA_FEATURE_csv_parser_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_csv_parser_SHA256}"
        DOWNLOAD_ONLY YES
    )
    if(NOT csv_parser_SOURCE_DIR)
        message(FATAL_ERROR "csv_parser: CPM did not provide a source directory")
    endif()
    tula_register_bundled_headers(csv_parser "${csv_parser_SOURCE_DIR}")

    add_library(tula_csv_parser INTERFACE)
    target_include_directories(
        tula_csv_parser
        INTERFACE "${csv_parser_SOURCE_DIR}/include"
    )
    add_library(tula::csv_parser ALIAS tula_csv_parser)
endfunction()
