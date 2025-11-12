"""Enum package definition - Enum utilities (meta_enum + bitmask)"""

PACKAGE_INFO = {
    "name": "Enum",
    "modes": ["AUTO", "CPM", "DISABLED"],  # Header-only, CPM only
    "conan_requires": [],
    "cmake_file": "Enum.cmake",
    "cmake_vars": {
        "META_ENUM_CPM_GITHUB_REPO": "Jerry-Ma/meta_enum",
        "META_ENUM_CPM_GIT_TAG": "master",
        "BITMASK_CPM_GITHUB_REPO": "oliora/bitmask",
        "BITMASK_CPM_GIT_TAG": "master",
    },
}
