include_guard(GLOBAL)

include(CMakePackageConfigHelpers)
include(CMakeParseArguments)
include(GNUInstallDirs)

function(tula_cmake_install_package)
    set(
        one_value_args
        PACKAGE
        EXPORT
        NAMESPACE
        VERSION
        COMPATIBILITY
        CONFIG_TEMPLATE
        DESTINATION
    )
    set(multi_value_args TARGETS)
    cmake_parse_arguments(
        PARSE_ARGV 0
        package
        ""
        "${one_value_args}"
        "${multi_value_args}"
    )

    foreach(required_arg PACKAGE EXPORT NAMESPACE TARGETS)
        if(NOT package_${required_arg})
            message(
                FATAL_ERROR
                "tula_cmake_install_package requires ${required_arg}"
            )
        endif()
    endforeach()
    if(NOT package_VERSION)
        set(package_VERSION "${PROJECT_VERSION}")
    endif()
    if(NOT package_COMPATIBILITY)
        set(package_COMPATIBILITY SameMajorVersion)
    endif()
    if(NOT package_DESTINATION)
        set(
            package_DESTINATION
            "${CMAKE_INSTALL_LIBDIR}/cmake/${package_PACKAGE}"
        )
    endif()

    if(NOT package_CONFIG_TEMPLATE)
        set(
            package_CONFIG_TEMPLATE
            "${CMAKE_CURRENT_BINARY_DIR}/${package_PACKAGE}Config.cmake.in"
        )
        file(
            WRITE "${package_CONFIG_TEMPLATE}"
            "@PACKAGE_INIT@\n\n"
            "include(\"\${CMAKE_CURRENT_LIST_DIR}/${package_EXPORT}.cmake\")\n"
            "check_required_components(${package_PACKAGE})\n"
        )
    endif()

    install(
        TARGETS ${package_TARGETS}
        EXPORT "${package_EXPORT}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    )
    install(
        EXPORT "${package_EXPORT}"
        FILE "${package_EXPORT}.cmake"
        NAMESPACE "${package_NAMESPACE}"
        DESTINATION "${package_DESTINATION}"
    )

    configure_package_config_file(
        "${package_CONFIG_TEMPLATE}"
        "${CMAKE_CURRENT_BINARY_DIR}/${package_PACKAGE}Config.cmake"
        INSTALL_DESTINATION "${package_DESTINATION}"
    )
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${package_PACKAGE}ConfigVersion.cmake"
        VERSION "${package_VERSION}"
        COMPATIBILITY "${package_COMPATIBILITY}"
    )
    install(
        FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${package_PACKAGE}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${package_PACKAGE}ConfigVersion.cmake"
        DESTINATION "${package_DESTINATION}"
    )
endfunction()
