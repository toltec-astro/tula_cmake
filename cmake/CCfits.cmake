include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(CCfits "conan")


set(ccfits_libs "")

if (USE_INSTALLED_CCFITS)
    verbose_message("Use system installed CCfits.")
    # find_package(CCfits REQUIRED CONFIG)
    # set(ccfits_libs ${ccfits_libs} CCfits::CCfits)
    message(STATUS "search CCfits in ${CCFITS_PREFIX}")
    find_path(CCFITS_INCLUDE_DIR CCfits/CCfits
        PATHS ${CCFITS_PREFIX}/include
        )
    find_library(CCFITS_LIBRARY CCfits
        PATHS ${CCFITS_PREFIX}/lib
        )
    find_library(CFITSIO_LIBRARY cfitsio
        PATHS ${CCFITS_PREFIX}/lib
        )
    set(CCFITS_FOUND false)
    if (CCFITS_INCLUDE_DIR AND CCFITS_LIBRARY)
        set(CCFITS_FOUND true)
    endif()
    MESSAGE(STATUS "CCfits include: ${CCFITS_INCLUDE_DIR}")
    MESSAGE(STATUS "CCfits lib: ${CCFITS_LIBRARY}")
    if (CCFITS_FOUND)
        MESSAGE(STATUS "Found CCfits: ${CCFITS_LIBRARY}")
    else()
        MESSAGE(FATAL_ERROR "Cannot find CCfits")
    endif()
    add_library(ccfits INTERFACE)
    target_include_directories(ccfits INTERFACE ${CCFITS_INCLUDE_DIR})
    target_link_libraries(ccfits INTERFACE ${CCFITS_LIBRARY} ${CFITSIO_LIBRARY} z)
    add_library(CCfits::CCfits ALIAS ccfits)
    set(ccfits_libs ${ccfits_libs} CCfits::CCfits)
else()
    if (CONAN_INSTALL_CCFITS)
        include(conan_helper)
        ConanHelper(REQUIRES
            ccfits/[>=2.6]
            )
            # BUILD all
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
