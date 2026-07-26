#include <clipp.h>

#include <string>

int main()
{
    bool verbose = false;
    int count = 0;
    std::string input;
    const auto cli = (
        clipp::option("-v", "--verbose").set(verbose),
        clipp::option("-n", "--count") & clipp::value("count", count),
        clipp::value("input", input));

    const auto result =
        clipp::parse({"--verbose", "--count", "3", "sample.dat"}, cli);
    return result && verbose && count == 3 && input == "sample.dat" ? 0 : 1;
}
