#include <Eigen/Core>

#ifndef TULA_EIGEN_MULTITHREADING
#error "eigen matrix case did not publish its multithreading state"
#endif

#if defined(EIGEN_DONT_PARALLELIZE) && TULA_EIGEN_MULTITHREADING
#error "eigen disabled multithreading state is inconsistent"
#endif

#if !defined(EIGEN_DONT_PARALLELIZE) && !TULA_EIGEN_MULTITHREADING
#error "eigen enabled multithreading state is inconsistent"
#endif

int main()
{
    const Eigen::Matrix2d matrix{{1.0, 2.0}, {3.0, 4.0}};
    const Eigen::Vector2d vector{1.0, 1.0};
    return (matrix * vector).isApprox(Eigen::Vector2d{3.0, 7.0}) ? 0 : 1;
}
