include_guard(GLOBAL)

include(TulaCPM)

function(_tula_clipp_installed)
    find_package(clipp CONFIG REQUIRED)
endfunction()

function(_tula_clipp_cpm)
    tula_load_cpm()
    CPMAddPackage(
        NAME clipp
        URL "${TULA_FEATURE_clipp_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_clipp_SHA256}"
        DOWNLOAD_ONLY YES
    )
    if(NOT clipp_SOURCE_DIR)
        message(FATAL_ERROR "clipp: CPM did not provide a source directory")
    endif()

    add_library(tula_clipp_upstream INTERFACE)
    target_include_directories(
        tula_clipp_upstream
        INTERFACE "${clipp_SOURCE_DIR}/include"
    )
endfunction()

function(_tula_clipp_finalize)
    if(TARGET tula::clipp)
        return()
    endif()

    if(TARGET clipp::clipp)
        set(_clipp_target clipp::clipp)
    elseif(TARGET tula_clipp_upstream)
        set(_clipp_target tula_clipp_upstream)
    else()
        message(FATAL_ERROR "clipp: provider target is unavailable")
    endif()

    add_library(tula_clipp INTERFACE)
    target_link_libraries(tula_clipp INTERFACE "${_clipp_target}")
    add_library(tula::clipp ALIAS tula_clipp)
endfunction()

function(tula_resolve_clipp_conan)
    _tula_clipp_installed()
    _tula_clipp_finalize()
endfunction()

function(tula_resolve_clipp_cpm)
    _tula_clipp_cpm()
    _tula_clipp_finalize()
endfunction()
