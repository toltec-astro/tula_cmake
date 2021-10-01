include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Spectra "conan")

set(spectra_libs "")

# make available eigen
if (NOT TARGET tula::Eigen3)
    # Fetch eigen if requested fetch spectra
    if (FETCH_CERES)
        verbose_message("FETCH_CERES=ON, set FETCH_EIGEN3=ON")
        set(FETCH_EIGEN3 ON)
    endif()
    include(Eigen3)
endif()

if (USE_INSTALLED_SPECTRA)
    verbose_message("Use system installed Spectra.")
    find_package(Spectra REQUIRED CONFIG)
    set(spectra_libs ${spectra_libs} Spectra::Spectra)
else()
    if (CONAN_INSTALL_SPECTRA)
        include(conan_helper)
        ConanHelper(REQUIRES
            eigen/[>=3.4]  # override the dependency
            spectra/[>=1.0]
            )
        find_package(spectra REQUIRED MODULE)
        verbose_message("Use conan installed Spectra")
        set(spectra_libs ${spectra_libs} Spectra::Spectra)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(spectra GIT "https://github.com/yixuan/spectra.git" master)
        # The official cmake list does not do much. We just roll our own target
        add_library(spectra INTERFACE)
        target_include_directories(spectra INTERFACE ${spectra_SOURCE_DIR}/include)
        target_link_libraries(spectra INTERFACE tula::Eigen3)
        add_library(Spectra::Spectra ALIAS spectra)
        verbose_message("Use fetchcontent Spectra.")
        set(spectra_libs ${spectra_libs} Spectra::Spectra)
    endif()
endif()

include(make_tula_target)
make_tula_target(Spectra ${spectra_libs})
