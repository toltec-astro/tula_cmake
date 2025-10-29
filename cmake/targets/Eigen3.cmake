# Eigen3.cmake - Eigen linear algebra library

include(_deps_callbacks)

# Skip if target already exists
if(TARGET tula_Eigen3)
    message(STATUS "(Eigen3) Target tula_Eigen3 already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Try to find Eigen3 via Conan (searches CMAKE_INCLUDE_PATH)
]=======================================================================]
function(TULA_Eigen3_TRY_CONAN)
    tula_try_conan_header_only(Eigen3 Eigen3::Eigen)
    set(TULA_Eigen3_CONAN_SUCCESS ${TULA_Eigen3_CONAN_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to fetch Eigen3 via CPM
]=======================================================================]
function(TULA_Eigen3_TRY_CPM)
    tula_try_cpm(Eigen3 Eigen3::Eigen
        NAME Eigen3
        URL "https://gitlab.com/libeigen/eigen/-/archive/3.4.1/eigen-3.4.1.tar.gz"
        OPTIONS
            "BUILD_TESTING OFF"
            "EIGEN_BUILD_DOC OFF"
            "EIGEN_BUILD_PKGCONFIG OFF"
            "EIGEN_BUILD_BTL OFF"
            "EIGEN_LEAVE_TEST_IN_ALL_TARGET OFF"
    )
    set(TULA_Eigen3_CPM_SUCCESS ${TULA_Eigen3_CPM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Try to find Eigen3 via system find_package
]=======================================================================]
function(TULA_Eigen3_TRY_SYSTEM)
    tula_try_system(Eigen3 Eigen3::Eigen)
    set(TULA_Eigen3_SYSTEM_SUCCESS ${TULA_Eigen3_SYSTEM_SUCCESS} PARENT_SCOPE)
endfunction()

#[=======================================================================[
@brief Create tula::Eigen3 wrapper target with optional MKL/threading support
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
        
        # Check MKL availability and warn user if requested but not found
        if(NOT MKL_FOUND AND USE_EIGEN3_WITH_MKL)
            message(WARNING "USE_EIGEN3_WITH_MKL=ON but MKL is not found. Setting to OFF. To enable, set USE_INTEL_ONEAPI=ON")
            set_property(CACHE USE_EIGEN3_WITH_MKL PROPERTY VALUE OFF)
        endif()
        
        if(USE_EIGEN3_WITH_MKL)
            list(APPEND eigen3_defs EIGEN_USE_MKL_ALL)
        endif()
        
        if(NOT USE_EIGEN3_MULTITHREADING)
            list(APPEND eigen3_defs EIGEN_DONT_PARALLELIZE)
        endif()
    endif()
    
    # Create wrapper target
    include(make_tula_target)
    make_tula_target(Eigen3 ${eigen3_libs})
    target_compile_definitions(tula_Eigen3 INTERFACE ${eigen3_defs})
    
    if(VERBOSE_MESSAGE)
        include(verbose_message)
        foreach(def ${eigen3_defs})
            verbose_message("Eigen3 defined: ${def}")
        endforeach()
    endif()
endfunction()

# Register Eigen3 for tri-modal resolution
tula_deps_register(Eigen3)
