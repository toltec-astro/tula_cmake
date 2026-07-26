#include <ceres/ceres.h>

struct Residual {
    template <typename T>
    auto operator()(const T* const value, T* residual) const -> bool
    {
        residual[0] = value[0] - T{3};
        return true;
    }
};

int main()
{
    double value = 0;
    ceres::Problem problem;
    problem.AddResidualBlock(
        new ceres::AutoDiffCostFunction<Residual, 1, 1>{new Residual},
        nullptr,
        &value);
    ceres::Solver::Options options;
    options.max_num_iterations = 10;
    options.logging_type = ceres::SILENT;
    ceres::Solver::Summary summary;
    ceres::Solve(options, &problem, &summary);
    return summary.IsSolutionUsable() && value > 2.9 ? 0 : 1;
}
