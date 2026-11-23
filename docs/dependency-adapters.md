# Dependency adapters

An adapter is an installed CMake package that gives one target for a
third-party library, whichever provider supplied it. Link the adapter target
instead of the library's own targets.

## Adapters

| Spack package | `find_package` | Target | Wraps |
| --- | --- | --- | --- |
| `tula-logging` | `TulaLogging` | `tula_deps::logging` | fmt 9.1.0+ and spdlog 1.12.0+ (1.x) |
| `tula-yaml-cpp` | `TulaYamlCpp` | `tula_deps::yaml_cpp` | yaml-cpp 0.8.0+ |
| `tula-csv-parser` | `TulaCsvParser` | `tula_deps::csv_parser` | csv-parser (pinned commit) |
| `tula-eigen3` | `TulaEigen3` | `tula_deps::eigen3` | Eigen 3.4.0+ (3.x) |
| `tula-perflibs` | `TulaPerflibs` | `tula_deps::perflibs` | Threads and, with `+openmp`, OpenMP |
| `tula-netcdf-cxx4` | `TulaNetcdfCxx4` | `tula_deps::netcdf_cxx4` | NetCDF C++4 4.3.1+ and NetCDF C |
| `tula-ccfits` | `TulaCcfits` | `tula_deps::ccfits` | CCfits 2.6+ and CFITSIO 4.3+ |

Tula owns `tula-bitmask`, `tula-clipp`, `tula-grppi` and `tula-meta-enum`.

## Use an adapter

```cmake
find_package(TulaCcfits CONFIG REQUIRED)
target_link_libraries(my_app PRIVATE tula_deps::ccfits)
```

In the recipe:

```python
depends_on("tula-ccfits@1.0:1", type=("build", "link"))
```

You do not need Tula to use an adapter. To use a Tula component, request it
from Tula; the component brings its adapters:

```cmake
find_package(tula 3.1 CONFIG REQUIRED COMPONENTS ecsv)
target_link_libraries(my_app PRIVATE tula::ecsv)
```

If the installed Tula lacks a requested component, `tula_FOUND` is false and
configuration fails. Tula's `design/COMPONENTS.md` lists the components and
their variants.

| Namespace | Meaning | Example |
| --- | --- | --- |
| `tula_deps::` | adapter, named after the library | `tula_deps::yaml_cpp` |
| `tula::` | Tula component with its own API | `tula::yaml` |

## Choose a provider

The provider is Spack configuration: a system external or a Spack build.
The target and the C++ code are the same for both. For example, these
`packages.yaml` entries build CCfits and CFITSIO with Spack instead of using
the system libraries:

```yaml
packages:
  cfitsio::
    require: "@4.6.3+bzip2~fortran"
    buildable: true
  ccfits::
    require: "@2.6"
    buildable: true
```

## OpenMP

Only `tula-perflibs` finds OpenMP. Enable it with the `openmp` variant;
Kidscpp and Citlali have the same variant and pass it to Tula:

```console
spack -e <env> add citlali+openmp
```

Link `tula_deps::perflibs` (or `tula::perflibs`) and test the capability in
C++:

```cpp
#include <tula_perflibs/config.h>
#if TULA_PERFLIBS_HAS_OPENMP
#include <omp.h>
#endif
```

The installed adapter keeps the OpenMP flags and runtime that it was built
with. On macOS with Homebrew LLVM 20, Spack builds the matching
`llvm-openmp`, and consumers link that runtime.
