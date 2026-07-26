#include <yaml-cpp/yaml.h>

#include <string>

int main()
{
    const auto document = YAML::Load("name: tula\nversion: 3\n");
    if (document["name"].as<std::string>() != "tula") {
        return 1;
    }
    if (document["version"].as<int>() != 3) {
        return 2;
    }
    return YAML::Dump(document).empty() ? 3 : 0;
}
