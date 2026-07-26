from conan import ConanFile


class TulaFeatureMatrixRecipe(ConanFile):
    name = "tula-feature-matrix"
    version = "3.1.0"
    required_conan_version = ">=2.31"
    python_requires = "tula-cmake/3.1.0"
    python_requires_extend = "tula-cmake.TulaConan"
    settings = ()
    options = {}  # noqa: RUF012
    default_options = {  # noqa: RUF012
        "boost/*:header_only": True,
        "ceres-solver/*:use_schur_specializations": False,
        "fftw/*:precision_single": False,
        "fftw/*:precision_longdouble": False,
    }
