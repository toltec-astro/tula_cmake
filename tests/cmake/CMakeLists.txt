set(fixture_root "${CMAKE_CURRENT_SOURCE_DIR}/fixture")
set(consumer_root "${CMAKE_CURRENT_SOURCE_DIR}/consumer")
set(test_root "${CMAKE_CURRENT_BINARY_DIR}/installed-package")

add_test(
    NAME tula_cmake::installed_package
    COMMAND
        "${CMAKE_COMMAND}"
        "-DTULA_CMAKE_BUILD_DIR=${PROJECT_BINARY_DIR}"
        "-DFIXTURE_SOURCE_DIR=${fixture_root}"
        "-DCONSUMER_SOURCE_DIR=${consumer_root}"
        "-DTEST_ROOT=${test_root}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/run_installed_package.cmake"
)
