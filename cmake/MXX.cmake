include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(MXX "fetch")

set(mxx_libs "")

if (USE_INSTALLED_MXX)
    message(FATAL_ERROR "MXX does not support system installed.")
else()
    if (CONAN_INSTALL_MXX)
        message(FATAL_ERROR "MXX does not support conan install.")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(mxx GIT "https://github.com/patflick/mxx.git" master
            ADD_SUBDIR CONFIG_SUBDIR
                MXX_BUILD_TESTS=OFF
                MXX_BUILD_DOCS=OFF
            PATCH_SUBDIR
                ${FCH_PATCH_DIR}/patch.sh "mxx_fixcmake.patch"
                )
        verbose_message("Use fetchcontent MXX.")
        set(mxx_libs ${mxx_libs} mxx)
    endif()
endif()

include(make_tula_target)
make_tula_target(MXX ${mxx_libs})
