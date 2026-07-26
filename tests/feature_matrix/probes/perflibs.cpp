#ifndef TULA_PERFLIBS_HAS_THREADS
#error "perflibs matrix case did not publish thread capability"
#endif

#ifndef TULA_PERFLIBS_HAS_OPENMP
#error "perflibs matrix case did not publish OpenMP capability"
#endif

#ifndef TULA_PERFLIBS_HAS_MKL
#error "perflibs matrix case did not publish oneMKL capability"
#endif

#include <thread>

int main()
{
    static_assert(TULA_PERFLIBS_HAS_THREADS == 1);
#ifdef TULA_MATRIX_EXPECT_MKL
    static_assert(TULA_PERFLIBS_HAS_MKL == TULA_MATRIX_EXPECT_MKL);
#endif
#ifdef TULA_MATRIX_EXPECT_OPENMP
    static_assert(TULA_PERFLIBS_HAS_OPENMP == TULA_MATRIX_EXPECT_OPENMP);
#endif
    std::thread worker([] {});
    worker.join();
    return 0;
}
