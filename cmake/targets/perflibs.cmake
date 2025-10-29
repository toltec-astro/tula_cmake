# Performance Libraries Package Module for tula v2
# Provides centralized settings for multiprocessing and multithreading libs
# - OpenMP (Intel/GNU/LLVM)
# - Intel OneAPI (MKL, Intel OpenMP, TBB, Intel MPI)
# - C++ Threads
#
# Creates target: tula::perflibs

include_guard(GLOBAL)
include(verbose_message)
include(make_tula_target)

## Configuration Options

option(USE_INTEL_ONEAPI "Use the Intel OneAPI libs, including MKL, Intel OpenMP, TBB, and Intel MPI." OFF)

if (USE_INTEL_ONEAPI)
    set(default_openmp_lib "intel")
else()
    if (CMAKE_CXX_COMPILER_ID STREQUAL Clang)
        set(default_openmp_lib "llvm")
    else()
        set(default_openmp_lib "gnu")
    endif()
endif()

set(USE_OPENMP_LIB ${default_openmp_lib} CACHE STRING "Choose the OpenMP lib to use. Options are: \"gnu\", \"intel\", \"llvm\".")
set_property(CACHE USE_OPENMP_LIB PROPERTY STRINGS "gnu" "intel" "llvm")

# Validate the openmp lib settings
if (USE_OPENMP_LIB STREQUAL "intel" AND NOT USE_INTEL_ONEAPI)
    message(FATAL_ERROR "USE_OPENMP_LIB is set to \"intel\" but USE_INTEL_ONEAPI is not set.")
endif()
if (USE_OPENMP_LIB STREQUAL "llvm" AND USE_INTEL_ONEAPI)
    verbose_message("WARNING: USE_OPENMP_LIB=llvm with USE_INTEL_ONEAPI=ON (using LLVM OpenMP + Intel MKL)")
endif()

set(USE_MKL_THREAD "sequential" CACHE STRING "Choose the MKL threading layer. Options are: \"sequential\", \"openmp\", \"tbb\".")
set_property(CACHE USE_MKL_THREAD PROPERTY STRINGS "sequential" "openmp" "tbb")

## Determine MKL Thread Layer

set(MKL_THREAD_LAYER)
if (USE_MKL_THREAD STREQUAL "sequential")
    set(MKL_THREAD_LAYER "Sequential")
elseif(USE_MKL_THREAD STREQUAL "openmp")
    # Use the specified openmp lib
    if (USE_OPENMP_LIB STREQUAL "intel")
        set(MKL_THREAD_LAYER "Intel OpenMP")
    elseif(USE_OPENMP_LIB STREQUAL "gnu")
        set(MKL_THREAD_LAYER "GNU OpenMP")
    elseif(USE_OPENMP_LIB STREQUAL "llvm")
        message(FATAL_ERROR "USE_OPENMP_LIB=llvm conflicts with MKL_THREAD_LAYER=openmp")
    else()
        message(FATAL_ERROR "Invalid USE_OPENMP_LIB setting.")
    endif()
elseif(USE_MKL_THREAD STREQUAL "tbb")
    # Disable use of the intel openmp since this is not supported with the find mkl module
    if (USE_OPENMP_LIB STREQUAL "intel")
        message(FATAL_ERROR "USE_MKL_THREAD=tbb cannot be used with USE_OPENMP_LIB=intel")
    endif()
    set(MKL_THREAD_LAYER "TBB")
else()
    message(FATAL_ERROR "Invalid USE_MKL_THREAD setting.")
endif()

verbose_message("Performance library configuration:")
verbose_message("  USE_INTEL_ONEAPI: ${USE_INTEL_ONEAPI}")
verbose_message("  USE_OPENMP_LIB: ${USE_OPENMP_LIB}")
verbose_message("  USE_MKL_THREAD: ${USE_MKL_THREAD}")
if(USE_INTEL_ONEAPI)
    verbose_message("  MKL_THREAD_LAYER: ${MKL_THREAD_LAYER}")
endif()

## Find Libraries

set(_perflibs "")

# OpenMP
if (USE_OPENMP_LIB STREQUAL "intel")
    # Intel OpenMP is included in the MKL lib, handled below
    verbose_message("Using Intel OpenMP (bundled with MKL)")
else()
    find_package(OpenMP)
    if (OpenMP_FOUND)
        if (VERBOSE_MESSAGE)
            include(print_properties)
            print_target_properties(OpenMP::OpenMP_CXX)
        endif()
        list(APPEND _perflibs OpenMP::OpenMP_CXX)
        verbose_message("OpenMP configured: ${USE_OPENMP_LIB}")
    else()
        verbose_message("WARNING: No OpenMP lib found")
        if (USE_MKL_THREAD STREQUAL "openmp")
            message(FATAL_ERROR "USE_MKL_THREAD=openmp but no OpenMP lib found")
        endif()
    endif()
endif()

# Intel OneAPI / MKL
if (USE_INTEL_ONEAPI)
    find_package(MKL REQUIRED MODULE)
    if (VERBOSE_MESSAGE)
        include(print_properties)
        print_target_properties(MKL::Shared)
    endif()
    # The MKL target will contain the proper thread layer:
    # USE_OPENMP_LIB=intel -> Intel OpenMP + MKL with USE_MKL_THREAD={sequential, openmp}
    # USE_OPENMP_LIB=gnu   -> GNU OpenMP + MKL with USE_MKL_THREAD={sequential, openmp, tbb}
    list(APPEND _perflibs MKL::Shared)
    verbose_message("Intel MKL configured with ${MKL_THREAD_LAYER} threading")
endif()

# C++ Threads
find_package(Threads)
if (Threads_FOUND)
    if (VERBOSE_MESSAGE)
        include(print_properties)
        print_target_properties(Threads::Threads)
    endif()
    list(APPEND _perflibs Threads::Threads)
    verbose_message("C++ Threads configured")
endif()

## Create Target

if(NOT _perflibs)
    message(WARNING "No performance libraries configured - creating empty tula::perflibs target")
endif()

make_tula_target(perflibs ${_perflibs})

# Add compile definitions
if (OpenMP_FOUND)
    set(has_openmp 1)
else()
    set(has_openmp 0)
endif()
if (MKL_FOUND)
    set(has_mkl 1)
else()
    set(has_mkl 0)
endif()
if (Threads_FOUND)
    set(has_threads 1)
else()
    set(has_threads 0)
endif()

target_compile_definitions(tula_perflibs INTERFACE
    USE_OPENMP_LIB=${USE_OPENMP_LIB}
    USE_INTEL_ONEAPI=$<BOOL:${USE_INTEL_ONEAPI}>
    USE_MKL_THREAD=${USE_MKL_THREAD}
    HAS_OPENMP=${has_openmp}
    HAS_MKL=${has_mkl}
    HAS_THREADS=${has_threads}
)

if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_perflibs)
endif()

verbose_message("Performance libraries configured: tula::perflibs")
