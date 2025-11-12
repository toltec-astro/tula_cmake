# Csv.cmake - CSV parser library (header-only)
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Setup Csv package (CPM only, header-only library)
@param MODE Resolution mode (AUTO, CPM)
]=======================================================================]
function(tula_setup_Csv MODE)
    verbose_message("Setting up tula::Csv (mode=${MODE})")
    
    if(TARGET tula::Csv)
        verbose_message("tula::Csv already exists")
        return()
    endif()
    
    if(MODE STREQUAL "AUTO" OR MODE STREQUAL "CPM")
        TULA_Csv_TRY_CPM()
    elseif(MODE STREQUAL "CONAN" OR MODE STREQUAL "SYSTEM")
        message(FATAL_ERROR "Csv does not support ${MODE} mode (header-only, CPM only)")
    else()
        message(FATAL_ERROR "Invalid MODE for Csv: ${MODE}")
    endif()
    
    # Create wrapper
    TULA_Csv_CREATE_WRAPPER()
    verbose_message("tula::Csv ready")
endfunction()

#[=======================================================================[
@brief Try to fetch Csv via CPM
]=======================================================================]
function(TULA_Csv_TRY_CPM)
    if(NOT DEFINED CSV_CPM_GITHUB_REPO)
        message(FATAL_ERROR "CSV_CPM_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    # Manually fetch with CPM since this library doesn't export targets
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/_ensure_cpm.cmake)
    CPMAddPackage(
        NAME csv_parser
        GITHUB_REPOSITORY "${CSV_CPM_GITHUB_REPO}"
        GIT_TAG "${CSV_CPM_GIT_TAG}"
    )
    
    # Manually create the target (library doesn't provide one)
    if(csv_parser_ADDED AND NOT TARGET csv_parser::csv_parser)
        add_library(csv_parser_interface INTERFACE)
        target_include_directories(csv_parser_interface INTERFACE ${csv_parser_SOURCE_DIR}/include)
        add_library(csv_parser::csv_parser ALIAS csv_parser_interface)
        verbose_message("    Fetched csv_parser via CPM and created target")
        set(TULA_Csv_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        verbose_message("    CPM fetch failed for Csv")
        set(TULA_Csv_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Create tula::Csv wrapper target
]=======================================================================]
function(TULA_Csv_CREATE_WRAPPER)
    tula_create_wrapper(Csv csv_parser::csv_parser)
    verbose_message("Created tula::Csv wrapper")
endfunction()
