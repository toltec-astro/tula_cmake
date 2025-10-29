# Eigen3.cmake - Eigen linear algebra library
# Uses naming convention: TULA_Eigen3_TRY_* functions

include(verbose_message)

# Skip if target already exists
if(TARGET tula_Eigen3)
    message(STATUS "(Eigen3) Target tula_Eigen3 already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Try to find Eigen3 via Conan (searches CMAKE_INCLUDE_PATH)
Sets TULA_Eigen3_CONAN_SUCCESS=TRUE on success
]=======================================================================]
function(TULA_Eigen3_TRY_CONAN)
    if(TARGET Eigen3::Eigen)
        set(TULA_Eigen3_CONAN_SUCCESS TRUE PARENT_SCOPE)
        return()
    endif()
    
    # Conan provides include path via CMAKE_INCLUDE_PATH (set by conan_toolchain.cmake)
    set(EIGEN3_INCLUDE_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "eigen")
            set(EIGEN3_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT EIGEN3_INCLUDE_DIR)
        message(STATUS "    Eigen3 not found in CMAKE_INCLUDE_PATH")
        set(TULA_Eigen3_CONAN_SUCCESS FALSE PARENT_SCOPE)
        return()
    endif()
    
    # Create INTERFACE target
    add_library(Eigen3::Eigen INTERFACE IMPORTED GLOBAL)
    target_include_directories(Eigen3::Eigen INTERFACE "${EIGEN3_INCLUDE_DIR}")
    message(STATUS "    Created Eigen3::Eigen from Conan: ${EIGEN3_INCLUDE_DIR}")
    set(TULA_Eigen3_CONAN_SUCCESS TRUE PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Eigen3 via CPM
Sets TULA_Eigen3_CPM_SUCCESS=TRUE on success
]=======================================================================]
function(TULA_Eigen3_TRY_CPM)
    if(TARGET Eigen3::Eigen)
        set(TULA_Eigen3_CPM_SUCCESS TRUE PARENT_SCOPE)
        return()
    endif()
    
    # Load CPM if not already available
    if(NOT COMMAND CPMAddPackage)
        set(CPM_DOWNLOAD_VERSION 0.40.0)
        set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
        
        if(NOT EXISTS "${CPM_DOWNLOAD_LOCATION}")
            message(STATUS "    Downloading CPM.cmake v${CPM_DOWNLOAD_VERSION}...")
            file(DOWNLOAD
                https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
                ${CPM_DOWNLOAD_LOCATION}
                EXPECTED_HASH SHA256=7b354f3a5976c4626c876850c93944e52c83ec59a159ae5de5be7983f0e17a2a
            )
        endif()
        
        include(${CPM_DOWNLOAD_LOCATION})
    endif()
    
    CPMAddPackage(
        NAME Eigen3
        URL "https://gitlab.com/libeigen/eigen/-/archive/3.4.1/eigen-3.4.1.tar.gz"
        OPTIONS
            "EIGEN_BUILD_DOC OFF"
            "EIGEN_BUILD_PKGCONFIG OFF"
            "BUILD_TESTING OFF"
    )
    
    if(Eigen3_ADDED OR TARGET Eigen3::Eigen)
        message(STATUS "    Fetched Eigen3 via CPM")
        set(TULA_Eigen3_CPM_SUCCESS TRUE PARENT_SCOPE)
    else()
        message(STATUS "    CPM fetch failed for Eigen3")
        set(TULA_Eigen3_CPM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Try to find Eigen3 via system find_package
Sets TULA_Eigen3_SYSTEM_SUCCESS=TRUE on success
]=======================================================================]
function(TULA_Eigen3_TRY_SYSTEM)
    if(TARGET Eigen3::Eigen)
        set(TULA_Eigen3_SYSTEM_SUCCESS TRUE PARENT_SCOPE)
        return()
    endif()
    
    find_package(Eigen3 CONFIG QUIET)
    
    if(TARGET Eigen3::Eigen)
        message(STATUS "    Found Eigen3 via system find_package")
        set(TULA_Eigen3_SYSTEM_SUCCESS TRUE PARENT_SCOPE)
    else()
        message(STATUS "    System find_package failed for Eigen3")
        set(TULA_Eigen3_SYSTEM_SUCCESS FALSE PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[
@brief Create tula::Eigen3 wrapper target with optional MKL/threading support
Called after successful target creation
]=======================================================================]
function(TULA_Eigen3_CREATE_WRAPPER)
    if(TARGET tula_Eigen3)
        return()  # Already created
    endif()
    
    if(NOT TARGET Eigen3::Eigen)
        message(FATAL_ERROR "Cannot create wrapper: Eigen3::Eigen target does not exist")
    endif()
    
    # Optional MKL and multithreading support
    option(USE_EIGEN3_WITH_MKL "Use Intel MKL library if installed" ON)
    option(USE_EIGEN3_MULTITHREADING "Enable multithreading inside Eigen3" ON)
    
    set(eigen3_libs Eigen3::Eigen)
    set(eigen3_defs "")
    
    if(USE_EIGEN3_MULTITHREADING OR USE_EIGEN3_WITH_MKL)
        include(perflibs)
        list(APPEND eigen3_libs tula::perflibs)
        
        if(USE_EIGEN3_WITH_MKL AND MKL_FOUND)
            list(APPEND eigen3_defs EIGEN_USE_MKL_ALL)
        endif()
        
        if(NOT USE_EIGEN3_MULTITHREADING)
            list(APPEND eigen3_defs EIGEN_DONT_PARALLELIZE)
        endif()
    endif()
    
    # Create unified target
    include(make_tula_target)
    make_tula_target(Eigen3 ${eigen3_libs})
    target_compile_definitions(tula_Eigen3 INTERFACE ${eigen3_defs})
    
    if(VERBOSE_MESSAGE)
        foreach(def ${eigen3_defs})
            verbose_message("Eigen3 defined: ${def}")
        endforeach()
    endif()
endfunction()

# Register Eigen3 for tri-modal resolution
tula_deps_register(Eigen3)
