# Enum.cmake - Enum utilities (meta_enum + bitmask metapackage)
include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)

#[=======================================================================[
@brief Setup Enum metapackage (CPM only, combines meta_enum + bitmask)
@param MODE Resolution mode (AUTO, CPM)
]=======================================================================]
function(tula_setup_Enum MODE)
    verbose_message("Setting up tula::Enum metapackage (mode=${MODE})")
    
    if(TARGET tula::Enum)
        verbose_message("tula::Enum already exists")
        return()
    endif()
    
    if(MODE STREQUAL "AUTO" OR MODE STREQUAL "CPM")
        TULA_Enum_TRY_CPM()
    elseif(MODE STREQUAL "CONAN" OR MODE STREQUAL "SYSTEM")
        message(FATAL_ERROR "Enum does not support ${MODE} mode (header-only, CPM only)")
    else()
        message(FATAL_ERROR "Invalid MODE for Enum: ${MODE}")
    endif()
    
    # Create wrapper
    TULA_Enum_CREATE_WRAPPER()
    verbose_message("tula::Enum ready")
endfunction()

#[=======================================================================[
@brief Try to fetch Enum components via CPM
]=======================================================================]
function(TULA_Enum_TRY_CPM)
    if(NOT DEFINED ENUM_META_ENUM_CPM_GITHUB_REPO)
        message(FATAL_ERROR "ENUM_META_ENUM_CPM_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils/_ensure_cpm.cmake)
    
    # Fetch meta_enum
    verbose_message("Fetching meta_enum...")
    CPMAddPackage(
        NAME meta_enum
        GITHUB_REPOSITORY "${ENUM_META_ENUM_CPM_GITHUB_REPO}"
        GIT_TAG "${ENUM_META_ENUM_CPM_GIT_TAG}"
    )
    
    if(NOT TARGET meta_enum::meta_enum AND meta_enum_ADDED)
        add_library(meta_enum INTERFACE)
        target_include_directories(meta_enum INTERFACE ${meta_enum_SOURCE_DIR}/include)
        add_library(meta_enum::meta_enum ALIAS meta_enum)
    endif()
    
        # 2. Fetch bitmask
    message(VERBOSE "Fetching bitmask...")
    CPMAddPackage(
        NAME bitmask
        GITHUB_REPOSITORY Jerry-Ma/bitmask
        GIT_TAG master
        DOWNLOAD_ONLY YES
        PATCH_COMMAND sed -i.bak "s/cmake_minimum_required(VERSION 2\\.6)/cmake_minimum_required(VERSION 3.23)/" <SOURCE_DIR>/CMakeLists.txt || true
    )
    
    if(NOT TARGET bitmask::bitmask AND bitmask_ADDED)
        add_library(bitmask INTERFACE)
        target_include_directories(bitmask INTERFACE ${bitmask_SOURCE_DIR}/include)
        add_library(bitmask::bitmask ALIAS bitmask)
    endif()
    
    if(TARGET meta_enum::meta_enum AND TARGET bitmask::bitmask)
        verbose_message("Fetched meta_enum and bitmask via CPM")
        set(TULA_Enum_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        message(STATUS "CPM fetch failed for Enum components")
        set(TULA_Enum_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Create tula::Enum metapackage wrapper
]=======================================================================]
function(TULA_Enum_CREATE_WRAPPER)
    if(TARGET tula_Enum)
        return()
    endif()
    
    if(NOT TARGET meta_enum::meta_enum OR NOT TARGET bitmask::bitmask)
        message(FATAL_ERROR "Cannot create Enum metapackage: components missing")
    endif()
    
    # Create metapackage combining both components
    add_library(tula_Enum INTERFACE)
    target_link_libraries(tula_Enum INTERFACE 
        meta_enum::meta_enum 
        bitmask::bitmask
    )
    add_library(tula::Enum ALIAS tula_Enum)
    
    verbose_message("Created tula::Enum metapackage")
endfunction()
