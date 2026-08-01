include(FindPackageHandleStandardArgs)

find_path(
    TulaNetcdfCxx4_INCLUDE_DIR
    NAMES netcdf
    DOC "NetCDF C++4 include directory"
)
find_library(
    TulaNetcdfCxx4_CXX_LIBRARY
    NAMES netcdf-cxx4 netcdf_c++4
    DOC "NetCDF C++4 library"
)
find_library(
    TulaNetcdfCxx4_C_LIBRARY
    NAMES netcdf
    DOC "NetCDF C library"
)

find_package_handle_standard_args(
    TulaNetcdfCxx4
    REQUIRED_VARS
        TulaNetcdfCxx4_INCLUDE_DIR
        TulaNetcdfCxx4_CXX_LIBRARY
        TulaNetcdfCxx4_C_LIBRARY
)

mark_as_advanced(
    TulaNetcdfCxx4_INCLUDE_DIR
    TulaNetcdfCxx4_CXX_LIBRARY
    TulaNetcdfCxx4_C_LIBRARY
)
