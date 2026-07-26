include_guard(GLOBAL)

function(tula_resolve_ceres_conan)
    if(TARGET tula::ceres)
        return()
    endif()
    if(NOT TARGET tula::eigen)
        message(FATAL_ERROR "ceres: required target tula::eigen is unavailable")
    endif()

    find_package(Ceres CONFIG REQUIRED)
    if(NOT TARGET Ceres::ceres)
        message(FATAL_ERROR "ceres: Ceres::ceres provider target is unavailable")
    endif()

    add_library(tula_ceres INTERFACE)
    target_link_libraries(tula_ceres INTERFACE Ceres::ceres tula::eigen)
    add_library(tula::ceres ALIAS tula_ceres)
endfunction()
