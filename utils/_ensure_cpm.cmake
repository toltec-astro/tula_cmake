# _ensure_cpm.cmake - Load CPM.cmake if not already available
#
# Usage:
#   include(_ensure_cpm)
#   # Now CPMAddPackage command is available

include_guard(GLOBAL)

if(NOT COMMAND CPMAddPackage)
    set(CPM_DOWNLOAD_VERSION 0.40.0)
    set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
    
    if(NOT EXISTS "${CPM_DOWNLOAD_LOCATION}")
        message(STATUS "Downloading CPM.cmake v${CPM_DOWNLOAD_VERSION}...")
        file(DOWNLOAD
            https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
            ${CPM_DOWNLOAD_LOCATION}
            EXPECTED_HASH SHA256=7b354f3a5976c4626c876850c93944e52c83ec59a159ae5de5be7983f0e17a2a
        )
    endif()
    
    include(${CPM_DOWNLOAD_LOCATION})
endif()
