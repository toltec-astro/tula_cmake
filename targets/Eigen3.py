"""Eigen3 package definition - Linear algebra library"""

PACKAGE_INFO = {
    "name": "Eigen3",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    "conan_requires": ["eigen/3.4.0"],
    "cmake_file": "Eigen3.cmake",
    # CMake variables (MODE will be added automatically by toolchain)
    "cmake_vars": {
        "CPM_URL": "https://gitlab.com/libeigen/eigen/-/archive/3.4.1/eigen-3.4.1.tar.gz",
        "CPM_OPTIONS": [
            "BUILD_TESTING OFF",
            "EIGEN_BUILD_DOC OFF",
            "EIGEN_BUILD_PKGCONFIG OFF",
            "EIGEN_BUILD_BTL OFF",
            "EIGEN_LEAVE_TEST_IN_ALL_TARGET OFF",
        ],
    },
}
