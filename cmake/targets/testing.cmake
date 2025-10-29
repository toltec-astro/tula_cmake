# testing.cmake - Test infrastructure (GTest + Google Benchmark)
# Single-include workflow with callback-based target creation
#
# Creates target: tula::testing

include_guard(GLOBAL)
include(verbose_message)

# Skip if target already exists
if(TARGET tula_testing)
    message(STATUS "(testing) Target tula_testing already exists, skipping")
    return()
endif()

#[=======================================================================[
@brief Create GTest targets from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_gtest_create_conan_target)
    if(TARGET GTest::gtest)
        return()  # Already created
    endif()
    
    set(GTEST_INCLUDE_DIR "")
    set(GTEST_LIB_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "gtest" OR _path MATCHES "googletest")
            set(GTEST_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    foreach(_path IN LISTS CMAKE_LIBRARY_PATH)
        if(_path MATCHES "gtest" OR _path MATCHES "googletest")
            set(GTEST_LIB_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT GTEST_INCLUDE_DIR OR NOT GTEST_LIB_DIR)
        message(STATUS "  ✗ GTest not found in CMAKE_INCLUDE_PATH/CMAKE_LIBRARY_PATH, will try next mode")
        return()
    endif()
    
    # Create gtest target
    add_library(GTest::gtest INTERFACE IMPORTED GLOBAL)
    target_include_directories(GTest::gtest INTERFACE "${GTEST_INCLUDE_DIR}")
    target_link_directories(GTest::gtest INTERFACE "${GTEST_LIB_DIR}")
    target_link_libraries(GTest::gtest INTERFACE gtest)
    
    # Create gmock target
    add_library(GTest::gmock INTERFACE IMPORTED GLOBAL)
    target_include_directories(GTest::gmock INTERFACE "${GTEST_INCLUDE_DIR}")
    target_link_directories(GTest::gmock INTERFACE "${GTEST_LIB_DIR}")
    target_link_libraries(GTest::gmock INTERFACE gmock)
    
    message(STATUS "  ✓ Created GTest::gtest and GTest::gmock targets from Conan")
endfunction()

#[=======================================================================[
@brief Create benchmark targets from Conan-provided paths
Called by tula_deps_create_targets() when MODE=CONAN
]=======================================================================]
function(_tula_benchmark_create_conan_target)
    if(TARGET benchmark::benchmark)
        return()  # Already created
    endif()
    
    set(BENCHMARK_INCLUDE_DIR "")
    set(BENCHMARK_LIB_DIR "")
    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)
        if(_path MATCHES "benchmark")
            set(BENCHMARK_INCLUDE_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    foreach(_path IN LISTS CMAKE_LIBRARY_PATH)
        if(_path MATCHES "benchmark")
            set(BENCHMARK_LIB_DIR "${_path}")
            break()
        endif()
    endforeach()
    
    if(NOT BENCHMARK_INCLUDE_DIR OR NOT BENCHMARK_LIB_DIR)
        message(STATUS "  ✗ benchmark not found in CMAKE_INCLUDE_PATH/CMAKE_LIBRARY_PATH, will try next mode")
        return()
    endif()
    
    add_library(benchmark::benchmark INTERFACE IMPORTED GLOBAL)
    target_include_directories(benchmark::benchmark INTERFACE "${BENCHMARK_INCLUDE_DIR}")
    target_link_directories(benchmark::benchmark INTERFACE "${BENCHMARK_LIB_DIR}")
    target_link_libraries(benchmark::benchmark INTERFACE benchmark)
    
    message(STATUS "  ✓ Created benchmark::benchmark target from Conan")
endfunction()

# Register GTest dependency
tula_deps_register(GTest
    CONAN_NAME gtest
    CONAN_TARGET_CALLBACK _tula_gtest_create_conan_target
    CONAN_TARGET_NAME GTest::gtest
    CPM_GITHUB_REPOSITORY google/googletest
    CPM_GIT_TAG main
    CPM_OPTIONS 
        "BUILD_GMOCK ON" 
        "INSTALL_GTEST OFF" 
        "gtest_force_shared_crt ON"
    SYSTEM_NAME GTest
    FIND_PACKAGE_ARGS CONFIG
)

# Register Google Benchmark dependency
tula_deps_register(benchmark
    CONAN_NAME benchmark
    CONAN_TARGET_CALLBACK _tula_benchmark_create_conan_target
    CONAN_TARGET_NAME benchmark::benchmark
    CPM_GITHUB_REPOSITORY google/benchmark
    CPM_GIT_TAG main
    CPM_OPTIONS 
        "BENCHMARK_ENABLE_TESTING OFF"
        "BENCHMARK_ENABLE_INSTALL OFF"
        "BENCHMARK_INSTALL_DOCS OFF"
        "BENCHMARK_ENABLE_GTEST_TESTS OFF"
        "BENCHMARK_ENABLE_ASSEMBLY_TESTS OFF"
    SYSTEM_NAME benchmark
    FIND_PACKAGE_ARGS CONFIG
)

# Wrapper function to create tula::testing after dependencies are resolved
function(_tula_testing_create_wrapper)
    if(TARGET tula_testing)
        return()  # Already created
    endif()
    
    set(_testing_libs "")

    # Add GTest and GMock
    if(TARGET GTest::gtest)
        list(APPEND _testing_libs GTest::gtest GTest::gmock)
        verbose_message("GTest configured with GTest::gtest target")
    elseif(TARGET gtest)
        list(APPEND _testing_libs gtest gmock)
        verbose_message("GTest configured with gtest target")
    else()
        message(FATAL_ERROR "GTest not found after dependency resolution")
    endif()

    # Add Google Benchmark
    if(TARGET benchmark::benchmark)
        list(APPEND _testing_libs benchmark::benchmark)
        verbose_message("Google Benchmark configured with benchmark::benchmark target")
    elseif(TARGET benchmark)
        list(APPEND _testing_libs benchmark)
        verbose_message("Google Benchmark configured with benchmark target")
    else()
        message(FATAL_ERROR "benchmark not found after dependency resolution")
    endif()

    # Create the tula wrapper target
    include(make_tula_target)
    make_tula_target(testing ${_testing_libs})

    # Setup test environment
    enable_testing()
    # https://gitlab.kitware.com/cmake/community/wikis/doc/tutorials/EmulateMakeCheck
    add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})
    include(GoogleTest)

    verbose_message("Testing configured: tula::testing")
endfunction()

# If targets already exist, create wrapper now
if((TARGET GTest::gtest OR TARGET gtest) AND (TARGET benchmark::benchmark OR TARGET benchmark))
    _tula_testing_create_wrapper()
endif()
