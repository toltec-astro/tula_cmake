include_guard(GLOBAL)
include(verbose_message)

find_package(Python3 REQUIRED COMPONENTS Development Interpreter NumPy)

add_library(python3_and_numpy INTERFACE)
target_link_libraries(python3_and_numpy INTERFACE
    Python3::Python
    Python3::NumPy
    )
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(Python3::Python)
    print_target_properties(Python3::NumPy)
endif()
add_library(tula::python3 ALIAS python3_and_numpy)
