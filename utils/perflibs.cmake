include_guard(GLOBAL)

# Simplified perflibs module for v2 system
# Provides centralized settings for OpenMP and threading libs

message(VERBOSE "Setting up tula::perflibs")

set(perflibs "")

# Find OpenMP (optional)
find_package(OpenMP QUIET)
if(OpenMP_FOUND)
    message(VERBOSE "    Found OpenMP")
    list(APPEND perflibs OpenMP::OpenMP_CXX)
else()
    message(VERBOSE "    OpenMP not found (optional)")
endif()

# Find Threads (required for most parallel libraries)
find_package(Threads QUIET)
if(Threads_FOUND)
    message(VERBOSE "    Found Threads")
    list(APPEND perflibs Threads::Threads)
else()
    message(VERBOSE "    Threads not found (optional)")
endif()

# Create the interface library
add_library(tula_perflibs INTERFACE)
if(perflibs)
    target_link_libraries(tula_perflibs INTERFACE ${perflibs})
endif()

# Add compile definitions
if(OpenMP_FOUND)
    set(has_openmp 1)
else()
    set(has_openmp 0)
endif()
if(Threads_FOUND)
    set(has_threads 1)
else()
    set(has_threads 0)
endif()

target_compile_definitions(tula_perflibs INTERFACE
    HAS_OPENMP=${has_openmp}
    HAS_THREADS=${has_threads}
)

# Create alias
add_library(tula::perflibs ALIAS tula_perflibs)

message(VERBOSE "tula::perflibs ready (OpenMP=${has_openmp}, Threads=${has_threads})")
