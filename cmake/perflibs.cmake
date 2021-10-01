include_guard(GLOBAL)

include(verbose_message)

## This module provides centralized settings for multiprocessing
## and multithreading libs.

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
# validate the openmp lib settings
if (USE_OPENMP_LIB STREQUAL "intel" AND NOT USE_INTEL_ONEAPI)
    message(FATAL_ERROR "USE_OPENMP_LIB is set to \"intel\" but USE_INTEL_ONEAPI is not set.")
endif()
if (USE_OPENMP_LIB STREQUAL "llvm" AND USE_INTEL_ONEAPI)
    # message(FATAL_ERROR "USE_OPENMP_LIB=llvm conflicts with USE_INTEL_ONEAPI=ON.")
endif()

set(USE_MKL_THREAD "sequential" CACHE STRING "Choose the MKL threading layer. Options are: \"sequential\", \"openmp\", \"tbb\".")
set_property(CACHE USE_MKL_THREAD PROPERTY STRINGS "sequential" "openmp" "tbb")

# Figure out MKL thread layer
set(MKL_THREAD_LAYER)
if (USE_MKL_THREAD STREQUAL "sequential")
    set(MKL_THREAD_LAYER "Sequential")
elseif(USE_MKL_THREAD STREQUAL "openmp")
    # use the specified openmp lib
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
    # disable use of the intel openmp since this is not supported
    # with the find mkl module
    if (USE_OPENMP_LIB STREQUAL "intel")
        message(FATAL_ERROR "US_MKL_THREAD=tbb cannot be used with USE_OPENMP_LIB=intel")
    endif()
    set(MKL_THREAD_LAYER "TBB")
else()
    message(FATAL_ERROR "Invalid USE_MKL_THREAD setting.")
endif()

# Now do the find
set(perflibs "")
if (USE_OPENMP_LIB STREQUAL "intel")
    # intel openmp is included in the mkl lib
    # do nothing here
else()
    find_package(OpenMP)
    if (OpenMP_FOUND)
        if (VERBOSE_MESSAGE)
            include(print_properties)
            print_target_properties(OpenMP::OpenMP_CXX)
        endif()
        set(perflibs ${perflibs} OpenMP::OpenMP_CXX)
    else()
        verbose_message("No OpenMP lib is found")
        if (USE_MKL_THREAD STREQUAL "openmp")
            message(FATAL_ERROR "USE_MKL_THREAD=openmp but no OpenMP lib is found.")
        endif()
    endif()
endif()
if (USE_INTEL_ONEAPI)
    find_package(MKL REQUIRED MODULE)
    if (VERBOSE_MESSAGE)
        include(print_properties)
        print_target_properties(MKL::Shared)
    endif()
    # the MKL target will contain the proper
    # thread layer:
    # USE_OPENMP_LIB=intel, this will be intel OpenMP + MKL with USE_MKL_THREAD={sequential, openmp}
    # USE_OPENMP_LIB=gnu, this will be GNU OpenMP + MKL with USE_MKL_THREAD={sequential, openmp, tbb}
    set(perflibs ${perflibs} MKL::Shared)
else()
    # nothing happens here
endif()
# add C++ threads
find_package(Threads)
if (Threads_FOUND)
    if (VERBOSE_MESSAGE)
        include(print_properties)
        print_target_properties(Threads::Threads)
    endif()
    set(perflibs ${perflibs} Threads::Threads)
endif()

add_library(tula_perflibs INTERFACE)
target_link_libraries(tula_perflibs INTERFACE ${perflibs})
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
    USE_INTEL_ONEAPI=${USE_INTEL_ONEAPI}
    USE_MKL_THREAD=${USE_MKL_THREAD}
    HAS_OPENMP=${has_openmp}
    HAS_MKL=${has_mkl}
    HAS_THREADS=${has_threads}
    )
if (VERBOSE_MESSAGE)
    include(print_properties)
    print_target_properties(tula_perflibs)
endif()
add_library(tula::perflibs ALIAS tula_perflibs)
