#include <csv_parser/parser.hpp>
#include <fmt/format.h>
#include <yaml-cpp/yaml.h>

#include <Eigen/Core>

#include <string>

int main() {
    const auto config = YAML::Load("value: 42");
    const Eigen::Vector2i values{config["value"].as<int>(), 1};
    const auto message = fmt::format("{}:{}", values[0], values[1]);
    return message == "42:1" ? 0 : 1;
}
