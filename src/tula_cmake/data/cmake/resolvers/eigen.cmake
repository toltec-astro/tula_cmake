include_guard(GLOBAL)

include(TulaCPM)

function(_tula_eigen_cpm)
    tula_load_cpm()
    CPMAddPackage(
        NAME eigen
        URL "${TULA_FEATURE_eigen_URL}"
        URL_HASH "SHA256=${TULA_FEATURE_eigen_SHA256}"
        OPTIONS
            "BUILD_TESTING OFF"
            "EIGEN_BUILD_BTL OFF"
            "EIGEN_BUILD_DOC OFF"
            "EIGEN_BUILD_PKGCONFIG OFF"
            "EIGEN_LEAVE_TEST_IN_ALL_TARGET OFF"
    )
endfunction()

function(_tula_eigen_installed)
    find_package(Eigen3 3.4 CONFIG REQUIRED NO_MODULE)
endfunction()

function(_tula_eigen_finalize)
    if(TARGET tula::eigen)
        return()
    endif()
    if(NOT TARGET Eigen3::Eigen)
        message(FATAL_ERROR "eigen: Eigen3::Eigen provider target is unavailable")
    endif()
    if(NOT TARGET tula::perflibs)
        message(FATAL_ERROR "eigen: required target tula::perflibs is unavailable")
    endif()

    add_library(tula_eigen INTERFACE)
    target_link_libraries(tula_eigen INTERFACE Eigen3::Eigen tula::perflibs)
    if(TULA_EIGEN_MULTITHREADING STREQUAL "disabled")
        target_compile_definitions(
            tula_eigen
            INTERFACE EIGEN_DONT_PARALLELIZE TULA_EIGEN_MULTITHREADING=0
        )
    elseif(TULA_EIGEN_MULTITHREADING STREQUAL "enabled")
        target_compile_definitions(
            tula_eigen
            INTERFACE TULA_EIGEN_MULTITHREADING=1
        )
    else()
        message(FATAL_ERROR
            "eigen: invalid multithreading mode ${TULA_EIGEN_MULTITHREADING}")
    endif()
    add_library(tula::eigen ALIAS tula_eigen)
endfunction()

function(tula_resolve_eigen_conan)
    _tula_eigen_installed()
    _tula_eigen_finalize()
endfunction()

function(tula_resolve_eigen_cpm)
    _tula_eigen_cpm()
    _tula_eigen_finalize()
endfunction()

function(tula_resolve_eigen_system)
    _tula_eigen_installed()
    _tula_eigen_finalize()
endfunction()
