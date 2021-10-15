include_guard(GLOBAL)

include(verbose_message)

set(default_loglevel "Trace")
if (CMAKE_BUILD_TYPE MATCHES "^(Release|MinSizeRel)$")
    set(default_loglevel "Debug")
endif()

set(LOGLEVEL "${default_loglevel}" CACHE STRING "Choose the minimum log level to enable.")
set_property(CACHE LOGLEVEL PROPERTY STRINGS "Trace" "Debug" "Info" "Warning" "Error")

verbose_message("Minimum log level enabled at compile-time: ${LOGLEVEL}")

# Add the logging libs
include(make_pkg_options)
# 20210930 The fmtlib does not support C++20 concept so we use our fork here with fetch
make_pkg_options(logging_libs "fetch")

set(logging_libs "")

if (USE_INSTALLED_LOGGING_LIBS)
    verbose_message("Use system installed spdlog and fmtlib.")
    find_package(fmt 8.0 REQUIRED CONFIG)
    find_package(spdlog 1.9 REQUIRED CONFIG)
    set(logging_libs ${logging_libs} spdlog::spdlog)
else()
    if (CONAN_INSTALL_LOGGING_LIBS)
        include(conan_helper)
        ConanHelper(REQUIRES
            fmt/[>=8.0]
            spdlog/[>=1.9]
            )
        find_package(fmt REQUIRED MODULE)
        find_package(spdlog REQUIRED MODULE)
        verbose_message("Use conan installed spdlog and fmtlib.")
        set(logging_libs ${logging_libs} spdlog::spdlog fmt::fmt)
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(fmt GIT "https://github.com/toltec-astro/fmt.git" "feature-customizable-range-formatter"
            ADD_SUBDIR CONFIG_SUBDIR
            BUILD_SHARED_LIBS=OFF
            FMT_DOC=OFF
            FMT_INSTALL=OFF
            FMT_TEST=OFF
            )
        # set_target_properties(fmt PROPERTIES INTERFACE_COMPILE_DEFINITIONS "FMT_USE_CONSTEXPR")
        FetchContentHelper(spdlog GIT "https://github.com/gabime/spdlog.git" v1.x
            ADD_SUBDIR CONFIG_SUBDIR
            SPDLOG_BUILD_EXAMPLE=OFF
            SPDLOG_BUILD_EXAMPLE_HO=OFF
            SPDLOG_BUILD_TESTS=OFF
            SPDLOG_BUILD_TESTS_HO=OFF
            SPDLOG_BUILD_BENCH=OFF
            SPDLOG_FMT_EXTERNAL=ON
            SPDLOG_FMT_EXTERNAL_HO=OFF
            SPDLOG_BUILD_SHARED=OFF
            SPDLOG_INSTALL=OFF
            )
        verbose_message("Use fetchcontent spdlog and fmtlib.")
        set(logging_libs ${logging_libs} spdlog::spdlog fmt::fmt)
    endif()
endif()

include(make_tula_target)
make_tula_target(logging ${logging_libs})
target_compile_definitions(tula_logging INTERFACE LOGLEVEL=${LOGLEVEL})
