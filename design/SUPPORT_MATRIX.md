# Support matrix and public target catalog

This page records measured behavior on the unpublished `v3.x_spack` branch.
Recipes and CMake declarations are authoritative. “Planned” means that source
or an early recipe may exist, but the current component acceptance gate does
not claim it.

## 1. Measured platform

| Item | GCC lane | LLVM lane |
| --- | --- | --- |
| Operating system | Ubuntu 24.04 arm64 | Ubuntu 24.04 arm64 |
| Compiler | GCC 14.2.0 | LLVM/Clang 20.1.2 |
| C++ mode | C++23 | C++23 |
| CMake | 3.28.3 | 3.28.3 |
| Spack | 1.2.2 | 1.2.2 |
| `tula+ecsv` package tests | 10/10 | 10/10 |
| Direct adapter consumer | pass | pass |
| Installed ECSV consumer | pass | pass |
| Missing component rejection | pass | pass |
| `tula+perflibs+openmp` | pass | pass |
| `tula+perflibs~openmp` | pass | pass |
| Installed perflibs consumers | 2/2 | 2/2 |
| Minimal enum component | pass | pass |
| Minimal CLI component | pass | pass |
| Minimal NetCDF component | pass | pass |
| `tula+grppi+openmp` | pass | pass |
| `tula+grppi~openmp` | pass | pass |
| Minimal fitting component | pass | pass |
| CFITSIO/CCfits external adapter | pass | pass |
| CFITSIO/CCfits source adapter | pass | pass |
| Full Tula package | 16/16 | 16/16 |
| Kidscpp package | 7/7 | 7/7 |
| Citlali package | 6/6 | 6/6 |
| Installed Tula/Kidscpp/Citlali consumers | 3/3 | 3/3 |
| Installed Citlali CLI | pass | pass |
| Tlaloc package and real tune-reader test | pass | pass |
| Installed Tlaloc executable present | pass | pass |

The focused CCfits/CFITSIO adapter and the complete Citlali root are also
measured on native macOS 26 arm64 with Homebrew LLVM 20.1.8 and C++23.
Citlali's six package tests and installed CLI pass with `~openmp`; AppleClang
is not substituted. Homebrew GCC 14.3 supplies only the Fortran build edge.

## 2. Root workflows

| Workflow | What it proves | Command | Status |
| --- | --- | --- | --- |
| TulaCMake installed fixture | TulaCMake installs; a separate producer and consumer use the installed modules | `just unit` | Measured |
| Spack boilerplate/downstream slice | Direct and transitive variant constraints, local develop sources, environment views | `just spack-matrix` | Measured with GCC 14 |
| Tula ECSV component slice | Minimal component closure, adapters, installed discovery, real tune reports | `just tula-component-matrix` | Measured with GCC 14 and LLVM 20 |
| Tula perflibs component slice | Threads baseline, optional compiler OpenMP, minimal graph, installed discovery | `just tula-perflibs-matrix` | Four cases measured with GCC 14 and LLVM 20 |
| Tula enum/CLI slices | Exact reflected-enum and typed-CLI closures with installed consumers | `just tula-enum-cli-matrix` | Four cases measured with GCC 14 and LLVM 20 |
| Tula NetCDF slice | Normalized NetCDF C++ target, exact closure, file I/O, installed consumer | `just tula-netcdf-matrix` | Measured with GCC 14 and LLVM 20 |
| Tula GrPPI slice | Clean adapter boundary and optional OpenMP execution mode | `just tula-grppi-matrix` | Four cases measured with GCC 14 and LLVM 20 |
| Tula fitting slice | Minimal logging/Eigen/Ceres closure and installed consumer | `just tula-fitting-matrix` | Measured with GCC 14 and LLVM 20 |
| CCfits/CFITSIO adapter | Aggregate target plus external/source provider policy | `just tula-ccfits-matrix` | Four cases: GCC 14 and LLVM 20 × external and source |
| Tula → Kidscpp → Citlali | Exact non-skipped package-test totals, installed consumers, and installed CLI | `just production-matrix` | Measured with GCC 14 and LLVM 20 |
| Citlali observation 149101 | Eleven TolTEC streams, telescope stream, APT, 123 scans, raw/filtered FITS output | `just citlali-real-workdir` | Measured with GCC 14 |
| Tlaloc | Minimal Tula ECSV closure, full CLI build, real tune-report reader, no Kidscpp/Ceres | `just tlaloc-matrix` | Measured with GCC 14 and LLVM 20 |

