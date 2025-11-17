"""perflibs - Performance libraries metapackage configuration

perflibs provides OpenMP and Threads support.
Default mode is SYSTEM since these are typically system-provided.
"""

from pathlib import Path

PACKAGE_INFO = {
    "name": "perflibs",
    "modes": ["SYSTEM", "AUTO", "DISABLED"],  # SYSTEM only (AUTO falls back to SYSTEM)
    "conan_requires": [],  # No Conan packages - system-provided
    "cmake_file": "perflibs.cmake",
    # No dependencies
    "cmake_vars": {},
}
