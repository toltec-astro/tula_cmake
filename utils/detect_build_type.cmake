include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/verbose_message.cmake)

set(default_build_type "RelWithDebInfo")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    verbose_message("No build type specified, default to ${default_build_type}")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY VALUE "${default_build_type}")
endif()
