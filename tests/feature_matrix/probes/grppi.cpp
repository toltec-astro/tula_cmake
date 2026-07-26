#include <tuple>
#include <vector>

#include <grppi/grppi.h>

int main()
{
    static_assert(grppi::is_supported<grppi::sequential_execution>());
    const grppi::sequential_execution execution;
    return execution.concurrency_degree() == 1 ? 0 : 1;
}
