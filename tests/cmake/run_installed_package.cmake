foreach(required_var
        TULA_CMAKE_BUILD_DIR
        FIXTURE_SOURCE_DIR
        CONSUMER_SOURCE_DIR
        TEST_ROOT)
    if(NOT DEFINED ${required_var})
        message(FATAL_ERROR "Missing ${required_var}")
    endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}")
set(prefix "${TEST_ROOT}/prefix")

function(run_checked)
    execute_process(
        COMMAND ${ARGV}
        RESULT_VARIABLE result
        COMMAND_ECHO STDOUT
    )
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Command failed with exit code ${result}: ${ARGV}")
    endif()
endfunction()

run_checked(
    "${CMAKE_COMMAND}"
    --install "${TULA_CMAKE_BUILD_DIR}"
    --prefix "${prefix}"
)
run_checked(
    "${CMAKE_COMMAND}"
    -S "${FIXTURE_SOURCE_DIR}"
    -B "${TEST_ROOT}/fixture-build"
    "-DCMAKE_PREFIX_PATH=${prefix}"
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    -DCMAKE_BUILD_TYPE=Debug
)
run_checked(
    "${CMAKE_COMMAND}"
    --build "${TEST_ROOT}/fixture-build"
    --parallel
)
run_checked(
    "${CMAKE_CTEST_COMMAND}"
    --test-dir "${TEST_ROOT}/fixture-build"
    --output-on-failure
)
run_checked(
    "${CMAKE_COMMAND}"
    --install "${TEST_ROOT}/fixture-build"
)
run_checked(
    "${CMAKE_COMMAND}"
    -S "${CONSUMER_SOURCE_DIR}"
    -B "${TEST_ROOT}/consumer-build"
    "-DCMAKE_PREFIX_PATH=${prefix}"
    -DCMAKE_BUILD_TYPE=Debug
)
run_checked(
    "${CMAKE_COMMAND}"
    --build "${TEST_ROOT}/consumer-build"
    --parallel
)
run_checked("${TEST_ROOT}/consumer-build/tula_cmake_fixture_consumer")
