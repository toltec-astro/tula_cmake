include_guard(GLOBAL)

include(verbose_message)

# Add the testing libs
include(make_pkg_options)
make_pkg_options(testing_libs "conan")

set(testing_libs "")

if (USE_INSTALLED_TESTING_LIBS)
    verbose_message("Use system installed gtest and gbench.")
    find_package(GTest REQUIRED CONFIG)
    find_package(benchmark REQUIRED CONFIG)
    set(testing_libs ${testing_libs} GTest::gtest GTest::gmock benchmark::benchmark)
else()
    if (CONAN_INSTALL_TESTING_LIBS)
        include(conan_helper)
        conan_cmake_configure(REQUIRES
            benchmark/[>=1.5]
            gtest/cci.20210126
            GENERATORS cmake_find_package)
        conan_cmake_install(PATH_OR_REFERENCE .
                    BUILD outdated
                    REMOTE conancenter
                    SETTINGS ${conan_install_settings}
                    ${conan_install_env_list}
                    )
        find_package(GTest REQUIRED MODULE)
        find_package(benchmark REQUIRED MODULE)
        verbose_message("Use conan installed gtest and gbench.")
        set(testing_libs ${testing_libs} GTest::gtest GTest::gmock benchmark::benchmark)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(benchmark GIT https://github.com/google/benchmark.git v1.6.0
            ADD_SUBDIR CONFIG_SUBDIR
                BENCHMARK_ENABLE_TESTING=OFF
                BENCHMARK_ENABLE_INSTALL=OFF
                BENCHMARK_INSTALL_DOCS=OFF
                BENCHMARK_ENABLE_GTEST_TESTS=OFF
                BENCHMARK_ENABLE_ASSEMBLY_TESTS=OFF
            )
        FetchContentHelper(googletest GIT https://github.com/google/googletest.git release-1.11.0
            ADD_SUBDIR CONFIG_SUBDIR
                BUILD_GMOCK=ON
                INSTALL_GTEST=OFF
            )
        verbose_message("Use fetchcontent gtest and gbench.")
        set(testing_libs ${testing_libs} GTest::gtest GTest::gmock benchmark::benchmark)
    endif()
endif()
if (VERBOSE_MESSAGE)
    include(print_properties)
    foreach (lib ${testing_libs})
        print_target_properties(${lib})
    endforeach()
endif()

add_library(tula_testing INTERFACE)
target_link_libraries(tula_testing INTERFACE ${testing_libs})
target_compile_definitions(tula_testing INTERFACE LOGLEVEL=${LOGLEVEL})
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_testing)
endif()
add_library(tula::testing ALIAS tula_testing)

# setup the test env
enable_testing()
# https://gitlab.kitware.com/cmake/community/wikis/doc/tutorials/EmulateMakeCheck
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})
include(GoogleTest)
