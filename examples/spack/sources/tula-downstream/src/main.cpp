#include <iostream>

#include <tula_boilerplate/boilerplate.h>
#include <tula_lib_b/config.h>

int main()
{
    tula_boilerplate::log_summary();
    std::cout << "tula_downstream " << tula_boilerplate::summary()
              << " libB=" << tula_lib_b::flavor << '\n';
}

