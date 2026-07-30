#include <fixture/fixture.h>

#include <fixture/config.h>
#include <fixture/version.h>

namespace fixture {

std::string summary()
{
    static_assert(TULA_CMAKE_FIXTURE_HAS_EXAMPLE == 1);
    return std::string{version} + "@" + std::string{git_revision};
}

}  // namespace fixture