## 3. Dependency adapter packages

The adapter package and target names retain the underlying provider identity.
They may be consumed without finding Tula.

| Spack package | Config package | Public target | Upstream dependency | Status |
| --- | --- | --- | --- | --- |
| `tula-logging@1.0.0` | `TulaLogging` | `tula_deps::logging` | fmt 9.1.0 + spdlog 1.12.0 | Measured |
| `tula-yaml-cpp@0.8.0` | `TulaYamlCpp` | `tula_deps::yaml_cpp` | yaml-cpp 0.8.0 | Measured |
| `tula-csv-parser@2020.06.12` | `TulaCsvParser` | `tula_deps::csv_parser` | pinned Jerry-Ma csv-parser | Measured |
| `tula-eigen3@3.4.0` | `TulaEigen3` | `tula_deps::eigen3` | Eigen 3.4.0 | Measured |
| `tula-perflibs@0.1.0` | `TulaPerflibs` | `tula_deps::perflibs` | Threads and optional compiler OpenMP | Measured with OpenMP enabled and disabled |
| `tula-netcdf-cxx4@4.3.1` | `TulaNetcdfCxx4` | `tula_deps::netcdf_cxx4` | NetCDF C++4 4.3.1 | Measured |
| `tula-ccfits@1.0.0` | `TulaCcfits` | `tula_deps::ccfits` | CCfits 2.6 + CFITSIO 4.3+ | Measured external/source under GCC 14 and LLVM 20; source under macOS LLVM 20.1.8 |

Logging, YAML, Eigen, perflibs, NetCDF, and FITS build small relocatable packages
from `tula_cmake/packages/`. csv-parser's generic Spack recipe installs its
pinned headers and config file directly.

## 4. Tula component matrix

| Spack variant | CMake option | Tula component target | Capability macro | Required closure | Status |
| --- | --- | --- | --- | --- | --- |
| always | always | `tula::core` | `TULA_VERSION` | none | Measured |
| `+logging` | `TULA_ENABLE_LOGGING` | `tula::logging` | `TULA_HAS_LOGGING` | `tula_deps::logging` | Measured |
| `+yaml` | `TULA_ENABLE_YAML` | `tula::yaml` | `TULA_HAS_YAML` | `+logging`, `tula_deps::yaml_cpp` | Measured |
| `+eigen` | `TULA_ENABLE_EIGEN` | `tula::eigen` | `TULA_HAS_EIGEN` | `+logging`, `tula_deps::eigen3` | Measured |
| `+ecsv` | `TULA_ENABLE_ECSV` | `tula::ecsv` | `TULA_HAS_ECSV` | `+logging+yaml+eigen`, `tula_deps::csv_parser` | Measured |
| `+netcdf` | `TULA_ENABLE_NETCDF` | `tula::netcdf` | `TULA_HAS_NETCDF` | `+logging+eigen`, `tula_deps::netcdf_cxx4` | Measured |
| `+enum` | `TULA_ENABLE_ENUM` | `tula::enum` | `TULA_HAS_ENUM` | `+logging`, `tula_deps::bitmask`, `tula_deps::meta_enum` | Measured |
| `+cli` | `TULA_ENABLE_CLI` | `tula::cli` | `TULA_HAS_CLI` | `+logging+enum`, `tula_deps::clipp` | Measured |
| `+perflibs` | `TULA_ENABLE_PERFLIBS` | `tula::perflibs` | `TULA_HAS_PERFLIBS`, `TULA_HAS_OPENMP` | `tula_deps::perflibs`; `+openmp` is optional | Measured |
| `+grppi` | `TULA_ENABLE_GRPPI` | `tula::grppi` | `TULA_HAS_GRPPI` | `+logging+enum+perflibs`, `tula_deps::grppi`; optional `+openmp` | Measured |
| `+fitting` | `TULA_ENABLE_FITTING` | `tula::fitting` | `TULA_HAS_FITTING` | `+logging+eigen`, `Ceres::ceres` | Measured |

