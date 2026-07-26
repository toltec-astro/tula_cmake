include_guard(GLOBAL)

function(tula_resolve_fftw_conan)
    if(TARGET tula::fftw)
        return()
    endif()

    find_package(FFTW3 CONFIG REQUIRED)
    if(NOT TARGET FFTW3::fftw3)
        message(FATAL_ERROR "fftw: FFTW3::fftw3 provider target is unavailable")
    endif()

    add_library(tula_fftw INTERFACE)
    target_link_libraries(tula_fftw INTERFACE FFTW3::fftw3)
    add_library(tula::fftw ALIAS tula_fftw)
endfunction()
