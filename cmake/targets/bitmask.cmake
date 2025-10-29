# bitmask.cmake - Type-safe bitmask operations (header-only)
# Special handling: bitmask has cmake_minimum_required < 3.5, incompatible with CMake 3.30+
# We manually fetch and create target instead of processing their CMakeLists.txt

include(verbose_message)
include(FetchContent)

# Skip if target already exists
if(TARGET bitmask::bitmask)
    message(STATUS "(bitmask) Target bitmask::bitmask already exists, skipping")
    return()
endif()

# Manually fetch bitmask (header-only) - use Populate to avoid add_subdirectory
FetchContent_Declare(
    bitmask
    GIT_REPOSITORY https://github.com/oliora/bitmask.git
    GIT_TAG 1.1.2
)

# Set policy to allow deprecated Populate method
cmake_policy(SET CMP0169 OLD)
FetchContent_Populate(bitmask)

# Create our own target (don't use their CMakeLists.txt)
if(bitmask_SOURCE_DIR)
    add_library(bitmask::bitmask INTERFACE IMPORTED GLOBAL)
    target_include_directories(bitmask::bitmask INTERFACE "${bitmask_SOURCE_DIR}/include")
    message(STATUS "(bitmask) Created header-only target: ${bitmask_SOURCE_DIR}/include")
else()
    message(FATAL_ERROR "bitmask source not found after FetchContent_Populate")
endif()

