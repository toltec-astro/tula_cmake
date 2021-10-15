include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Clipp "fetch")


set(clipp_libs "")

if (USE_INSTALLED_CLIPP)
    verbose_message("Use system installed Clipp.")
    find_package(Clipp REQUIRED CONFIG)
    set(clipp_libs ${clipp_libs} clipp::clipp)
else()
    if (CONAN_INSTALL_CLIPP)
        include(conan_helper)
        ConanHelper(REQUIRES
            clipp/[>=1.2.3]
            )
        find_package(clipp REQUIRED MODULE)
        verbose_message("Use conan installed Clipp")
        set(clipp_libs ${clipp_libs} clipp::clipp)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(clipp GIT https://github.com/GerHobbelt/clipp.git master)
        # Create target and add include path
        add_library(clipp INTERFACE)
        target_include_directories(clipp INTERFACE ${clipp_SOURCE_DIR}/include)
        add_library(clipp::clipp ALIAS clipp)

        verbose_message("Use fetchcontent Clipp.")
        set(clipp_libs ${clipp_libs} clipp::clipp)
    endif()
endif()

include(make_tula_target)
make_tula_target(Clipp ${clipp_libs})
