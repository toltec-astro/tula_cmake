#include <boost/math/special_functions/bessel.hpp>

#include <cmath>

int main()
{
    return std::abs(boost::math::cyl_bessel_j(0, 0.0) - 1.0) < 1e-12 ? 0 : 1;
}
