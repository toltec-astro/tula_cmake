"""testing package definition - Metapackage for GTest + benchmark"""

PACKAGE_INFO = {
    "name": "testing",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    "conan_requires": ["gtest/1.14.0", "benchmark/1.8.3"],
    "cmake_file": "testing.cmake",
    # CMake variables (MODE will be added automatically by toolchain)
    "cmake_vars": {
        "GTEST_GITHUB_REPO": "google/googletest",
        "GTEST_GIT_TAG": "v1.14.0",
        "GTEST_OPTIONS": [
            "INSTALL_GTEST ON",
            "BUILD_GMOCK ON",
        ],
        "BENCHMARK_GITHUB_REPO": "google/benchmark",
        "BENCHMARK_GIT_TAG": "v1.8.3",
        "BENCHMARK_OPTIONS": [
            "BENCHMARK_ENABLE_TESTING OFF",
            "BENCHMARK_ENABLE_INSTALL ON",
        ],
    },
}

PACKAGE_INFO = {
    "name": "testing",
    "modes": ["AUTO", "CONAN", "CPM", "SYSTEM", "DISABLED"],
    # Meta-package: multiple Conan requirements
    "conan_requires": ["gtest/1.14.0", "benchmark/1.8.3"],
    "cmake_file": "testing.cmake",
}

def get_cmake_vars(conanfile, mode):
    """
    Generate testing-specific CMake variables.
    
    Args:
        conanfile: ConanFile instance
        mode: Selected mode (AUTO/CONAN/CPM/SYSTEM/DISABLED)
    
    Returns:
        dict: CMake variables (will be prefixed with TESTING_)
    """
    vars_dict = {"MODE": mode}
    
    # CPM configuration (used in CPM and AUTO modes)
    if mode in ("CPM", "AUTO"):
        vars_dict.update({
            "GTEST_GITHUB_REPO": "google/googletest",
            "GTEST_GIT_TAG": "main",
            "GTEST_OPTIONS": [
                "BUILD_GMOCK ON",
                "INSTALL_GTEST OFF",
                "gtest_force_shared_crt ON",
            ],
            "BENCHMARK_GITHUB_REPO": "google/benchmark",
            "BENCHMARK_GIT_TAG": "main",
            "BENCHMARK_OPTIONS": [
                "BENCHMARK_ENABLE_TESTING OFF",
                "BENCHMARK_ENABLE_INSTALL OFF",
                "BENCHMARK_INSTALL_DOCS OFF",
                "BENCHMARK_ENABLE_GTEST_TESTS OFF",
                "BENCHMARK_ENABLE_ASSEMBLY_TESTS OFF",
            ],
        })
    
    return vars_dict
