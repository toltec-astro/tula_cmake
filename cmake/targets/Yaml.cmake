# Yaml.cmake - YAML configuration file parsing support (yaml-cpp library)

include(_deps_callbacks)

# Skip if target already exists
if(TARGET tula_Yaml)
    message(STATUS "(Yaml) Target tula_Yaml already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Try to find yaml-cpp via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_Yaml_TRY_CONAN)
    tula_try_conan_header_only(Yaml yaml-cpp::yaml-cpp yaml-cpp)
    set(TULA_Yaml_CONAN_SUCCESS ${TULA_Yaml_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch yaml-cpp via CPM
]=======================================================================]
function(TULA_Yaml_TRY_CPM)
    tula_try_cpm(Yaml yaml-cpp::yaml-cpp
        NAME yaml-cpp
        GITHUB_REPOSITORY jbeder/yaml-cpp
        GIT_TAG master
        OPTIONS
            "YAML_CPP_BUILD_CONTRIB OFF"
            "YAML_CPP_BUILD_TOOLS OFF"
            "YAML_CPP_BUILD_TESTS OFF"
            "YAML_CPP_INSTALL OFF"
            "YAML_BUILD_SHARED_LIBS OFF"
            "YAML_MSVC_SHARED_RT OFF"
    )
    set(TULA_Yaml_CPM_SUCCESS ${TULA_Yaml_CPM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find yaml-cpp via system find_package
]=======================================================================]
function(TULA_Yaml_TRY_SYSTEM)
    tula_try_system(Yaml yaml-cpp::yaml-cpp yaml-cpp)
    set(TULA_Yaml_SYSTEM_SUCCESS ${TULA_Yaml_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Yaml wrapper target
]=======================================================================]
function(TULA_Yaml_CREATE_WRAPPER)
    if(TARGET tula_Yaml)
        return()  # Already created
    endif()
    
    if(NOT TARGET yaml-cpp::yaml-cpp)
        message(FATAL_ERROR "Cannot create wrapper: yaml-cpp::yaml-cpp target does not exist")
    endif()
    
    # Create wrapper target
    include(make_tula_target)
    make_tula_target(Yaml yaml-cpp::yaml-cpp)
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        verbose_message("Yaml configured: tula::Yaml")
    endif()
endfunction()

# Register Yaml for tri-modal resolution
tula_deps_register(Yaml)
