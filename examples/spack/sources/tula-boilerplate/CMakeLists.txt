cmake_minimum_required(VERSION 3.25)

project(tula_boilerplate VERSION 0.1.0 LANGUAGES CXX)

include(CMakePackageConfigHelpers)

find_package(fmt CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(TulaLibA CONFIG REQUIRED)
find_package(TulaPerflibs CONFIG REQUIRED)

add_library(tula_boilerplate INTERFACE)
add_library(tula::boilerplate ALIAS tula_boilerplate)
set_target_properties(tula_boilerplate PROPERTIES EXPORT_NAME boilerplate)
target_compile_features(tula_boilerplate INTERFACE cxx_std_23)
target_include_directories(
    tula_boilerplate
    INTERFACE
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "$<INSTALL_INTERFACE:include>"
)
target_link_libraries(
    tula_boilerplate
    INTERFACE
        fmt::fmt
        spdlog::spdlog
        tula::lib_a
        tula::perflibs
)

install(TARGETS tula_boilerplate EXPORT TulaBoilerplateTargets)
install(DIRECTORY include/ DESTINATION include)
install(EXPORT TulaBoilerplateTargets NAMESPACE tula::
        DESTINATION lib/cmake/TulaBoilerplate)
configure_package_config_file(
    cmake/TulaBoilerplateConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/TulaBoilerplateConfig.cmake"
    INSTALL_DESTINATION lib/cmake/TulaBoilerplate
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/TulaBoilerplateConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion
)
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/TulaBoilerplateConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/TulaBoilerplateConfigVersion.cmake"
    DESTINATION lib/cmake/TulaBoilerplate
)

