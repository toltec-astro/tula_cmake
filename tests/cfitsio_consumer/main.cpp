#include <CCfits/CCfits>
#include <fitsio.h>

#include <iostream>

int main() {
    float cfitsio_version = 0.0F;
    fits_get_version(&cfitsio_version);

    // Referencing both APIs verifies that the aggregate target propagates the
    // C and C++ FITS headers and libraries to a downstream consumer.
    CCfits::FITS::setVerboseMode(false);
    std::cout << "cfitsio=" << cfitsio_version << " ccfits=available\n";
    return cfitsio_version > 0.0F ? 0 : 1;
}
