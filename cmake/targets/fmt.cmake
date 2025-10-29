# fmt.cmake - Modern C++ formatting library
# Single-include workflow with callback-based target creation

include(verbose_message)

# Skip if target already exists
if(TARGET tula_fmt)
    message(STATUS "(fmt) Target tula_fmt already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Create fmt::fmt target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_fmt_create_conan_target)
    if(TARGET fmt::fmt)
        return()  # Already created
    endif()
    
    # Conan provides include path via CMAKE_INCLUDE_PATH (set by conan_toolchain.cmake)
    # Search for fmt directory in CMAKE_INCLUDE_PATH
    set(FMT_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "fmt")
            set(FMT_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT FMT_INCLUDE_DIR)
        # Don't fail - allow fallback to other modes
        message(STATUS "  ✗ fmt not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target
    add_library(fmt::fmt INTERFACE IMPORTED GLOBAL)
    target_include_directories(fmt::fmt INTERFACE "${FMT_INCLUDE_DIR}")
    message(STATUS "  ✓ Created fmt::fmt target from Conan: ${FMT_INCLUDE_DIR}")
endfunction()

# Register dependency with callback for CONAN mode
tula_deps_register(fmt
    CONAN_NAME fmt
    CONAN_TARGET_CALLBACK _tula_fmt_create_conan_target
    CONAN_TARGET_NAME fmt::fmt
    CPM_GITHUB_REPOSITORY fmtlib/fmt
    CPM_GIT_TAG master
    CPM_OPTIONS "FMT_TEST OFF" "FMT_DOC OFF" "FMT_INSTALL ON"
    SYSTEM_NAME fmt
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::fmt after dependency is resolved
function(_tula_fmt_create_wrapper)
    if(TARGET tula_fmt)
        return()  # Already created
    endif()
    
    # Create unified target
    include(make_tula_target)
    make_tula_target(fmt fmt::fmt)
    
    verbose_message("fmt configured: tula::fmt")
endfunction()

# If fmt::fmt already exists (e.g., from system), create wrapper now
if(TARGET fmt::fmt OR TARGET fmt)
    _tula_fmt_create_wrapper()
endif()
