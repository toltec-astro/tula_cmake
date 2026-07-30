#include <fixture/config.h>
#include <fixture/version.h>

#include <iostream>

int main()
{
    static_assert(TULA_CMAKE_FIXTURE_HAS_EXAMPLE == 1);
    std::cout << fixture::version << '@' << fixture::git_revision << '\n';
}
