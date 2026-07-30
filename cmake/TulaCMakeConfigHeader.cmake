include_guard(GLOBAL)

include(CMakeParseArguments)
include(GNUInstallDirs)

function(tula_cmake_generate_config_header)
    set(
        one_value_args
        TARGET
        INPUT
        OUTPUT
        BUILD_INCLUDE_DIR
        INSTALL_INCLUDE_DIR
        SCOPE
    )
    cmake_parse_arguments(
        PARSE_ARGV 0
        header
        ""
        "${one_value_args}"
        ""
    )

    foreach(required_arg TARGET INPUT OUTPUT BUILD_INCLUDE_DIR)
        if(NOT header_${required_arg})
            message(
                FATAL_ERROR
                "tula_cmake_generate_config_header requires ${required_arg}"
            )
        endif()
    endforeach()
    if(NOT TARGET "${header_TARGET}")
        message(FATAL_ERROR "Target does not exist: ${header_TARGET}")
    endif()
    if(NOT header_SCOPE)
        get_target_property(target_type "${header_TARGET}" TYPE)
        if(target_type STREQUAL "INTERFACE_LIBRARY")
            set(header_SCOPE INTERFACE)
        else()
            set(header_SCOPE PUBLIC)
        endif()
    endif()
    if(NOT header_INSTALL_INCLUDE_DIR)
        set(header_INSTALL_INCLUDE_DIR "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()

    get_filename_component(output_directory "${header_OUTPUT}" DIRECTORY)
    file(MAKE_DIRECTORY "${output_directory}")
    configure_file("${header_INPUT}" "${header_OUTPUT}" @ONLY)

    target_include_directories(
        "${header_TARGET}"
        "${header_SCOPE}"
        "$<BUILD_INTERFACE:${header_BUILD_INCLUDE_DIR}>"
        "$<INSTALL_INTERFACE:${header_INSTALL_INCLUDE_DIR}>"
    )
endfunction()
