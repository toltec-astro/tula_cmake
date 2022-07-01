include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Matplotlibcpp "fetch")


set(matplotlibcpp_libs "")


if (USE_INSTALLED_MATPLOTLIBCPP)
    messsage(FATAL_ERROR "MATPLOTLIBCPP does not support use installed.")
else()
    if (CONAN_INSTALL_MATPLOTLIBCPP)
        messsage(FATAL_ERROR "MATPLOTLIBCPP does not support conan install.")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(
            matplotlibcpp GIT "https://github.com/Jerry-Ma/matplotlib-cpp.git" master
            )
        add_library(matplotlibcpp INTERFACE)
        target_include_directories(matplotlibcpp SYSTEM INTERFACE ${matplotlibcpp_SOURCE_DIR})
        # TODO: Use `Development.Embed` component when requiring cmake >= 3.18
        find_package(Python3 COMPONENTS Interpreter Development NumPy REQUIRED)
        target_link_libraries(matplotlibcpp INTERFACE
          Python3::Python
          Python3::Module
          Python3::NumPy
        )
        target_compile_definitions(matplotlibcpp INTERFACE WITHOUT_NUMPY)
        add_library(matplotlibcpp::matplotlibcpp ALIAS matplotlibcpp)
        verbose_message("Use fetchcontent Matplotlibcpp.")
        set(matplotlibcpp_libs ${matplotlibcpp_libs} matplotlibcpp::matplotlibcpp)
    endif()
endif()

include(make_tula_target)
make_tula_target(Matplotlibcpp ${matplotlibcpp_libs})
