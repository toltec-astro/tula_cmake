include_guard(GLOBAL)

include(CMakeParseArguments)
include("${CMAKE_CURRENT_LIST_DIR}/TulaCMakeLog.cmake")

function(tula_cmake_target_defaults)
    set(options WARNINGS)
    set(one_value_args TARGET CXX_STANDARD SCOPE)
    cmake_parse_arguments(
        PARSE_ARGV 0
        defaults
        "${options}"
        "${one_value_args}"
        ""
    )

    if(NOT defaults_TARGET)
        message(FATAL_ERROR "tula_cmake_target_defaults requires TARGET")
    endif()
    if(NOT TARGET "${defaults_TARGET}")
        message(FATAL_ERROR "Target does not exist: ${defaults_TARGET}")
    endif()
    if(NOT defaults_CXX_STANDARD)
        set(defaults_CXX_STANDARD 23)
    endif()

    get_target_property(target_type "${defaults_TARGET}" TYPE)
    if(NOT defaults_SCOPE)
        if(target_type STREQUAL "INTERFACE_LIBRARY")
            set(defaults_SCOPE INTERFACE)
        else()
            set(defaults_SCOPE PRIVATE)
        endif()
    endif()

    target_compile_features(
        "${defaults_TARGET}"
        "${defaults_SCOPE}"
        "cxx_std_${defaults_CXX_STANDARD}"
    )
    if(NOT target_type STREQUAL "INTERFACE_LIBRARY")
        set_target_properties(
            "${defaults_TARGET}"
            PROPERTIES
                CXX_EXTENSIONS OFF
                CXX_STANDARD_REQUIRED ON
        )
    endif()

    if(defaults_WARNINGS AND NOT target_type STREQUAL "INTERFACE_LIBRARY")
        target_compile_options(
            "${defaults_TARGET}"
            "${defaults_SCOPE}"
            "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-Wall>"
            "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-Wextra>"
            "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-Wpedantic>"
            "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/W4>"
        )
    elseif(defaults_WARNINGS)
        tula_cmake_log(
            VERBOSE
            "Skipping warning flags for header-only target '${defaults_TARGET}' so installed consumers retain their warning policy"
        )
    endif()
endfunction()
