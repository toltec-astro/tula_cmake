cmake_minimum_required(VERSION 3.25)

project(tula_perflibs VERSION 0.1.0 LANGUAGES CXX)

include(CMakePackageConfigHelpers)

option(TULA_PERFLIBS_ENABLE_OPENMP "Require compiler-native OpenMP" ON)

find_package(Threads REQUIRED)
if(TULA_PERFLIBS_ENABLE_OPENMP)
    find_package(OpenMP REQUIRED COMPONENTS CXX)
endif()

add_library(tula_perflibs INTERFACE)
add_library(tula::perflibs ALIAS tula_perflibs)
set_target_properties(tula_perflibs PROPERTIES EXPORT_NAME perflibs)
target_compile_features(tula_perflibs INTERFACE cxx_std_23)
target_link_libraries(tula_perflibs INTERFACE Threads::Threads)
if(TULA_PERFLIBS_ENABLE_OPENMP)
    target_link_libraries(tula_perflibs INTERFACE OpenMP::OpenMP_CXX)
endif()
target_compile_definitions(
    tula_perflibs
    INTERFACE
        TULA_PERFLIBS_HAS_THREADS=1
        "TULA_PERFLIBS_HAS_OPENMP=$<BOOL:${TULA_PERFLIBS_ENABLE_OPENMP}>"
)

install(TARGETS tula_perflibs EXPORT TulaPerflibsTargets)
install(EXPORT TulaPerflibsTargets NAMESPACE tula::
        DESTINATION lib/cmake/TulaPerflibs)
configure_package_config_file(
    cmake/TulaPerflibsConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/TulaPerflibsConfig.cmake"
    INSTALL_DESTINATION lib/cmake/TulaPerflibs
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/TulaPerflibsConfigVersion.cmake"
    COMPATIBILITY SameMajorVersion
)
install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/TulaPerflibsConfig.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/TulaPerflibsConfigVersion.cmake"
    DESTINATION lib/cmake/TulaPerflibs
)

