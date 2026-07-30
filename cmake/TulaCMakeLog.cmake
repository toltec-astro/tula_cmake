include_guard(GLOBAL)

function(tula_cmake_log level)
    string(TOUPPER "${level}" level)
    set(
        valid_levels
        STATUS
        VERBOSE
        DEBUG
        TRACE
        NOTICE
        WARNING
        AUTHOR_WARNING
        DEPRECATION
        SEND_ERROR
        FATAL_ERROR
    )
    if(NOT level IN_LIST valid_levels)
        message(FATAL_ERROR "Unknown TulaCMake log level: ${level}")
    endif()

    list(APPEND CMAKE_MESSAGE_CONTEXT "${PROJECT_NAME}")
    message(${level} "${ARGN}")
endfunction()
