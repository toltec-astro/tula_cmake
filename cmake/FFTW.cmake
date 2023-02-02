include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(FFTW "conan")

set(fftw_libs "")

if (USE_INSTALLED_FFTW)
    verbose_message("Use system installed FFTW.")
    find_package(fftw 3.3.10 REQUIRED CONFIG)
    set(fftw_libs ${fftw_libs} fftw:fftw)

else()
    if (CONAN_INSTALL_FFTW)
        include(conan_helper)
        ConanHelper(REQUIRES
            fftw/[>=3.3.9]
            )
        find_package(fftw REQUIRED MODULE)
        verbose_message("Use conan installed FFTW")
        set(fftw_libs ${eigen3_libs} fftw::fftw)
endif()

include(make_tula_target)
make_tula_target(FFTW ${fftw_libs})