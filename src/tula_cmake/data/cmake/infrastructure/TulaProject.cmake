include_guard(GLOBAL)

include(TulaConfigHeader)
include(TulaCPM)

function(tula_resolve_project_dependencies)
    get_property(_resolved GLOBAL PROPERTY TULA_PROJECTS_RESOLVED)
    if(_resolved)
        return()
    endif()
    get_property(_resolving GLOBAL PROPERTY TULA_PROJECTS_RESOLVING)
    if(_resolving)
        return()
    endif()
    if(NOT TULA_PROJECT_MANIFEST OR NOT EXISTS "${TULA_PROJECT_MANIFEST}")
        message(FATAL_ERROR
            "TULA_PROJECT_MANIFEST is unavailable; run the tula-cmake launcher")
    endif()

    include("${TULA_PROJECT_MANIFEST}")
    set_property(GLOBAL PROPERTY TULA_PROJECTS_RESOLVING TRUE)
    foreach(_project IN LISTS TULA_PROJECT_DEPENDENCIES)
        set(_mode_variable "TULA_PROJECT_${_project}_MODE")
        set(_source_variable "TULA_PROJECT_${_project}_SOURCE_DIR")
        set(_target_variable "TULA_PROJECT_${_project}_TARGET")
        set(_mode "${${_mode_variable}}")
        set(_source_dir "${${_source_variable}}")
        set(_target "${${_target_variable}}")
        if(NOT _mode STREQUAL "cpm")
            message(FATAL_ERROR
                "${_project}: project provider ${_mode} is not implemented")
        endif()
        if(NOT IS_DIRECTORY "${_source_dir}")
            message(FATAL_ERROR
                "${_project}: source directory is unavailable: ${_source_dir}")
        endif()

        tula_load_cpm()
        CPMAddPackage(
            NAME "${_project}"
            SOURCE_DIR "${_source_dir}"
            EXCLUDE_FROM_ALL YES
            SYSTEM NO
        )
        if(NOT TARGET "${_target}")
            message(FATAL_ERROR
                "${_project}: cpm provider did not create ${_target}")
        endif()
        set_property(
            GLOBAL PROPERTY "TULA_PROJECT_${_project}_PROVIDER" "${_mode}")
        message(STATUS "(tula) ${_project}: ${_mode}")
    endforeach()
    set_property(GLOBAL PROPERTY TULA_PROJECTS_RESOLVING FALSE)
    set_property(GLOBAL PROPERTY TULA_PROJECTS_RESOLVED TRUE)
endfunction()

function(tula_resolve_features)
    get_property(_resolved GLOBAL PROPERTY TULA_FEATURES_RESOLVED)
    if(_resolved)
        return()
    endif()
    if(NOT PROJECT_NAME)
        message(FATAL_ERROR "tula_resolve_features() must be called after project()")
    endif()
    if(NOT TULA_FEATURE_MANIFEST OR NOT EXISTS "${TULA_FEATURE_MANIFEST}")
        message(FATAL_ERROR
            "TULA_FEATURE_MANIFEST is unavailable; run the tula-cmake launcher")
    endif()

    include("${TULA_FEATURE_MANIFEST}")
    foreach(_feature IN LISTS TULA_FEATURES)
        set(_mode_variable "TULA_FEATURE_${_feature}_MODE")
        set(_mode "${${_mode_variable}}")
        if(_mode STREQUAL "disabled")
            message(STATUS "(tula) ${_feature}: disabled")
            set_property(GLOBAL PROPERTY "TULA_FEATURE_${_feature}_PROVIDER" "disabled")
            continue()
        endif()

        set(_module_variable "TULA_FEATURE_${_feature}_MODULE")
        include("${${_module_variable}}")
        set(_entrypoint "tula_resolve_${_feature}_${_mode}")
        if(NOT COMMAND "${_entrypoint}")
            message(FATAL_ERROR
                "${_feature}: missing provider entrypoint ${_entrypoint}()")
        endif()
        cmake_language(CALL "${_entrypoint}")
        if(NOT TARGET "tula::${_feature}")
            message(FATAL_ERROR
                "${_feature}: ${_mode} provider did not create tula::${_feature}")
        endif()
        set_property(GLOBAL PROPERTY "TULA_FEATURE_${_feature}_PROVIDER" "${_mode}")
        message(STATUS "(tula) ${_feature}: ${_mode}")
    endforeach()
    set_property(GLOBAL PROPERTY TULA_FEATURE_NAMES "${TULA_FEATURES}")
    set_property(GLOBAL PROPERTY TULA_FEATURES_RESOLVED TRUE)
endfunction()

function(tula_get_feature_provider OUT_VAR FEATURE)
    get_property(_provider GLOBAL PROPERTY "TULA_FEATURE_${FEATURE}_PROVIDER")
    if(NOT _provider)
        set(_provider "disabled")
    endif()
    set("${OUT_VAR}" "${_provider}" PARENT_SCOPE)
endfunction()

function(tula_register_bundled_headers FEATURE SOURCE_DIR)
    if(NOT IS_DIRECTORY "${SOURCE_DIR}/include")
        message(FATAL_ERROR
            "${FEATURE}: bundled provider has no include directory at ${SOURCE_DIR}")
    endif()
    set_property(GLOBAL APPEND PROPERTY TULA_BUNDLED_HEADER_FEATURES "${FEATURE}")
    set_property(GLOBAL PROPERTY "TULA_BUNDLED_HEADER_${FEATURE}_DIR" "${SOURCE_DIR}/include")
endfunction()

function(tula_install_bundled_headers)
    get_property(_features GLOBAL PROPERTY TULA_BUNDLED_HEADER_FEATURES)
    foreach(_feature IN LISTS _features)
        get_property(
            _include_dir
            GLOBAL PROPERTY "TULA_BUNDLED_HEADER_${_feature}_DIR"
        )
        install(
            DIRECTORY "${_include_dir}/"
            DESTINATION include
            PATTERN ".git*" EXCLUDE
        )
    endforeach()
endfunction()
