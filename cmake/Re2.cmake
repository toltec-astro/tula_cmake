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
        conan_cmake_configure(REQUIRES
            re2/20210901@
            GENERATORS cmake_find_package)
        conan_cmake_install(PATH_OR_REFERENCE .
                    BUILD outdated
                    REMOTE conancenter
                    SETTINGS ${conan_install_settings}
                    ${conan_install_env_list}
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

if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${re2_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_re2 INTERFACE)
target_link_libraries(tula_re2 INTERFACE ${re2_libs})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_re2)
endif()
add_library(tula::Re2 ALIAS tula_re2)
