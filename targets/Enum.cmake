# Enum.cmake - Enum utilities (meta_enum + bitmask metapackage)
#
# Defines: tula_Enum_add_cpm()
# Called by: tula_deps_add(deps Enum) from tula_deps.cmake
# Note: CPM only - combines meta_enum + bitmask

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Fetch Enum components via CPM (only supported mode)
]=======================================================================]
function(tula_Enum_add_cpm)
    if(NOT DEFINED TULA_ENUM_META_ENUM_CPM_GITHUB_REPO)
        return()
    endif()
    
    # Fetch meta_enum (header-only, DOWNLOAD_ONLY to avoid recursive project() during toolchain)
    verbose_message("Fetching meta_enum...")
    CPMAddPackage(
        NAME meta_enum
        GITHUB_REPOSITORY "${TULA_ENUM_META_ENUM_CPM_GITHUB_REPO}"
        GIT_TAG "${TULA_ENUM_META_ENUM_CPM_GIT_TAG}"
        DOWNLOAD_ONLY YES
    )

    # Fix typo in Jerry-Ma/meta_enum: 'emta_enum' should be 'meta_enum' in Color_meta_from_value
    # This is applied every configure run so it works even when the CPM cache already exists.
    if(DEFINED meta_enum_SOURCE_DIR)
        set(_meta_enum_header "${meta_enum_SOURCE_DIR}/include/meta_enum/meta_enum.hpp")
        if(EXISTS "${_meta_enum_header}")
            file(READ "${_meta_enum_header}" _meta_enum_content)
            if("${_meta_enum_content}" MATCHES "emta_enum::MetaEnumMember")
                string(REPLACE "emta_enum::MetaEnumMember" "meta_enum::MetaEnumMember"
                    _meta_enum_content "${_meta_enum_content}")
                file(WRITE "${_meta_enum_header}" "${_meta_enum_content}")
                verbose_message("Patched meta_enum.hpp: fixed emta_enum typo")
            endif()
        endif()
    endif()

    if(NOT TARGET meta_enum::meta_enum AND meta_enum_ADDED)
        add_library(meta_enum INTERFACE)
        # meta_enum.hpp may be in root or include/; add both so either path works
        # meta_enum.hpp may be at root, include/, or include/meta_enum/
        target_include_directories(meta_enum INTERFACE
            "${meta_enum_SOURCE_DIR}"
            "${meta_enum_SOURCE_DIR}/include"
            "${meta_enum_SOURCE_DIR}/include/meta_enum"
        )
        add_library(meta_enum::meta_enum ALIAS meta_enum)
    endif()
    
    # Fetch bitmask
    verbose_message("Fetching bitmask...")
    CPMAddPackage(
        NAME bitmask
        GITHUB_REPOSITORY Jerry-Ma/bitmask
        GIT_TAG master
        DOWNLOAD_ONLY YES
        PATCH_COMMAND sed -i.bak "s/cmake_minimum_required(VERSION 2\\.6)/cmake_minimum_required(VERSION 3.23)/" <SOURCE_DIR>/CMakeLists.txt || true
    )
    
    if(NOT TARGET bitmask::bitmask AND bitmask_ADDED)
        add_library(bitmask INTERFACE)
        # bitmask header may be at include/bitmask.hpp (flat) or include/bitmask/bitmask.hpp;
        # add both paths so #include <bitmask.hpp> works in either layout
        target_include_directories(bitmask INTERFACE
            "${bitmask_SOURCE_DIR}/include"
            "${bitmask_SOURCE_DIR}/include/bitmask"
        )
        add_library(bitmask::bitmask ALIAS bitmask)
    endif()
    
    if(NOT TARGET meta_enum::meta_enum OR NOT TARGET bitmask::bitmask)
        return()
    endif()
    _tula_Enum_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::Enum metapackage wrapper
]=======================================================================]
function(_tula_Enum_create_wrapper)
    if(TARGET tula_Enum)
        return()
    endif()
    
    if(NOT TARGET meta_enum::meta_enum OR NOT TARGET bitmask::bitmask)
        message(FATAL_ERROR "Cannot create Enum metapackage: components missing")
    endif()
    
    add_library(tula_Enum INTERFACE)
    target_link_libraries(tula_Enum INTERFACE 
        meta_enum::meta_enum 
        bitmask::bitmask
    )
    add_library(tula::Enum ALIAS tula_Enum)
    
    verbose_message("Created tula::Enum metapackage")
endfunction()
