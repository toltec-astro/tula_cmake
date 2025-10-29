# Re2.cmake - Google RE2 regular expression library

include(_deps_callbacks)

# Skip if target already exists
if(TARGET tula_Re2)
    message(STATUS "(Re2) Target tula_Re2 already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Try to find re2 via Conan (uses CMakeDeps-generated config)
]=======================================================================]
function(TULA_Re2_TRY_CONAN)
    tula_try_conan_header_only(Re2 re2::re2)
    set(TULA_Re2_CONAN_SUCCESS ${TULA_Re2_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch re2 via CPM
]=======================================================================]
function(TULA_Re2_TRY_CPM)
    tula_try_cpm(Re2 re2::re2
        NAME re2
        GITHUB_REPOSITORY google/re2
        GIT_TAG 2024-07-02
        OPTIONS
            "RE2_BUILD_TESTING OFF"
            "BUILD_SHARED_LIBS OFF"
    )
    set(TULA_Re2_CPM_SUCCESS ${TULA_Re2_CPM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find re2 via system find_package
]=======================================================================]
function(TULA_Re2_TRY_SYSTEM)
    tula_try_system(Re2 re2::re2)
    set(TULA_Re2_SYSTEM_SUCCESS ${TULA_Re2_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Re2 wrapper target
]=======================================================================]
function(TULA_Re2_CREATE_WRAPPER)
    if(TARGET tula_Re2)
        return()  # Already created
    endif()
    
    if(NOT TARGET re2::re2)
        message(FATAL_ERROR "Cannot create wrapper: re2::re2 target does not exist")
    endif()
    
    include(make_tula_target)
    make_tula_target(Re2 re2::re2)
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        verbose_message("RE2 configured: tula::Re2")
    endif()
endfunction()

# Register re2 for tri-modal resolution
tula_deps_register(Re2)
