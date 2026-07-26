#include <netcdf>

#include <filesystem>
#include <vector>

int main()
{
    namespace fs = std::filesystem;
    using namespace netCDF;

    const auto path = fs::path{"tula-netcdf-cxx4-matrix.nc"};
    {
        auto file = NcFile(path.string(), NcFile::replace);
        const auto sample = file.addDim("sample", 3);
        auto values = file.addVar("values", ncInt, sample);
        const std::vector<int> output{1, 2, 3};
        values.putVar(output.data());
    }

    std::vector<int> input(3);
    {
        auto file = NcFile(path.string(), NcFile::read);
        file.getVar("values").getVar(input.data());
    }
    fs::remove(path);
    return input == std::vector<int>{1, 2, 3} ? 0 : 1;
}
