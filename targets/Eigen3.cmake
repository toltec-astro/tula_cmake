# Eigen3.cmake - Eigen linear algebra library
#
# Defines: tula_Eigen3_add_conan(), tula_Eigen3_add_cpm(), tula_Eigen3_add_system()
# Called by: tula_deps_add(deps Eigen3) from tula_deps.cmake

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_deps_callbacks.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Load Eigen3 from Conan (header-only, uses CMAKE_INCLUDE_PATH)
]=======================================================================]
function(tula_Eigen3_add_conan)
    tula_try_conan_header_only(Eigen3 Eigen3::Eigen)
    if(NOT TULA_Eigen3_CONAN_SUCCESS)
        return()
    endif()
    _tula_Eigen3_create_wrapper()
endfunction()

#[=======================================================================[
@brief Fetch Eigen3 via CPM
]=======================================================================]
function(tula_Eigen3_add_cpm)
    if(NOT DEFINED TULA_EIGEN3_CPM_URL)
        return()
    endif()
    
    tula_try_cpm(Eigen3 Eigen3::Eigen
        NAME Eigen3
        URL "${TULA_EIGEN3_CPM_URL}"
        OPTIONS ${TULA_EIGEN3_CPM_OPTIONS}
    )
    if(NOT TULA_Eigen3_CPM_SUCCESS)
        return()
    endif()
    _tula_Eigen3_create_wrapper()
endfunction()

#[=======================================================================[
@brief Find Eigen3 via system find_package
]=======================================================================]
function(tula_Eigen3_add_system)
    tula_try_system(Eigen3 Eigen3::Eigen)
    if(NOT TULA_Eigen3_SYSTEM_SUCCESS)
        return()
    endif()
    _tula_Eigen3_create_wrapper()
endfunction()

#[=======================================================================[
@brief Create tula::Eigen3 wrapper target with optional MKL/threading support
]=======================================================================]
function(_tula_Eigen3_create_wrapper)
    if(TARGET tula_Eigen3)
        return()
    endif()
    
    if(NOT TARGET Eigen3::Eigen)
        message(FATAL_ERROR "Cannot create wrapper: Eigen3::Eigen target does not exist")
    endif()
    
    option(USE_EIGEN3_WITH_MKL "Use Intel MKL library if installed" ON)
    option(USE_EIGEN3_MULTITHREADING "Enable multithreading inside Eigen3" ON)
    
    set(eigen3_libs Eigen3::Eigen)
    set(eigen3_defs "")
    
    if(USE_EIGEN3_MULTITHREADING OR USE_EIGEN3_WITH_MKL)
        # Conditional dependency on perflibs
        if(TARGET tula::perflibs)
            list(APPEND eigen3_libs tula::perflibs)
            
            # Check MKL availability
            if(NOT MKL_FOUND AND USE_EIGEN3_WITH_MKL)
                message(WARNING 
                    "USE_EIGEN3_WITH_MKL=ON but MKL is not found. Setting to OFF.\n"
                    "To enable MKL, set USE_INTEL_ONEAPI=ON")
                set_property(CACHE USE_EIGEN3_WITH_MKL PROPERTY VALUE OFF)
            endif()
            
            if(USE_EIGEN3_WITH_MKL)
                list(APPEND eigen3_defs EIGEN_USE_MKL_ALL)
            endif()
            
            if(NOT USE_EIGEN3_MULTITHREADING)
                list(APPEND eigen3_defs EIGEN_DONT_PARALLELIZE)
            endif()
        else()
            verbose_message("perflibs not available, skipping MKL/threading support")
        endif()
    endif()
    
    make_tula_target(Eigen3 ${eigen3_libs})
    
    if(eigen3_defs)
        target_compile_definitions(tula_Eigen3 INTERFACE ${eigen3_defs})
        foreach(def ${eigen3_defs})
            verbose_message("Eigen3 defined: ${def}")
        endforeach()
    endif()
    
    verbose_message("Created tula::Eigen3 wrapper")
endfunction()