include_guard(GLOBAL)

include(verbose_message)
include(print_properties)

function(make_tula_target name libs)
    if (VERBOSE_MESSAGE)
        foreach (lib ${libs})
            print_target_properties(${lib})
        endforeach()
    endif()

    add_library(tula_${name} INTERFACE)
    target_link_libraries(tula_${name} INTERFACE ${libs})
    if (VERBOSE_MESSAGE)
        print_target_properties(tula_${name})
    endif()
    add_library(tula::${name} ALIAS tula_${name})
endfunction()
