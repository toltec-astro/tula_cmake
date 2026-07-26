#include <fftw3.h>

int main()
{
    auto* data = fftw_alloc_complex(4);
    if (data == nullptr) {
        return 1;
    }
    fftw_free(data);
    return 0;
}
