include_guard(GLOBAL)

include(verbose_message)

include(make_pkg_options)
make_pkg_options(Enum "fetch")


set(enum_libs "")


if (USE_INSTALLED_ENUM)
    messsage(FATAL_ERROR "Enum.hpp does not support use installed.")
else()
    if (CONAN_INSTALL_ENUM)
        messsage(FATAL_ERROR "Enum.hpp does not support conan install.")
    else()
        # fetch content
        include(fetchcontent_helper)
        FetchContentHelper(meta_enum GIT "https://github.com/Jerry-Ma/meta_enum.git" "master")
        # Create target and add include path
        add_library(meta_enum INTERFACE)
        target_include_directories(meta_enum INTERFACE ${meta_enum_SOURCE_DIR}/include)
        add_library(meta_enum::meta_enum ALIAS meta_enum)

        FetchContentHelper(bitmask GIT "https://github.com/oliora/bitmask.git" "master")
        # Create target and add include path
        add_library(bitmask INTERFACE)
        target_include_directories(bitmask INTERFACE ${bitmask_SOURCE_DIR}/include)
        add_library(bitmask::bitmask ALIAS bitmask)

        set(enum_libs ${enum_libs} meta_enum::meta_enum bitmask::bitmask)
    endif()
endif()

include(make_tula_target)
make_tula_target(Enum ${enum_libs})
