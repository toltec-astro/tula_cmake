# Grppi.cmake - Generic and Reusable Parallel Pattern Interface
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Setup Grppi package (CPM only, requires perflibs and Enum dependencies)
@param MODE Resolution mode (AUTO, CPM)
]=======================================================================]
function(tula_setup_Grppi MODE)
    verbose_message("Setting up tula::Grppi (mode=${MODE})")
    
    if(TARGET tula::Grppi)
        verbose_message("tula::Grppi already exists")
        return()
    endif()
    
    # Ensure perflibs is available (for OpenMP/threading)
    if(NOT TARGET tula::perflibs)
        verbose_message("Grppi requires perflibs, loading it first...")
        tula_deps_add(_perflibs_dep perflibs)
    endif()
    
    # Ensure Enum is available
    if(NOT TARGET tula::Enum)
        verbose_message("Grppi requires Enum, loading it first...")
        tula_deps_add(_enum_dep Enum)
    endif()
    
    if(MODE STREQUAL "AUTO" OR MODE STREQUAL "CPM")
        TULA_Grppi_TRY_CPM()
    elseif(MODE STREQUAL "CONAN" OR MODE STREQUAL "SYSTEM")
        message(FATAL_ERROR "Grppi does not support ${MODE} mode (header-only, CPM only)")
    else()
        message(FATAL_ERROR "Invalid MODE for Grppi: ${MODE}")
    endif()
    
    # Create wrapper
    TULA_Grppi_CREATE_WRAPPER()
    verbose_message("tula::Grppi ready")
endfunction()

#[=======================================================================[
@brief Try to fetch Grppi via CPM
]=======================================================================]
function(TULA_Grppi_TRY_CPM)
    if(NOT DEFINED GRPPI_CPM_GITHUB_REPO)
        message(FATAL_ERROR "GRPPI_CPM_GITHUB_REPO not set. Check toolchain configuration.")
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
    
    tula_try_cpm(Grppi grppi::grppi
        NAME grppi
        GITHUB_REPOSITORY "${GRPPI_CPM_GITHUB_REPO}"
        GIT_TAG "${GRPPI_CPM_GIT_TAG}"
    )
    
    # CPM doesn't create the target automatically for header-only
    if(NOT TARGET grppi::grppi AND grppi_ADDED)
        add_library(grppi INTERFACE)
        target_include_directories(grppi SYSTEM INTERFACE ${grppi_SOURCE_DIR}/include)
        
        # Add OpenMP support if available
        find_package(OpenMP QUIET)
        if(OpenMP_FOUND)
            target_compile_definitions(grppi INTERFACE GRPPI_OMP)
        endif()
        
        # Require threads
        find_package(Threads REQUIRED)
        if(NOT Threads_FOUND)
            message(FATAL_ERROR "Grppi requires threads library")
        endif()
        
        # Link perflibs for threading/OpenMP support
        target_link_libraries(grppi INTERFACE tula::perflibs)
        
        add_library(grppi::grppi ALIAS grppi)
        set(TULA_Grppi_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        set(TULA_Grppi_CPM_SUCCESS ${TULA_Grppi_CPM_SUCCESS} PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Create tula::Grppi wrapper target
]=======================================================================]
function(TULA_Grppi_CREATE_WRAPPER)
    tula_create_wrapper(Grppi grppi::grppi tula::perflibs tula::Enum)
    verbose_message("Created tula::Grppi wrapper")
endfunction()
