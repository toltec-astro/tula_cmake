#include <csv_parser/parser.hpp>

#include <sstream>
#include <string>
#include <vector>

int main()
{
    std::istringstream input{"name;value\n\"detector;1\";42\n"};
    auto parser = aria::csv::CsvParser(input).delimiter(';');
    std::vector<std::vector<std::string>> rows;
    for (const auto &row : parser) {
        rows.push_back(row);
    }

    if (rows.size() != 2 || rows[0] != std::vector<std::string>{"name", "value"}) {
        return 1;
    }
    return rows[1] == std::vector<std::string>{"detector;1", "42"} ? 0 : 2;
}
