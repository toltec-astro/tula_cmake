# Clipp.cmake - Command line interface parser
#
# Defines: tula_Clipp_add_conan(), tula_Clipp_add_cpm(), tula_Clipp_add_system()
# Called by: tula_deps_add(deps Clipp) from tula_deps.cmake

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Load Clipp from Conan
]=======================================================================]
function(tula_Clipp_add_conan)
    tula_try_conan_header_only(Clipp clipp::clipp clipp)
    if(NOT TULA_Clipp_CONAN_SUCCESS)
        return()
    endif()
    _tula_Clipp_create_wrapper()
endfunction()

#[=======================================================================[
@brief Fetch Clipp via CPM
]=======================================================================]
function(tula_Clipp_add_cpm)
    if(NOT DEFINED TULA_CLIPP_CPM_GITHUB_REPO)
        return()
    endif()

    if(TARGET clipp::clipp)
        set(TULA_Clipp_CPM_SUCCESS TRUE PARENT_SCOPE)
        _tula_Clipp_create_wrapper()
        return()
    endif()

    # Clipp's CMakeLists.txt has `project(LANGUAGES CXX)` which causes a recursive
    # language-enable error during the CMake toolchain phase. Use CPM's DOWNLOAD_ONLY
    # to fetch the source without add_subdirectory, then create the target manually.
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/_ensure_cpm.cmake)
    CPMAddPackage(
        NAME clipp
        GITHUB_REPOSITORY "${TULA_CLIPP_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_CLIPP_CPM_GIT_TAG}"
        DOWNLOAD_ONLY YES
    )

    if(clipp_ADDED)
        add_library(clipp INTERFACE)
        target_include_directories(clipp INTERFACE "${clipp_SOURCE_DIR}/include")
        add_library(clipp::clipp ALIAS clipp)
        message(STATUS "    Fetched Clipp via CPM DOWNLOAD_ONLY (header-only)")
        set(TULA_Clipp_CPM_SUCCESS TRUE PARENT_SCOPE)
        _tula_Clipp_create_wrapper()
    else()
        message(STATUS "    CPM DOWNLOAD_ONLY failed for Clipp")
        set(TULA_Clipp_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Find Clipp via system find_package
]=======================================================================]
function(tula_Clipp_add_system)
    tula_try_system(Clipp clipp::clipp Clipp)
    if(NOT TULA_Clipp_SYSTEM_SUCCESS)
        return()
    endif()
    _tula_Clipp_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::Clipp wrapper target
]=======================================================================]
function(_tula_Clipp_create_wrapper)
    if(TARGET tula_Clipp)
        return()
    endif()
    
    if(NOT TARGET clipp::clipp)
        message(FATAL_ERROR "Cannot create wrapper: clipp::clipp target does not exist")
    endif()
    
    make_tula_target(Clipp clipp::clipp)
    
    verbose_message("Created tula::Clipp wrapper")
endfunction()
