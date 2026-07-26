include_guard(GLOBAL)

function(tula_resolve_boost_conan)
    if(TARGET tula::boost)
        return()
    endif()

    find_package(Boost CONFIG REQUIRED)
    if(NOT TARGET Boost::headers)
        message(FATAL_ERROR "boost: Boost::headers provider target is unavailable")
    endif()

    add_library(tula_boost INTERFACE)
    target_link_libraries(tula_boost INTERFACE Boost::headers)
    add_library(tula::boost ALIAS tula_boost)
endfunction()
