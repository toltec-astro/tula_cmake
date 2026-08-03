include_guard(GLOBAL)

include(CMakeParseArguments)
include(GNUInstallDirs)

function(_tula_cmake_escape_cpp_string output_var input_value)
    string(REPLACE "\\" "\\\\" escaped_value "${input_value}")
    string(REPLACE "\"" "\\\"" escaped_value "${escaped_value}")
    set("${output_var}" "${escaped_value}" PARENT_SCOPE)
endfunction()

function(tula_cmake_detect_git_revision output_var)
    set(one_value_args SOURCE_DIR)
    cmake_parse_arguments(
        PARSE_ARGV 1
        git
        ""
        "${one_value_args}"
        ""
    )
    if(NOT git_SOURCE_DIR)
        set(git_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    find_package(Git QUIET)
    if(NOT Git_FOUND)
        set("${output_var}" "unknown" PARENT_SCOPE)
        return()
    endif()

    execute_process(
        COMMAND "${GIT_EXECUTABLE}" rev-parse --verify HEAD
        WORKING_DIRECTORY "${git_SOURCE_DIR}"
        RESULT_VARIABLE git_result
        OUTPUT_VARIABLE git_revision
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT git_result EQUAL 0)
        set(git_revision "unknown")
    endif()
    set("${output_var}" "${git_revision}" PARENT_SCOPE)
endfunction()

function(tula_cmake_detect_git_state output_var)
    set(one_value_args SOURCE_DIR)
    cmake_parse_arguments(PARSE_ARGV 1 git "" "${one_value_args}" "")
    if(NOT git_SOURCE_DIR)
        set(git_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    find_package(Git QUIET)
    if(NOT Git_FOUND)
        set("${output_var}" "unknown" PARENT_SCOPE)
        return()
    endif()
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" status --porcelain --untracked-files=no
        WORKING_DIRECTORY "${git_SOURCE_DIR}"
        RESULT_VARIABLE git_result
        OUTPUT_VARIABLE git_status
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT git_result EQUAL 0)
        set(git_state "unknown")
    elseif(git_status)
        set(git_state "dirty")
    else()
        set(git_state "clean")
    endif()
    set("${output_var}" "${git_state}" PARENT_SCOPE)
endfunction()

function(tula_cmake_generate_version_header)
    set(
        one_value_args
        TARGET
        OUTPUT
        BUILD_INCLUDE_DIR
        INSTALL_INCLUDE_DIR
        NAMESPACE
        VERSION
        REVISION
        GIT_STATE
        SOURCE_DIR
        SCOPE
        PACKAGE_SPEC
        DAG_HASH
        BUILD_PROFILE
        LOCK_SHA256
    )
    cmake_parse_arguments(
        PARSE_ARGV 0
        version
        ""
        "${one_value_args}"
        ""
    )

    foreach(required_arg TARGET OUTPUT BUILD_INCLUDE_DIR NAMESPACE VERSION)
        if(NOT version_${required_arg})
            message(
                FATAL_ERROR
                "tula_cmake_generate_version_header requires ${required_arg}"
            )
        endif()
    endforeach()
    if(NOT TARGET "${version_TARGET}")
        message(FATAL_ERROR "Target does not exist: ${version_TARGET}")
    endif()
    if(NOT version_REVISION)
        tula_cmake_detect_git_revision(
            version_REVISION
            SOURCE_DIR "${version_SOURCE_DIR}"
        )
    endif()
    if(NOT version_GIT_STATE)
        tula_cmake_detect_git_state(
            version_GIT_STATE
            SOURCE_DIR "${version_SOURCE_DIR}"
        )
    endif()
    if(NOT version_INSTALL_INCLUDE_DIR)
        set(version_INSTALL_INCLUDE_DIR "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()
    if(NOT version_SCOPE)
        get_target_property(target_type "${version_TARGET}" TYPE)
        if(target_type STREQUAL "INTERFACE_LIBRARY")
            set(version_SCOPE INTERFACE)
        else()
            set(version_SCOPE PUBLIC)
        endif()
    endif()

    _tula_cmake_escape_cpp_string(escaped_version "${version_VERSION}")
    _tula_cmake_escape_cpp_string(escaped_revision "${version_REVISION}")
    _tula_cmake_escape_cpp_string(escaped_git_state "${version_GIT_STATE}")
    _tula_cmake_escape_cpp_string(escaped_spec "${version_PACKAGE_SPEC}")
    _tula_cmake_escape_cpp_string(escaped_dag_hash "${version_DAG_HASH}")
    _tula_cmake_escape_cpp_string(escaped_profile "${version_BUILD_PROFILE}")
    _tula_cmake_escape_cpp_string(escaped_lock "${version_LOCK_SHA256}")
    set(compiler "${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
    _tula_cmake_escape_cpp_string(escaped_compiler "${compiler}")
    get_target_property(cxx_standard "${version_TARGET}" CXX_STANDARD)
    if(NOT cxx_standard)
        set(cxx_standard 0)
    endif()

    set(header_content
"#pragma once

#include <string_view>

namespace ${version_NAMESPACE} {

inline constexpr std::string_view version = \"${escaped_version}\";
inline constexpr std::string_view git_revision = \"${escaped_revision}\";
inline constexpr std::string_view git_state = \"${escaped_git_state}\";
inline constexpr std::string_view compiler = \"${escaped_compiler}\";
inline constexpr int cxx_standard = ${cxx_standard};
inline constexpr std::string_view package_spec = \"${escaped_spec}\";
inline constexpr std::string_view dag_hash = \"${escaped_dag_hash}\";
inline constexpr std::string_view build_profile = \"${escaped_profile}\";
inline constexpr std::string_view lock_sha256 = \"${escaped_lock}\";

}  // namespace ${version_NAMESPACE}
")

    get_filename_component(output_directory "${version_OUTPUT}" DIRECTORY)
    file(MAKE_DIRECTORY "${output_directory}")
    if(EXISTS "${version_OUTPUT}")
        file(READ "${version_OUTPUT}" existing_header_content)
    endif()
    if(NOT existing_header_content STREQUAL header_content)
        file(WRITE "${version_OUTPUT}" "${header_content}")
    endif()

    target_include_directories(
        "${version_TARGET}"
        "${version_SCOPE}"
        "$<BUILD_INTERFACE:${version_BUILD_INCLUDE_DIR}>"
        "$<INSTALL_INTERFACE:${version_INSTALL_INCLUDE_DIR}>"
    )
endfunction()
