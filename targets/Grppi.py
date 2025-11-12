"""Grppi package definition - Parallel patterns library"""

PACKAGE_INFO = {
    "name": "Grppi",
    "modes": ["AUTO", "CPM", "DISABLED"],  # Header-only, CPM only
    "conan_requires": [],
    "cmake_file": "Grppi.cmake",
    "cmake_vars": {
        "CPM_GITHUB_REPO": "Jerry-Ma/grppi",
        "CPM_GIT_TAG": "cpp20",
    },
}
