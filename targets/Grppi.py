"""Grppi package definition - Parallel patterns library"""

PACKAGE_INFO = {
    "name": "Grppi",
    "modes": ["AUTO", "CPM", "DISABLED"],  # Header-only, CPM only
    "conan_requires": [],
    "cmake_file": "Grppi.cmake",
    # Required dependencies
    "depends_on": ["perflibs", "Enum"],  # Needs perflibs for OpenMP/threading
    "cmake_vars": {
        "CPM_GITHUB_REPO": "Jerry-Ma/grppi",
        "CPM_GIT_TAG": "cpp20",
    },
}
