include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Boost "conan")

set(boost_libs "")

if (USE_INSTALLED_BOOST)
    verbose_message("Use system installed Boost.")
    find_package(Boost REQUIRED CONFIG)
    set(boost_libs ${boost_libs} Boost::headers)
else()
    if (CONAN_INSTALL_BOOST)
        include(conan_helper)
        ConanHelper(REQUIRES
            boost/[>=1.77.0]
            )
        find_package(Boost REQUIRED MODULE)
        verbose_message("Use conan installed Boost")
        set(boost_libs ${boost_libs} Boost::boost)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(boost-cmake GIT "https://github.com/Orphis/boost-cmake.git" master
            ADD_SUBDIR CONFIG_SUBDIR
                BOOST_DISABLE_TESTS=ON
            )
        verbose_message("Use fetchcontent Boost.")
        set(boost_libs ${boost_libs} Boost::boost)
    endif()
endif()

include(make_tula_target)
make_tula_target(Boost ${boost_libs})
