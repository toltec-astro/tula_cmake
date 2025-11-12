"""Spectra package definition - Eigenvalue problems library"""

PACKAGE_INFO = {
    "name": "Spectra",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    "conan_requires": ["spectra/1.0.1"],
    "cmake_file": "Spectra.cmake",
    # CMake variables (MODE will be added automatically by toolchain)
    "cmake_vars": {
        "CPM_GITHUB_REPO": "yixuan/spectra",
        "CPM_GIT_TAG": "v1.0.1",
        "CPM_OPTIONS": [
            "BUILD_TESTS OFF",
            "BUILD_EXAMPLES OFF",
        ],
    },
}
