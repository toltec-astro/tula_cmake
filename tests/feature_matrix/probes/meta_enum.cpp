#include <meta_enum/meta_enum.hpp>

#include <array>

enum class Color : int { red, green, blue };

constexpr auto color_meta = meta_enum::internal::parseMetaEnum<Color, int, 3>(
    "Color",
    "red, green, blue",
    std::array{Color::red, Color::green, Color::blue});

int main()
{
    return color_meta.name == "Color"
            && color_meta.members[1].name == "green"
            && color_meta.members[1].value == Color::green
        ? 0
        : 1;
}