There is no `+csv` Tula component. csv-parser is a dependency adapter used by
the higher-level ECSV component. There is no `tula::headers` umbrella.

## 5. Public CMake calls

| Call | Result |
| --- | --- |
| `find_package(TulaCMake 3 CONFIG REQUIRED)` | Loads target-scoped CMake helper functions |
| `find_package(TulaYamlCpp CONFIG REQUIRED)` | Defines `tula_deps::yaml_cpp` without Tula |
| `find_package(TulaCsvParser CONFIG REQUIRED)` | Defines `tula_deps::csv_parser` without Tula |
| `find_package(TulaEigen3 CONFIG REQUIRED)` | Defines `tula_deps::eigen3` without Tula |
| `find_package(TulaLogging CONFIG REQUIRED)` | Defines `tula_deps::logging` without Tula |
| `find_package(tula 3.1 CONFIG REQUIRED COMPONENTS ecsv)` | Defines `tula::core`, the installed component closure, and `tula::ecsv` |
| `find_package(TulaPerflibs CONFIG REQUIRED)` | Defines `tula_deps::perflibs` with Threads and its configured OpenMP state |
| `find_package(tula 3.1 CONFIG REQUIRED COMPONENTS perflibs)` | Defines `tula::core` and `tula::perflibs`; reconstructs the adapter dependency |
| `find_package(tula 3.1 CONFIG REQUIRED COMPONENTS enum)` | Defines `tula::enum` and reconstructs logging, bitmask, and meta-enum |
| `find_package(tula 3.1 CONFIG REQUIRED COMPONENTS cli)` | Defines `tula::cli` and its enum/Clipp closure |
| `find_package(TulaNetcdfCxx4 CONFIG REQUIRED)` | Defines `tula_deps::netcdf_cxx4` without Tula |
| `find_package(TulaCcfits CONFIG REQUIRED)` | Defines `tula_deps::ccfits` for the CCfits API and required CFITSIO implementation |
| `find_package(tula 3.1 CONFIG REQUIRED COMPONENTS netcdf)` | Defines `tula::netcdf` with its Eigen and NetCDF C++ closure |
| `find_package(tula 3.1 CONFIG REQUIRED COMPONENTS grppi)` | Defines `tula::grppi` and its logging/enum/perflibs closure |
| `find_package(tula 3.1 CONFIG REQUIRED COMPONENTS fitting)` | Defines `tula::fitting` with logging, Eigen, and Ceres |
| `find_package(kidscpp 3.1 CONFIG REQUIRED)` | Defines the installed `kids::kids` reader/solver target |
| `find_package(citlali 4 CONFIG REQUIRED)` | Defines the installed `citlali::citlali` engine target |

Requesting a component absent from the concrete Tula installation makes
`tula_FOUND` false at configure time.

## 6. Real-data coverage

The ECSV matrix uses the same reader source installed-consumer examples use.
It validates:

- fourteen expected tune-report columns;
- nonempty typed Eigen-backed storage;
- finite `f_out` and `Qr` values;
- Astropy ordered-map metadata through `meta_to_map`; and
- positive observation identifiers.

The dev-container gate currently loads eleven regular reports under
`tolteca_test_data/data_lmt/toltec/reduced`. Valid work-directory report
symlinks are preferred when their external targets are mounted.

The Tlaloc package test independently reads the observation 149101 tune file
from `tolteca_test_data/tolteca_workdir/data`. It checks a nonempty table, the
fourteen-column schema, finite endpoint values, and ObsNum/SubObsNum/ScanNum
metadata. The fixture is required: its absence fails configuration rather than
silently skipping the test.

The observation-level Citlali gate uses the work-directory fixture at
`tolteca_test_data/tolteca_workdir/redu/citlali_o149101_0_2_c1.yaml`.
Its raw-data symlinks resolve through a read-only devcontainer mount of
`toltec_astro/run`; generated products go to
`/tmp/citlali-o149101-output`. The measured run completed all 123 scans and
wrote raw and filtered FITS products for a1100, a1400, and a2000.
