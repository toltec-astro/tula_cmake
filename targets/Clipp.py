"""Clipp package definition - Command line interface parser"""

PACKAGE_INFO = {
    "name": "Clipp",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    "conan_requires": ["clipp/1.2.3"],
    "cmake_file": "Clipp.cmake",
    "cmake_vars": {
        "CPM_GITHUB_REPO": "GerHobbelt/clipp",
        "CPM_GIT_TAG": "master",
    },
}
