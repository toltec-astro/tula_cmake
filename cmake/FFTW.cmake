include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(FFTW "conan")

set(fftw_libs "")

if (USE_INSTALLED_FFTW)
    verbose_message("Use system installed FFTW.")
    find_library(
        FFTW_DOUBLE_LIB
        NAMES "fftw3" libfftw3-3
        PATHS ${FFTW_ROOT}
        PATH_SUFFIXES "lib" "lib64"
        NO_DEFAULT_PATH
        )

    set(FFTW_LIBRARIES ${FFTW_LIBRARIES} ${FFTW_DOUBLE_LIB})
    add_library(FFTW::Double INTERFACE IMPORTED)
    set_target_properties(FFTW::Double
        PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${FFTW_INCLUDE_DIRS}"
        INTERFACE_LINK_LIBRARIES "${FFTW_DOUBLE_LIB}"
    )
    set(fftw_libs ${fftw_libs} FFTW::Double INTERFACE)
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
endif()

include(make_tula_target)
make_tula_target(FFTW ${fftw_libs})