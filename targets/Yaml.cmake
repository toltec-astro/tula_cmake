# Yaml.cmake - YAML configuration file parsing support (yaml-cpp library)
#
# Defines: tula_Yaml_add_conan(), tula_Yaml_add_cpm(), tula_Yaml_add_system()
# Called by: tula_deps_add(deps Yaml) from tula_deps.cmake

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Load yaml-cpp from Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(tula_Yaml_add_conan)
    tula_try_conan_header_only(Yaml yaml-cpp::yaml-cpp yaml-cpp)
    if(NOT TULA_Yaml_CONAN_SUCCESS)
        return()
    endif()
    _tula_Yaml_create_wrapper()
endfunction()

#[=======================================================================[
@brief Fetch yaml-cpp via CPM
]=======================================================================]
function(tula_Yaml_add_cpm)
    if(NOT DEFINED TULA_YAML_CPM_GITHUB_REPO)
        return()
    endif()

    # CPM requires CXX language (compiles yaml-cpp). Defer to post-project().
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        message(STATUS "    Toolchain phase: deferring Yaml CPM to post-project() phase")
        return()
    endif()

    if(TARGET yaml-cpp::yaml-cpp)
        _tula_Yaml_create_wrapper()
        return()
    endif()

    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/_ensure_cpm.cmake)

    CPMAddPackage(
        NAME yaml-cpp
        GITHUB_REPOSITORY "${TULA_YAML_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_YAML_CPM_GIT_TAG}"
        OPTIONS ${TULA_YAML_CPM_OPTIONS}
        PATCH_COMMAND sed -i.bak "s/cmake_minimum_required(VERSION 3\\.4)/cmake_minimum_required(VERSION 3.5)/" <SOURCE_DIR>/CMakeLists.txt || true
    )

    # yaml-cpp creates target 'yaml-cpp' but does not add a namespace alias in the
    # build tree (only in install exports). Create the alias if needed.
    if(TARGET yaml-cpp AND NOT TARGET yaml-cpp::yaml-cpp)
        add_library(yaml-cpp::yaml-cpp ALIAS yaml-cpp)
    endif()

    if(yaml-cpp_ADDED OR TARGET yaml-cpp::yaml-cpp)
        message(STATUS "    Fetched Yaml via CPM")
        _tula_Yaml_create_wrapper()
    else()
        message(STATUS "    CPM fetch failed for Yaml")
    endif()
endfunction()

#[=======================================================================[
@brief Find yaml-cpp via system find_package
]=======================================================================]
function(tula_Yaml_add_system)
    tula_try_system(Yaml yaml-cpp::yaml-cpp yaml-cpp)
    if(NOT TULA_Yaml_SYSTEM_SUCCESS)
        return()
    endif()
    _tula_Yaml_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::Yaml wrapper target
]=======================================================================]
function(_tula_Yaml_create_wrapper)
    if(TARGET tula_Yaml)
        return()
    endif()
    
    if(NOT TARGET yaml-cpp::yaml-cpp)
        message(FATAL_ERROR "Cannot create wrapper: yaml-cpp::yaml-cpp target does not exist")
    endif()
    
    make_tula_target(Yaml yaml-cpp::yaml-cpp)
    
    verbose_message("Created tula::Yaml wrapper")
endfunction()

