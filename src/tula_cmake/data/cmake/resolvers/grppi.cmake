include_guard(GLOBAL)

include(TulaCPM)

function(tula_resolve_grppi_cpm)
    if(TARGET tula::grppi)
        return()
    endif()

    foreach(_dependency logging bitmask meta_enum perflibs)
        if(NOT TARGET "tula::${_dependency}")
            message(FATAL_ERROR
                "grppi: required target tula::${_dependency} is unavailable")
        endif()
    endforeach()

    tula_load_cpm()
    CPMAddPackage(
        NAME grppi
        URL "${TULA_FEATURE_grppi_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_grppi_SHA256}"
        DOWNLOAD_ONLY YES
    )
    if(NOT grppi_SOURCE_DIR)
        message(FATAL_ERROR "grppi: CPM did not provide a source directory")
    endif()
    tula_register_bundled_headers(grppi "${grppi_SOURCE_DIR}")

    add_library(tula_grppi INTERFACE)
    target_include_directories(
        tula_grppi
        SYSTEM INTERFACE "${grppi_SOURCE_DIR}/include"
    )
    target_link_libraries(
        tula_grppi
        INTERFACE
            tula::logging
            tula::bitmask
            tula::meta_enum
            tula::perflibs
    )
    if(TARGET OpenMP::OpenMP_CXX)
        target_compile_definitions(tula_grppi INTERFACE GRPPI_OMP)
    endif()
    add_library(tula::grppi ALIAS tula_grppi)
endfunction()
