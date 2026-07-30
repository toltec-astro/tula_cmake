cmake_minimum_required(VERSION 3.25)

project(
    TulaDownstream
    VERSION 0.1.0
    DESCRIPTION "Minimal installed consumer of TulaBoilerplate"
    LANGUAGES CXX
)

include(GNUInstallDirs)

find_package(TulaCMake 3 CONFIG REQUIRED)
find_package(TulaBoilerplate CONFIG REQUIRED)
find_package(TulaLibB CONFIG REQUIRED)

add_executable(tula_downstream src/main.cpp)
tula_cmake_target_defaults(TARGET tula_downstream WARNINGS)
target_link_libraries(
    tula_downstream
    PRIVATE
        tula_boilerplate::tula_boilerplate
        tula::lib_b
)

install(TARGETS tula_downstream RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
