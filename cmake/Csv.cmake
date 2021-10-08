include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Csv "fetch")


set(csv_libs "")


if (USE_INSTALLED_CSV)
    messsage(FATAL_ERROR "Csv-parser does not support use installed.")
else()
    if (CONAN_INSTALL_CSV)
        messsage(FATAL_ERROR "Csv-parser does not support conan install.")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(csv_parser GIT "https://github.com/Jerry-Ma/csv-parser.git" "master")
        # Create target and add include path
        add_library(csv_parser INTERFACE)
        target_include_directories(csv_parser INTERFACE ${csv_parser_SOURCE_DIR})
        add_library(csv_parser::csv_parser ALIAS csv_parser)

        set(csv_libs ${csv_libs} csv_parser::csv_parser)
    endif()
endif()

include(make_tula_target)
make_tula_target(Csv ${csv_libs})
