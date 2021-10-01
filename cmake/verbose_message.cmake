include_guard(GLOBAL)

option(VERBOSE_MESSAGE "Print additional messages from CMake" ON)

function(verbose_message msg)
    if(${VERBOSE_MESSAGE})
        get_filename_component(module_name ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
        if (module_name STREQUAL "CMakeLists")
            set(module_name "verbose")
        endif()
        message(STATUS "(${module_name}) " ${msg})
    endif()
endfunction()
