"""NetCDFCXX4 package definition - NetCDF C++ bindings"""

PACKAGE_INFO = {
    "name": "NetCDFCXX4",
    "modes": ["AUTO", "CPM", "SYSTEM", "DISABLED"],  # No Conan support
    "conan_requires": [],  # Not available in Conan
    "cmake_file": "NetCDFCXX4.cmake",
    "cmake_vars": {
        "CPM_GITHUB_REPO": "Unidata/netcdf-cxx4",
        "CPM_GIT_TAG": "main",
        "CPM_OPTIONS": [
            "ENABLE_DOXYGEN OFF",
            "BUILD_SHARED_LIBS OFF",
            "NCXX_ENABLE_TESTS OFF",
            "ENABLE_COVERAGE_TESTS OFF",
            "ENABLE_LARGE_FILE_TESTS OFF",
        ],
    },
}
