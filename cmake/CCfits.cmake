include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(CCfits "conan")


set(ccfits_libs "")

if (USE_INSTALLED_CCFITS)
    verbose_message("Use system installed CCfits.")
    find_package(CCfits REQUIRED CONFIG)
    set(ccfits_libs ${ccfits_libs} CCfits::CCfits)
else()
    if (CONAN_INSTALL_CCFITS)
        include(conan_helper)
        ConanHelper(REQUIRES
            ccfits/[>=2.6]
            )
        find_package(ccfits REQUIRED MODULE)
        verbose_message("Use conan installed CCfits")
        set(ccfits_libs ${ccfits_libs} ccfits::ccfits)
    else()
        # fetch content
        message(FATAL_ERROR "CCfits does not support fetch content.")
    endif()
endif()

include(make_tula_target)
make_tula_target(CCfits ${ccfits_libs})
