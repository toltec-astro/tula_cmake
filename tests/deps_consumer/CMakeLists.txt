cmake_minimum_required(VERSION 3.25)

project(tula_deps_consumer LANGUAGES CXX)

find_package(TulaLogging CONFIG REQUIRED)
find_package(TulaYamlCpp CONFIG REQUIRED)
find_package(TulaCsvParser CONFIG REQUIRED)
find_package(TulaEigen3 CONFIG REQUIRED)

add_executable(tula_deps_consumer main.cpp)
target_compile_features(tula_deps_consumer PRIVATE cxx_std_23)
target_link_libraries(
    tula_deps_consumer
    PRIVATE
        tula_deps::logging
        tula_deps::yaml_cpp
        tula_deps::csv_parser
        tula_deps::eigen3
)
