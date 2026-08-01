"""TolTEC override for the dormant NetCDF C++4 4.3.1 CMake release."""

from spack.package import patch
from spack_repo.builtin.packages.netcdf_cxx4.package import (
    NetcdfCxx4 as BuiltinNetcdfCxx4,
)


class NetcdfCxx4(BuiltinNetcdfCxx4):
    """Retain the builtin recipe while repairing imported HDF5 metadata."""

    patch("netcdf-cxx4-hdf5-hl-target.patch", when="@4.3.1")
