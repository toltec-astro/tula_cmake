"""Csv package definition - CSV parser library"""

PACKAGE_INFO = {
    "name": "Csv",
    "modes": ["AUTO", "CPM", "DISABLED"],  # Header-only, CPM only
    "conan_requires": [],
    "cmake_file": "Csv.cmake",
    "cmake_vars": {
        "CPM_GITHUB_REPO": "Jerry-Ma/csv-parser",
        "CPM_GIT_TAG": "master",
    },
}
