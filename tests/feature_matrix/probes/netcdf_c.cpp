#include <netcdf.h>

#include <string_view>

int main()
{
    const auto version = std::string_view{nc_inq_libvers()};
    if (version.empty()) {
        return 1;
    }

    int id = -1;
    if (nc_create("tula-netcdf-matrix.nc", NC_DISKLESS, &id) != NC_NOERR) {
        return 2;
    }
    return nc_close(id) == NC_NOERR ? 0 : 3;
}
