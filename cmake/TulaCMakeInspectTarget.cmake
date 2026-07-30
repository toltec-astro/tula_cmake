include_guard(GLOBAL)

include(CMakeParseArguments)
include("${CMAKE_CURRENT_LIST_DIR}/TulaCMakeLog.cmake")

function(tula_cmake_inspect_target)
    set(one_value_args TARGET LEVEL)
    set(multi_value_args PROPERTIES)
    cmake_parse_arguments(
        PARSE_ARGV 0
        inspect
        ""
        "${one_value_args}"
        "${multi_value_args}"
    )

    if(NOT inspect_TARGET)
        message(FATAL_ERROR "tula_cmake_inspect_target requires TARGET")
    endif()
    if(NOT TARGET "${inspect_TARGET}")
        message(FATAL_ERROR "Target does not exist: ${inspect_TARGET}")
    endif()
    if(NOT inspect_LEVEL)
        set(inspect_LEVEL DEBUG)
    endif()
    if(NOT inspect_PROPERTIES)
        set(
            inspect_PROPERTIES
            TYPE
            IMPORTED
            INTERFACE_INCLUDE_DIRECTORIES
            INTERFACE_LINK_LIBRARIES
            INTERFACE_COMPILE_DEFINITIONS
            INTERFACE_COMPILE_FEATURES
            INTERFACE_COMPILE_OPTIONS
        )
    endif()

    get_target_property(inspected_target "${inspect_TARGET}" ALIASED_TARGET)
    if(NOT inspected_target)
        set(inspected_target "${inspect_TARGET}")
    endif()

    tula_cmake_log(
        "${inspect_LEVEL}"
        "Target ${inspect_TARGET} resolves to ${inspected_target}"
    )
    foreach(property_name IN LISTS inspect_PROPERTIES)
        get_property(
            property_is_set
            TARGET "${inspected_target}"
            PROPERTY "${property_name}"
            SET
        )
        if(property_is_set)
            get_target_property(
                property_value
                "${inspected_target}"
                "${property_name}"
            )
            string(REPLACE ";" "; " property_value "${property_value}")
        else()
            set(property_value "<unset>")
        endif()
        tula_cmake_log(
            "${inspect_LEVEL}"
            "  ${property_name} = ${property_value}"
        )
    endforeach()
endfunction()
