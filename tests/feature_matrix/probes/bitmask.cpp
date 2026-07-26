#include <bitmask/bitmask.hpp>

enum class Flag : unsigned { first = 1U, second = 2U };
BITMASK_DEFINE_MAX_ELEMENT(Flag, second)

int main()
{
    const auto flags = Flag::first | Flag::second;
    return flags.bits() == 3U ? 0 : 1;
}
