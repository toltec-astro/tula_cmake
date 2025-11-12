# testing.cmake - Test infrastructure metapackage (GTest + Google Benchmark)
# Adapted for v3 Conan-centric architecture with stateless functions

include_guard(GLOBAL)

# Include utilities
include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Main setup function for testing metapackage (stateless, mode as parameter)

This is the entry point called by tula_deps_add().
Mode is passed as parameter (not global variable).

@param MODE Resolution mode (AUTO, CONAN, CPM, SYSTEM)
]=======================================================================]
function(tula_setup_testing MODE)
    verbose_message("Setting up tula::testing metapackage (mode=${MODE})")
    
    # Idempotency check
    if(TARGET tula::testing)
        verbose_message("tula::testing already exists, skipping")
        return()
    endif()
    
    # Mode-driven resolution
    if(MODE MATCHES "CONAN|AUTO")
        _tula_testing_try_conan()
    elseif(MODE STREQUAL "CPM")
        _tula_testing_try_cpm()
    elseif(MODE STREQUAL "SYSTEM")
        _tula_testing_try_system()
    else()
        message(FATAL_ERROR "Unknown testing mode: ${MODE}")
    endif()
    
    # Create metapackage wrapper
    _tula_testing_create_wrapper()
    
    # Setup test environment
    enable_testing()
    add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})
    include(GoogleTest)
    
    verbose_message("tula::testing ready")
endfunction()

#[=======================================================================[
@brief Try to find GTest and benchmark via Conan
]=======================================================================]
function(_tula_testing_try_conan)
    # Try GTest
    find_package(GTest QUIET CONFIG)
    if(NOT TARGET GTest::gtest AND NOT TARGET gtest)
        message(FATAL_ERROR "GTest not found via Conan CONFIG. Ensure it's in Conan requirements.")
    endif()
    
    # Try Google Benchmark
    find_package(benchmark QUIET CONFIG)
    if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark)
        message(FATAL_ERROR "benchmark not found via Conan CONFIG. Ensure it's in Conan requirements.")
    endif()
    
    verbose_message("Found GTest and benchmark via Conan")
endfunction()

#[=======================================================================[
@brief Fetch GTest and benchmark via CPM
]=======================================================================]
function(_tula_testing_try_cpm)
    if(NOT DEFINED TESTING_GTEST_GITHUB_REPO)
        message(FATAL_ERROR "TESTING_GTEST_GITHUB_REPO not set. Check toolchain configuration.")
    endif()
    
    # Fetch GTest
    if(NOT TARGET GTest::gtest AND NOT TARGET gtest)
        CPMAddPackage(
            NAME googletest
            GITHUB_REPOSITORY "${TESTING_GTEST_GITHUB_REPO}"
            GIT_TAG "${TESTING_GTEST_GIT_TAG}"
            OPTIONS ${TESTING_GTEST_OPTIONS}
        )
    endif()
    
    # Fetch Google Benchmark
    if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark)
        CPMAddPackage(
            NAME benchmark
            GITHUB_REPOSITORY "${TESTING_BENCHMARK_GITHUB_REPO}"
            GIT_TAG "${TESTING_BENCHMARK_GIT_TAG}"
            OPTIONS ${TESTING_BENCHMARK_OPTIONS}
        )
    endif()
    
    verbose_message("Fetched GTest and benchmark via CPM")
endfunction()

#[=======================================================================[
@brief Find GTest and benchmark via system
]=======================================================================]
function(_tula_testing_try_system)
    find_package(GTest REQUIRED CONFIG)
    find_package(benchmark REQUIRED CONFIG)
    
    verbose_message("Found GTest and benchmark via system")
endfunction()

#[=======================================================================[
@brief Create tula::testing metapackage wrapper
]=======================================================================]
function(_tula_testing_create_wrapper)
    if(TARGET tula_testing)
        return()  # Already created
    endif()
    
    set(_testing_libs "")
    
    # Add GTest (check both possible target names)
    if(TARGET GTest::gtest)
        list(APPEND _testing_libs GTest::gtest GTest::gmock)
        verbose_message("Using GTest::gtest")
    elseif(TARGET gtest)
        list(APPEND _testing_libs gtest gmock)
        verbose_message("Using gtest")
    else()
        message(FATAL_ERROR "GTest target not found. Cannot create testing metapackage.")
    endif()
    
    # Add Google Benchmark (check both possible target names)
    if(TARGET benchmark::benchmark)
        list(APPEND _testing_libs benchmark::benchmark)
        verbose_message("Using benchmark::benchmark")
    elseif(TARGET benchmark)
        list(APPEND _testing_libs benchmark)
        verbose_message("Using benchmark")
    else()
        message(FATAL_ERROR "benchmark target not found. Cannot create testing metapackage.")
    endif()
    
    # Create metapackage wrapper
    make_tula_target(testing ${_testing_libs})
    
    verbose_message("Created tula::testing metapackage")
endfunction()

