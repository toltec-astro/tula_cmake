"""Ceres package definition - Non-linear least squares solver"""

PACKAGE_INFO = {
    "name": "Ceres",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    "conan_requires": ["ceres-solver/2.1.0"],  # Eigen is loaded as dependency in CMake
    "cmake_file": "Ceres.cmake",
    # Required and optional dependencies
    "depends_on": ["Eigen3"],  # Required
    "optional_deps": ["perflibs"],  # For multithreading support
    "cmake_vars": {
        "CPM_GITHUB_REPO": "ceres-solver/ceres-solver",
        "CPM_GIT_TAG": "2.0.0",
        "CPM_OPTIONS": [
            "GLOG_PREFER_EXPORTED_GLOG_CMAKE_CONFIGURATION ON",
            "MINIGLOG OFF",
            "GFLAGS OFF",
            "EIGENSPARSE ON",
            "SUITESPARSE OFF",
            "CXSPARSE OFF",
            "ACCELERATESPARSE OFF",
            "SCHUR_SPECIALIZATIONS ON",
            "BUILD_DOCUMENTATION OFF",
            "BUILD_TESTING OFF",
            "BUILD_EXAMPLES OFF",
            "BUILD_BENCHMARKS OFF",
            "BUILD_SHARED_LIBS OFF",
        ],
        "GLOG_CPM_GITHUB_REPO": "google/glog",
        "GLOG_CPM_GIT_TAG": "v0.5.0",
        "GLOG_CPM_OPTIONS": [
            "BUILD_SHARED_LIBS OFF",
            "WITH_GFLAGS OFF",
            "WITH_GTEST OFF",
            "WITH_PKGCONFIG OFF",
            "WITH_SYMBOLIZE OFF",
            "WITH_UNWIND OFF",
            "BUILD_TESTING OFF",
        ],
    },
}
