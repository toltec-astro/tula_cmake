#include <fixture/config.h>
#include <fixture/fixture.h>
#include <fixture/version.h>

#include <iostream>

int main()
{
    static_assert(TULA_CMAKE_FIXTURE_HAS_EXAMPLE == 1);
    std::cout << "consumer " << fixture::summary() << '\n';
}
