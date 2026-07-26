#include <fmt/format.h>
#include <spdlog/spdlog.h>

#include <string>

int main()
{
    const std::string message = fmt::format("feature matrix {}", 3);
    spdlog::info(message);
    return message == "feature matrix 3" ? 0 : 1;
}
