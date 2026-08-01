cmake_minimum_required(VERSION 3.25)

project(TulaCcfitsConsumer LANGUAGES CXX)

find_package(TulaCcfits 1 CONFIG REQUIRED)

add_executable(tula_ccfits_consumer main.cpp)
target_compile_features(tula_ccfits_consumer PRIVATE cxx_std_23)
target_link_libraries(tula_ccfits_consumer PRIVATE tula_deps::ccfits)

enable_testing()
add_test(NAME tula_ccfits_consumer COMMAND tula_ccfits_consumer)
