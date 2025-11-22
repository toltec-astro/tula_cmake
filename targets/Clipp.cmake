# Clipp.cmake - Command line interface parser
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Setup Clipp package with tri-modal resolution
@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_Clipp MODE)
    verbose_message("Setting up tula::Clipp (mode=${MODE})")
    
    if(TARGET tula::Clipp)
        verbose_message("tula::Clipp already exists")
        return()
    endif()
    
    if(MODE STREQUAL "AUTO")
        TULA_Clipp_TRY_CONAN()
        if(NOT TULA_Clipp_CONAN_SUCCESS)
            TULA_Clipp_TRY_CPM()
        endif()
        if(NOT TULA_Clipp_CPM_SUCCESS)
            TULA_Clipp_TRY_SYSTEM()
        endif()
    elseif(MODE STREQUAL "CONAN")
        TULA_Clipp_TRY_CONAN()
    elseif(MODE STREQUAL "CPM")
        TULA_Clipp_TRY_CPM()
    elseif(MODE STREQUAL "SYSTEM")
        TULA_Clipp_TRY_SYSTEM()
    else()
        message(FATAL_ERROR "Invalid MODE for Clipp: ${MODE}")
    endif()
    
    # Create wrapper
    TULA_Clipp_CREATE_WRAPPER()
    verbose_message("tula::Clipp ready")
endfunction()

#[=======================================================================[
@brief Try to find Clipp via Conan
]=======================================================================]
function(TULA_Clipp_TRY_CONAN)
    tula_try_conan_header_only(Clipp clipp::clipp clipp)
    set(TULA_Clipp_CONAN_SUCCESS ${TULA_Clipp_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Clipp via CPM
]=======================================================================]
function(TULA_Clipp_TRY_CPM)
    if(NOT DEFINED CLIPP_CPM_GITHUB_REPO)
        message(FATAL_ERROR "CLIPP_CPM_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    tula_try_cpm(Clipp clipp::clipp
        NAME clipp
        GITHUB_REPOSITORY "${CLIPP_CPM_GITHUB_REPO}"
        GIT_TAG "${CLIPP_CPM_GIT_TAG}"
        OPTIONS
            "CLIPP_BUILD_EXAMPLES OFF"
            "CLIPP_BUILD_TESTS OFF"
    )
    
    # CPM doesn't create the target automatically for header-only
    if(NOT TARGET clipp::clipp AND clipp_ADDED)
        add_library(clipp INTERFACE)
        target_include_directories(clipp INTERFACE ${clipp_SOURCE_DIR}/include)
        add_library(clipp::clipp ALIAS clipp)
        set(TULA_Clipp_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        set(TULA_Clipp_CPM_SUCCESS ${TULA_Clipp_CPM_SUCCESS} PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Try to find Clipp via system find_package
]=======================================================================]
function(TULA_Clipp_TRY_SYSTEM)
    tula_try_system(Clipp clipp::clipp Clipp)
    set(TULA_Clipp_SYSTEM_SUCCESS ${TULA_Clipp_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Clipp wrapper target
]=======================================================================]
function(TULA_Clipp_CREATE_WRAPPER)
    tula_create_wrapper(Clipp clipp::clipp)
    verbose_message("Created tula::Clipp wrapper")
endfunction()
