"""NetCDF package definition - Network Common Data Form"""

PACKAGE_INFO = {
    "name": "NetCDF",
    "modes": ["AUTO", "CONAN", "SYSTEM", "DISABLED"],  # No CPM support
    "conan_requires": ["netcdf-c/4.9.0"],  # Use netcdf-c package name
    "cmake_file": "NetCDF.cmake",
    "cmake_vars": {},
}
