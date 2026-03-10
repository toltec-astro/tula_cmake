# testing.cmake - Test infrastructure metapackage (GTest + Google Benchmark)
#
# Defines: tula_testing_add_conan(), tula_testing_add_cpm(), tula_testing_add_system()
# Called by: tula_deps_add(deps testing) from tula_deps.cmake

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../utils/make_tula_target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/verbose_message.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../utils/_ensure_cpm.cmake)

#[=======================================================================[
@brief Load GTest and benchmark from Conan
]=======================================================================]
function(tula_testing_add_conan)
    # Try GTest
    find_package(GTest QUIET CONFIG)
    if(NOT TARGET GTest::gtest AND NOT TARGET gtest)
        return()
    endif()
    
    # Try Google Benchmark
    find_package(benchmark QUIET CONFIG)
    if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark)
        return()
    endif()
    
    verbose_message("Found GTest and benchmark via Conan")
    _tula_testing_create_wrapper()
    _tula_testing_setup_environment()
endfunction()

#[=======================================================================[
@brief Fetch GTest and benchmark via CPM
]=======================================================================]
function(tula_testing_add_cpm)
    if(NOT DEFINED TULA_TESTING_GTEST_GITHUB_REPO)
        return()
    endif()

    # CPM requires CXX language (compiles GTest/benchmark). Defer to post-project().
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        message(STATUS "    Toolchain phase: deferring testing CPM to post-project() phase")
        return()
    endif()

    # Fetch GTest
    if(NOT TARGET GTest::gtest AND NOT TARGET gtest)
        CPMAddPackage(
            NAME googletest
            GITHUB_REPOSITORY "${TULA_TESTING_GTEST_GITHUB_REPO}"
            GIT_TAG "${TULA_TESTING_GTEST_GIT_TAG}"
            OPTIONS ${TULA_TESTING_GTEST_OPTIONS}
        )
    endif()
    
    # Fetch Google Benchmark
    if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark)
        CPMAddPackage(
            NAME benchmark
            GITHUB_REPOSITORY "${TULA_TESTING_BENCHMARK_GITHUB_REPO}"
            GIT_TAG "${TULA_TESTING_BENCHMARK_GIT_TAG}"
            OPTIONS ${TULA_TESTING_BENCHMARK_OPTIONS}
        )
    endif()
    
    if(NOT TARGET GTest::gtest AND NOT TARGET gtest)
        return()
    endif()
    if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark)
        return()
    endif()
    
    verbose_message("Fetched GTest and benchmark via CPM")
    _tula_testing_create_wrapper()
    _tula_testing_setup_environment()
endfunction()

#[=======================================================================[
@brief Find GTest and benchmark via system
]=======================================================================]
function(tula_testing_add_system)
    # GTestConfig.cmake calls find_package(Threads) which requires CXX language.
    # Skip entirely during toolchain phase; tula_deps.cmake will defer and retry.
    if(NOT CMAKE_CXX_COMPILER_LOADED)
        message(STATUS "    Toolchain phase: deferring testing system to post-project() phase")
        return()
    endif()

    find_package(GTest QUIET CONFIG)
    if(NOT TARGET GTest::gtest AND NOT TARGET GTest::GTest AND NOT TARGET gtest)
        # Try module mode (Ubuntu libgtest-dev may not provide CONFIG)
        find_package(GTest MODULE QUIET)
    endif()
    if(NOT TARGET GTest::gtest AND NOT TARGET GTest::GTest AND NOT TARGET gtest)
        message(STATUS "    GTest not found via system (neither CONFIG nor MODULE)")
        return()
    endif()

    find_package(benchmark QUIET CONFIG)
    if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark)
        message(STATUS "    benchmark not found via system CONFIG")
        return()
    endif()

    verbose_message("Found GTest and benchmark via system")
    _tula_testing_create_wrapper()
    _tula_testing_setup_environment()
endfunction()

#[=======================================================================[
@brief Create tula::testing metapackage wrapper
]=======================================================================]
function(_tula_testing_create_wrapper)
    if(TARGET tula_testing)
        return()
    endif()
    
    set(_testing_libs "")
    
    # Add GTest (check both possible target names)
    if(TARGET GTest::gtest)
        list(APPEND _testing_libs GTest::gtest)
        if(TARGET GTest::gmock)
            list(APPEND _testing_libs GTest::gmock)
        endif()
        verbose_message("Using GTest::gtest")
    elseif(TARGET gtest)
        list(APPEND _testing_libs gtest)
        if(TARGET gmock)
            list(APPEND _testing_libs gmock)
        endif()
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
    
    make_tula_target(testing ${_testing_libs})
    
    verbose_message("Created tula::testing metapackage")
endfunction()

#[=======================================================================[
@brief Setup test environment (enable_testing, check target, GoogleTest)
]=======================================================================]
function(_tula_testing_setup_environment)
    enable_testing()
    add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})
    include(GoogleTest)
endfunction()

