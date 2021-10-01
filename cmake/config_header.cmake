include_guard(GLOBAL)

include(verbose_message)

set(config_header_output_dir ${CMAKE_CURRENT_BINARY_DIR}/config_header)
add_library(tula_config_header INTERFACE)
target_include_directories(
    tula_config_header INTERFACE ${config_header_output_dir}
    )
add_library(tula::config_header ALIAS tula_config_header)

## Function to generate header files
set(config_header_srcdir ${CMAKE_CURRENT_LIST_DIR}/src)

function(get_config_header_output_dir output_dir name)
    if (NOT name)
        set(output_dir ${config_header_output_dir} PARENT_SCOPE)
    else()
        set(output_dir ${config_header_output_dir}/${name}_config PARENT_SCOPE)
    endif()
endfunction()

# Git version header
function(generate_gitversion_header name)
    get_config_header_output_dir(output_dir ${name})
    set(output_path ${output_dir}/gitversion.h)
    verbose_message("Generate gitversion header ${output_path}")
    set(_build_version "unknown")
    string(TOUPPER ${name} _build_prefix)
    find_package(Git)
    if(GIT_FOUND)
        set(local_dir ${CMAKE_CURRENT_LIST_DIR})
        verbose_message("GIT exec: ${GIT_EXECUTABLE}")
        verbose_message("GIT dir: ${local_dir}")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY "${local_dir}"
            OUTPUT_VARIABLE _build_revision
            OUTPUT_STRIP_TRAILING_WHITESPACE
            # ERROR_QUIET
        )
        verbose_message("GIT revision: ${_build_revision}")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --tags --always --broken
            WORKING_DIRECTORY "${local_dir}"
            OUTPUT_VARIABLE _build_version
            OUTPUT_STRIP_TRAILING_WHITESPACE
            # ERROR_QUIET
        )
        verbose_message("GIT version: ${_build_version}")
    else()
        verbose_message("Unable to get GIT version: GIT not found")
    endif()

    string(TIMESTAMP _time_stamp)
    verbose_message("Timestamp: ${_time_stamp}")
    configure_file(${config_header_srcdir}/gitversion.h.in ${output_path} @ONLY)
    add_custom_target(gitversion_header_${name} DEPENDS
        ${output_path}
    )
    add_dependencies(tula_config_header gitversion_header_${name})
endfunction()

# Config header
function(generate_config_header name)
    get_config_header_output_dir(output_dir ${name})
    set(output_path ${output_dir}/config.h)
    verbose_message("Generate config header ${output_path}")
    string(TOUPPER ${name} _build_prefix)
    configure_file(${config_header_srcdir}/config.h.in ${output_path} @ONLY)
    add_custom_target(config_header_${name} DEPENDS
        ${output_path}
    )
    add_dependencies(tula_config_header config_header_${name})
endfunction()
