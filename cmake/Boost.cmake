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
        conan_cmake_configure(REQUIRES
            boost/[>=1.77.0]
            GENERATORS cmake_find_package)
                    # OPTIONS
                    # boost:header_only=True
        conan_cmake_install(PATH_OR_REFERENCE .
                    BUILD outdated
                    REMOTE conancenter
                    SETTINGS ${conan_install_settings}
                    ${conan_install_env_list}
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

if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${boost_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_boost INTERFACE)
target_link_libraries(tula_boost INTERFACE ${boost_libs})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_boost)
endif()
add_library(tula::Boost ALIAS tula_boost)
