include_guard(GLOBAL)

function(tula_resolve_spectra_conan)
    if(TARGET tula::spectra)
        return()
    endif()
    if(NOT TARGET tula::eigen)
        message(FATAL_ERROR "spectra: required target tula::eigen is unavailable")
    endif()

    find_package(spectra CONFIG REQUIRED)
    if(NOT TARGET Spectra::Spectra)
        message(FATAL_ERROR "spectra: Spectra::Spectra provider target is unavailable")
    endif()

    add_library(tula_spectra INTERFACE)
    target_link_libraries(tula_spectra INTERFACE Spectra::Spectra tula::eigen)
    add_library(tula::spectra ALIAS tula_spectra)
endfunction()
