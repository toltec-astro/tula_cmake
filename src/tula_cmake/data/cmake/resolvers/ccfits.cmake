include_guard(GLOBAL)

function(tula_resolve_ccfits_conan)
    if(TARGET tula::ccfits)
        return()
    endif()

    find_package(ccfits CONFIG REQUIRED)
    if(NOT TARGET ccfits::ccfits)
        message(FATAL_ERROR "ccfits: ccfits::ccfits provider target is unavailable")
    endif()

    add_library(tula_ccfits INTERFACE)
    target_link_libraries(tula_ccfits INTERFACE ccfits::ccfits)
    add_library(tula::ccfits ALIAS tula_ccfits)
endfunction()
