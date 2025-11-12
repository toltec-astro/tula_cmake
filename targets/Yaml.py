"""Yaml package definition - YAML parser library (yaml-cpp)"""

PACKAGE_INFO = {
    "name": "Yaml",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    "conan_requires": ["yaml-cpp/0.8.0"],
    "cmake_file": "Yaml.cmake",
    # CMake variables (MODE will be added automatically by toolchain)
    "cmake_vars": {
        "CPM_GITHUB_REPO": "jbeder/yaml-cpp",
        "CPM_GIT_TAG": "0.8.0",  # Use release tag without 'v' prefix
        "CPM_OPTIONS": [
            "YAML_CPP_BUILD_TESTS OFF",
            "YAML_CPP_BUILD_TOOLS OFF",
            "YAML_CPP_BUILD_CONTRIB OFF",
            "YAML_CPP_INSTALL ON",
        ],
    },
}
