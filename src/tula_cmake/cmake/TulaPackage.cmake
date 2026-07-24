include_guard(GLOBAL)

include(TulaCPM)

function(tula_resolve_package FEATURE MODE)
    if(TARGET "tula::${FEATURE}")
        return()
    endif()

    set(_prefix "TULA_FEATURE_${FEATURE}")
    set(_package "${${_prefix}_PACKAGE_NAME}")
    if(MODE STREQUAL "conan" OR MODE STREQUAL "system")
        find_package("${_package}" CONFIG REQUIRED)
    elseif(MODE STREQUAL "cpm")
        tula_load_cpm()
        CPMAddPackage(
            NAME "${${_prefix}_CPM_NAME}"
            URL "${${_prefix}_CPM_URL}"
            URL_HASH "SHA256=${${_prefix}_CPM_SHA256}"
            OPTIONS ${${_prefix}_CPM_OPTIONS}
        )
    else()
        message(FATAL_ERROR "${FEATURE}: unsupported provider ${MODE}")
    endif()

    set(_provider_target "")
    foreach(_candidate IN LISTS "${_prefix}_TARGET_CANDIDATES")
        if(TARGET "${_candidate}")
            set(_provider_target "${_candidate}")
            break()
        endif()
    endforeach()
    if(NOT _provider_target)
        message(FATAL_ERROR
            "${FEATURE}: none of the provider targets exist: ${${_prefix}_TARGET_CANDIDATES}")
    endif()

    add_library("tula_${FEATURE}" INTERFACE)
    target_link_libraries("tula_${FEATURE}" INTERFACE "${_provider_target}")
    add_library("tula::${FEATURE}" ALIAS "tula_${FEATURE}")
endfunction()
