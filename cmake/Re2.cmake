include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Re2 "conan")

set(re2_libs "")

if (USE_INSTALLED_RE2)
    verbose_message("Use system installed Re2.")
    find_package(Re2 REQUIRED CONFIG)
    set(re2_libs ${re2_libs} re2::re2)
else()
    if (CONAN_INSTALL_RE2)
        include(conan_helper)
        ConanHelper(REQUIRES
            re2/20210901@
            )
        find_package(re2 REQUIRED MODULE)
        verbose_message("Use conan installed Re2")
        set(re2_libs ${re2_libs} re2::re2)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(re2 GIT "https://github.com/google/re2.git" "2021-09-01"
            ADD_SUBDIR CONFIG_SUBDIR
                RE2_BUILD_TESTING=OFF
                BUILD_SHARED_LIBS=OFF
                USEPCRE=OFF
            )
        verbose_message("Use fetchcontent Re2.")
        set(re2_libs ${re2_libs} re2::re2)
    endif()
endif()

include(make_tula_target)
make_tula_target(Re2 ${re2_libs})
