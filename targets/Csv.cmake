# Csv.cmake - CSV parser library (header-only)
#
# Defines: tula_Csv_add_cpm()
# Called by: tula_deps_add(deps Csv) from tula_deps.cmake
# Note: CPM only - no Conan or system support for this header-only library

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Fetch Csv via CPM (only supported mode)
]=======================================================================]
function(tula_Csv_add_cpm)
    if(NOT DEFINED TULA_CSV_CPM_GITHUB_REPO)
        return()
    endif()
    
    # Use DOWNLOAD_ONLY to avoid add_subdirectory on csv-parser (which has project(LANGUAGES CXX))
    CPMAddPackage(
        NAME csv_parser
        GITHUB_REPOSITORY "${TULA_CSV_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_CSV_CPM_GIT_TAG}"
        DOWNLOAD_ONLY YES
    )

    # Manually create the target (header-only; try single_include then include/)
    if(csv_parser_ADDED AND NOT TARGET csv_parser::csv_parser)
        add_library(csv_parser_interface INTERFACE)
        if(EXISTS "${csv_parser_SOURCE_DIR}/single_include")
            target_include_directories(csv_parser_interface INTERFACE "${csv_parser_SOURCE_DIR}/single_include")
        else()
            target_include_directories(csv_parser_interface INTERFACE "${csv_parser_SOURCE_DIR}/include")
        endif()
        add_library(csv_parser::csv_parser ALIAS csv_parser_interface)
        verbose_message("Fetched csv_parser via CPM and created target")
    endif()
    
    if(NOT TARGET csv_parser::csv_parser)
        return()
    endif()
    _tula_Csv_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::Csv wrapper target
]=======================================================================]
function(_tula_Csv_create_wrapper)
    if(TARGET tula_Csv)
        return()
    endif()
    
    if(NOT TARGET csv_parser::csv_parser)
        message(FATAL_ERROR "Cannot create wrapper: csv_parser::csv_parser target does not exist")
    endif()
    
    make_tula_target(Csv csv_parser::csv_parser)
    
    verbose_message("Created tula::Csv wrapper")
endfunction()
