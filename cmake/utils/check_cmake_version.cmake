include_guard(GLOBAL)

# Check minimum CMake version requirement
# Usage: check_cmake_version(<minimum_version> [MODULE_NAME <name>])

function(check_cmake_version MINIMUM_VERSION)
    set(options "")
    set(oneValueArgs MODULE_NAME)
    set(multiValueArgs "")
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    if(${CMAKE_VERSION} VERSION_LESS ${MINIMUM_VERSION})
        if(ARG_MODULE_NAME)
            set(MODULE_MSG " (required by ${ARG_MODULE_NAME})")
        else()
            set(MODULE_MSG "")
        endif()
        
        message(FATAL_ERROR "CMake ${MINIMUM_VERSION}+ required${MODULE_MSG}, but you have ${CMAKE_VERSION}")
    endif()
endfunction()
