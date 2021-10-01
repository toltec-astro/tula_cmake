include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Clipp "conan")


set(clipp_libs "")

if (USE_INSTALLED_CLIPP)
    verbose_message("Use system installed Clipp.")
    find_package(Clipp REQUIRED CONFIG)
    set(clipp_libs ${clipp_libs} clipp::clipp)
else()
    if (CONAN_INSTALL_CLIPP)
        include(conan_helper)
        conan_cmake_configure(REQUIRES
            clipp/[>=1.2.3]
            GENERATORS cmake_find_package)
        conan_cmake_install(PATH_OR_REFERENCE .
                    BUILD outdated
                    REMOTE conancenter
                    SETTINGS ${conan_install_settings}
                    ${conan_install_env_list}
                    )
        find_package(clipp REQUIRED MODULE)
        verbose_message("Use conan installed Clipp")
        set(clipp_libs ${clipp_libs} clipp::clipp)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(clipp GIT https://github.com/muellan/clipp.git master
            ADD_SUBDIR CONFIG_SUBDIR
                BUILD_TESTING=OFF
            )
        verbose_message("Use fetchcontent Clipp.")
        set(clipp_libs ${clipp_libs} clipp::clipp)
    endif()
endif()

if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${clipp_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_clipp INTERFACE)
target_link_libraries(tula_clipp INTERFACE ${clipp_libs})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_clipp)
endif()
add_library(tula::Clipp ALIAS tula_clipp)
