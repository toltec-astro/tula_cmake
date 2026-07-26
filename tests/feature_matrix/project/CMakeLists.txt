cmake_minimum_required(VERSION 3.25)

project(tula_feature_matrix LANGUAGES CXX)

include("${CMAKE_CURRENT_SOURCE_DIR}/matrix_case.cmake")
include(TulaProject)
tula_resolve_features()

if(TULA_MATRIX_EXPECT_ENABLED)
    if(NOT TARGET "tula::${TULA_MATRIX_FEATURE}")
        message(FATAL_ERROR
            "${TULA_MATRIX_FEATURE}: expected normalized target is missing")
    endif()
else()
    if(TARGET "tula::${TULA_MATRIX_FEATURE}")
        message(FATAL_ERROR
            "${TULA_MATRIX_FEATURE}: disabled feature created a target")
    endif()
endif()

add_executable(tula_feature_matrix probe.cpp)
target_compile_features(tula_feature_matrix PRIVATE cxx_std_23)
if(TULA_MATRIX_EXPECT_ENABLED)
    target_link_libraries(
        tula_feature_matrix
        PRIVATE "tula::${TULA_MATRIX_FEATURE}"
    )
endif()
if(DEFINED TULA_MATRIX_EXPECT_MKL)
    target_compile_definitions(
        tula_feature_matrix
        PRIVATE "TULA_MATRIX_EXPECT_MKL=${TULA_MATRIX_EXPECT_MKL}"
    )
endif()
if(DEFINED TULA_MATRIX_EXPECT_OPENMP)
    target_compile_definitions(
        tula_feature_matrix
        PRIVATE "TULA_MATRIX_EXPECT_OPENMP=${TULA_MATRIX_EXPECT_OPENMP}"
    )
endif()

if(TULA_MATRIX_EXPECT_RUNTIME STREQUAL "gnu"
   AND NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    message(FATAL_ERROR "GNU OpenMP matrix case requires a GNU compiler profile")
elseif(TULA_MATRIX_EXPECT_RUNTIME STREQUAL "llvm"
       AND NOT CMAKE_CXX_COMPILER_ID MATCHES "^(Clang|AppleClang)$")
    message(FATAL_ERROR "LLVM OpenMP matrix case requires a Clang compiler profile")
elseif(TULA_MATRIX_EXPECT_RUNTIME STREQUAL "intel"
       AND NOT CMAKE_CXX_COMPILER_ID MATCHES "^(Intel|IntelLLVM)$")
    message(FATAL_ERROR "Intel OpenMP matrix case requires an Intel compiler profile")
endif()

enable_testing()
add_test(NAME tula::feature_matrix COMMAND tula_feature_matrix)
