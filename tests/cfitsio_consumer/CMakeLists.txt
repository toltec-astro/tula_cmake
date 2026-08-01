cmake_minimum_required(VERSION 3.25)

project(TulaCfitsioConsumer LANGUAGES CXX)

find_package(TulaCfitsio 1 CONFIG REQUIRED)

add_executable(tula_cfitsio_consumer main.cpp)
target_compile_features(tula_cfitsio_consumer PRIVATE cxx_std_23)
target_link_libraries(tula_cfitsio_consumer PRIVATE tula_deps::cfitsio)

enable_testing()
add_test(NAME tula_cfitsio_consumer COMMAND tula_cfitsio_consumer)
