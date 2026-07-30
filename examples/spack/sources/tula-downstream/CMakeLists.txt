cmake_minimum_required(VERSION 3.25)

project(tula_downstream VERSION 0.1.0 LANGUAGES CXX)

find_package(TulaBoilerplate CONFIG REQUIRED)
find_package(TulaLibB CONFIG REQUIRED)

add_executable(tula_downstream src/main.cpp)
target_compile_features(tula_downstream PRIVATE cxx_std_23)
target_link_libraries(
    tula_downstream
    PRIVATE
        tula::boilerplate
        tula::lib_b
)

install(TARGETS tula_downstream RUNTIME DESTINATION bin)

