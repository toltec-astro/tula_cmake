"""logging package definition - Metapackage for spdlog + fmt"""

PACKAGE_INFO = {
    "name": "logging",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    # Meta-package: multiple Conan requirements
    "conan_requires": ["spdlog/1.12.0"],  # fmt is transitive dependency
    "cmake_file": "logging.cmake",
    # CMake variables (MODE will be added automatically by toolchain)
    "cmake_vars": {
        "SPDLOG_GIT_TAG": "v1.x",
        "SPDLOG_GITHUB_REPO": "gabime/spdlog",
        "SPDLOG_OPTIONS": [
            "SPDLOG_FMT_EXTERNAL ON",
            "SPDLOG_INSTALL ON",
        ],
    },
}
