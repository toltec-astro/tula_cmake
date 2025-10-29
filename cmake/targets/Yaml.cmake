# Yaml.cmake - YAML configuration file parsing support
# Single-include workflow with callback-based target creation

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_Yaml)
    message(STATUS "(Yaml) Target tula_Yaml already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Create yaml-cpp::yaml-cpp target from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_yaml_create_conan_target)
    if(TARGET yaml-cpp::yaml-cpp)
        return()  # Already created
    endif()
    
    # Conan provides include path via CMAKE_INCLUDE_PATH
    set(YAML_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "yaml-cpp")
            set(YAML_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT YAML_INCLUDE_DIR)
        message(STATUS "  ✗ yaml-cpp not found in CMAKE_INCLUDE_PATH, will try next mode")
        return()
    endif()
    
    # Create INTERFACE target
    add_library(yaml-cpp::yaml-cpp INTERFACE IMPORTED GLOBAL)
    target_include_directories(yaml-cpp::yaml-cpp INTERFACE "${YAML_INCLUDE_DIR}")
    message(STATUS "  ✓ Created yaml-cpp::yaml-cpp target from Conan: ${YAML_INCLUDE_DIR}")
endfunction()

# Find or fetch yaml-cpp
# Note: Using master branch instead of 0.8.0 tag because the tag has CMake version issues.
# The master branch includes CMake 3.5 requirement fix (commit c9371de from Apr 29, 2025)
# and other improvements since 0.8.0 release (Aug 10, 2023)
tula_deps_register(yaml-cpp
    CONAN_NAME yaml-cpp
    CONAN_TARGET_CALLBACK _tula_yaml_create_conan_target
    CONAN_TARGET_NAME yaml-cpp::yaml-cpp
    CPM_GITHUB_REPOSITORY jbeder/yaml-cpp
    CPM_GIT_TAG master  # Using master branch - includes fixes since 0.8.0
    CPM_OPTIONS 
        "YAML_CPP_BUILD_CONTRIB OFF" 
        "YAML_CPP_BUILD_TOOLS OFF"
        "YAML_BUILD_SHARED_LIBS OFF"
    SYSTEM_NAME yaml-cpp
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::Yaml after dependency is resolved
function(_tula_yaml_create_wrapper)
    if(TARGET tula_Yaml)
        return()  # Already created
    endif()
    
    # Create tula interface library
    include(make_tula_target)
    make_tula_target(Yaml yaml-cpp::yaml-cpp)
    
    verbose_message("Yaml configured: tula::Yaml")
endfunction()

# If yaml-cpp already exists, create wrapper now
if(TARGET yaml-cpp::yaml-cpp OR TARGET yaml-cpp)
    _tula_yaml_create_wrapper()
endif()
