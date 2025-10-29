# Re2.cmake - Google RE2 regular expression library
# Single-include workflow with callback-based target creation
#
# Creates target: tula::Re2

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_Re2)
    message(STATUS "(Re2) Target tula_Re2 already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Create re2::re2 target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_re2_create_conan_target)
    if(TARGET re2::re2)
        return()  # Already created
    endif()
    
    set(RE2_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "re2")
            set(RE2_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT RE2_INCLUDE_DIR)
        message(STATUS "  ✗ re2 not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    add_library(re2::re2 INTERFACE IMPORTED GLOBAL)
    target_include_directories(re2::re2 INTERFACE "${RE2_INCLUDE_DIR}")
    message(STATUS "  ✓ Created re2::re2 target from Conan: ${RE2_INCLUDE_DIR}")
endfunction()

# RE2 - Fast, safe alternative to backtracking regex engines
# Preferred over std::regex for performance-critical applications
tula_deps_register(re2
    CONAN_NAME re2
    CONAN_TARGET_CALLBACK _tula_re2_create_conan_target
    CONAN_TARGET_NAME re2::re2
    CPM_GITHUB_REPOSITORY google/re2
    CPM_GIT_TAG 2024-07-02
    CPM_OPTIONS
        "RE2_BUILD_TESTING OFF"
        "BUILD_SHARED_LIBS OFF"
    SYSTEM_NAME re2
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::Re2 after dependency is resolved
function(_tula_re2_create_wrapper)
    if(TARGET tula_Re2)
        return()  # Already created
    endif()
    
    set(_re2_libs "")

    if(TARGET re2::re2)
        list(APPEND _re2_libs re2::re2)
        verbose_message("RE2 configured with re2::re2 target")
    elseif(TARGET re2)
        list(APPEND _re2_libs re2)
        verbose_message("RE2 configured with re2 target")
    else()
        message(FATAL_ERROR "RE2 not found after dependency resolution")
    endif()

    # Create tula wrapper target
    include(make_tula_target)
    make_tula_target(Re2 ${_re2_libs})

    verbose_message("RE2 configured: tula::Re2")
endfunction()

# If re2 already exists, create wrapper now
if(TARGET re2::re2 OR TARGET re2)
    _tula_re2_create_wrapper()
endif()
