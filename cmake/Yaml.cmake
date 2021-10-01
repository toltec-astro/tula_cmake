include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Yaml "conan")


set(yaml_libs "")
set(yaml_defs "")

if (USE_INSTALLED_YAML)
    verbose_message("Use system installed Yaml.")
    find_package(yaml-cpp REQUIRED CONFIG)
    set(yaml_libs ${yaml_libs} yaml-cpp::yaml-cpp)
else()
    if (CONAN_INSTALL_YAML)
        include(conan_helper)
        conan_cmake_configure(REQUIRES
            yaml-cpp/[>=0.7]
            GENERATORS cmake_find_package)
        conan_cmake_install(PATH_OR_REFERENCE .
                    BUILD outdated
                    REMOTE conancenter
                    SETTINGS ${conan_install_settings}
                    ${conan_install_env_list}
                    )
        find_package(yaml-cpp REQUIRED MODULE)
        verbose_message("Use conan installed Yaml")
        set(yaml_libs ${yaml_libs} yaml-cpp::yaml-cpp)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(yaml GIT "https://github.com/jbeder/yaml-cpp.git" "master"
            ADD_SUBDIR CONFIG_SUBDIR
            YAML_CPP_BULID_CONTRIB=OFF
            YAML_CPP_BUILD_TOOLS=OFF
            YAML_CPP_BUILD_TESTS=OFF
            YAML_CPP_INSTALL=OFF
            YAML_BUILD_SHARED_LIBS=OFF
            YAML_MSVC_SHARED_RT=OFF
            )
        verbose_message("Use fetchcontent Yaml.")
        set(yaml_libs ${yaml_libs} yaml-cpp::yaml-cpp)
    endif()
endif()

if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${yaml_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_yaml INTERFACE)
target_link_libraries(tula_yaml INTERFACE ${yaml_libs})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_yaml)
endif()
add_library(tula::Yaml ALIAS tula_yaml)
