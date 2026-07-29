#include <tula_boilerplate/boilerplate.h>

#include <fmt/format.h>
#include <iostream>

int main()
{
    std::cout << fmt::format(
        "tula_downstream -> tula_boilerplate {}",
        tula_boilerplate::version
    ) << '\n';
    std::cout << "source-superbuild logging provider: "
              << tula_boilerplate::logging_provider << '\n';
    return 0;
}
