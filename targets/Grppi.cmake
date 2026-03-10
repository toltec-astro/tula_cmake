# Grppi.cmake - Generic and Reusable Parallel Pattern Interface
#
# Defines: tula_Grppi_add_cpm()
# Called by: tula_deps_add(deps Grppi) from tula_deps.cmake
# Note: CPM only - requires perflibs and Enum dependencies

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Fetch Grppi via CPM (only supported mode)
]=======================================================================]
function(tula_Grppi_add_cpm)
    if(NOT DEFINED TULA_GRPPI_CPM_GITHUB_REPO)
        return()
    endif()
    
    # Compiler version checks (from ref implementation)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.9.0)
            message(FATAL_ERROR "Clang version ${CMAKE_CXX_COMPILER_VERSION} not supported. Upgrade to 3.9 or above.")
        endif()
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 6.0)
            message(FATAL_ERROR "g++ version ${CMAKE_CXX_COMPILER_VERSION} not supported. Upgrade to 6.0 or above.")
        elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 7.0)
            # g++ 7 warns in non C++17 for over-aligned new otherwise
            add_compile_options(-faligned-new)
        endif()
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
        message(WARNING "Intel compiler is not currently supported for Grppi")
    endif()
    
    # Use DOWNLOAD_ONLY to avoid recursive project() call during toolchain phase
    CPMAddPackage(
        NAME grppi
        GITHUB_REPOSITORY "${TULA_GRPPI_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_GRPPI_CPM_GIT_TAG}"
        DOWNLOAD_ONLY YES
    )

    # Create the interface target manually (header-only library)
    if(NOT TARGET grppi::grppi AND grppi_ADDED)
        add_library(grppi INTERFACE)
        target_include_directories(grppi SYSTEM INTERFACE ${grppi_SOURCE_DIR}/include)
        
        # OpenMP/Threads detection requires languages to be enabled (not available in toolchain phase).
        # If perflibs is available, it handles OpenMP+Threads; otherwise defer to user.
        if(TARGET tula::perflibs)
            target_link_libraries(grppi INTERFACE tula::perflibs)
        elseif(CMAKE_CXX_COMPILER_LOADED)
            # Only attempt language-requiring find_package after project() is called
            find_package(OpenMP QUIET)
            if(OpenMP_FOUND)
                target_compile_definitions(grppi INTERFACE GRPPI_OMP)
            endif()
            find_package(Threads QUIET)
            if(Threads_FOUND)
                target_link_libraries(grppi INTERFACE Threads::Threads)
            endif()
        endif()
        
        add_library(grppi::grppi ALIAS grppi)
    endif()
    
    if(NOT TARGET grppi::grppi)
        return()
    endif()
    _tula_Grppi_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::Grppi wrapper target
]=======================================================================]
function(_tula_Grppi_create_wrapper)
    if(TARGET tula_Grppi)
        return()
    endif()
    
    if(NOT TARGET grppi::grppi)
        message(FATAL_ERROR "Cannot create wrapper: grppi::grppi target does not exist")
    endif()
    
    set(_deps grppi::grppi)
    
    if(TARGET tula::perflibs)
        list(APPEND _deps tula::perflibs)
    else()
        verbose_message("Grppi: tula::perflibs not found, OpenMP/Threads support unavailable")
    endif()

    if(TARGET tula::Enum)
        list(APPEND _deps tula::Enum)
    else()
        verbose_message("Grppi: tula::Enum not found, enum utilities unavailable")
    endif()
    
    make_tula_target(Grppi ${_deps})
    
    verbose_message("Created tula::Grppi wrapper")
endfunction()
