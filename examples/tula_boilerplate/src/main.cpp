#include <tula_boilerplate/boilerplate.h>

#include <iostream>

int main()
{
    static_assert(TULA_BOILERPLATE_HAS_LOGGING == 1);
    static_assert(TULA_BOILERPLATE_HAS_PERFLIBS == 1);
    tula_boilerplate::log_summary();
    std::cout << "tula_boilerplate " << tula_boilerplate::version << ' '
              << tula_boilerplate::summary() << '\n';
}
