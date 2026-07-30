cmake_minimum_required(VERSION 3.25)

project(TulaCMakeFixtureConsumer LANGUAGES CXX)

find_package(TulaCMake CONFIG REQUIRED)
find_package(TulaCMakeFixture 1 CONFIG REQUIRED)

add_executable(tula_cmake_fixture_consumer main.cpp)
tula_cmake_target_defaults(
    TARGET tula_cmake_fixture_consumer
    WARNINGS
)
target_link_libraries(
    tula_cmake_fixture_consumer
    PRIVATE fixture::fixture
)
