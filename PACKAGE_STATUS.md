# Package Status — tula v3

All packages defined in `targets/packages.yaml`. Mode support and test coverage below.

---

## Package Mode Support

| Package | CONAN | CPM | SYSTEM | Conan ref | Notes |
|---------|:-----:|:---:|:------:|-----------|-------|
| **Ceres** | ✅ | ✅ | ✅ | `ceres-solver/2.2.0` | Nonlinear least-squares; depends on Eigen3 |
| **Clipp** | ✅ | ✅ | ✅ | `clipp/1.2.3` | CLI argument parser |
| **Csv** | — | ✅ | — | — | CSV parser; CPM only |
| **Eigen3** | ✅ | ✅ | ✅ | `eigen/3.4.0` | Linear algebra |
| **Enum** | — | ✅ | — | — | `meta_enum` + `bitmask`; CPM only |
| **Grppi** | — | ✅ | — | — | Parallel patterns; CPM only (cpp20 branch) |
| **logging** | ✅ | ✅ | ✅ | `spdlog/1.15.3` | Metapkg: spdlog + fmt/11.2.0 |
| **NetCDF** | ✅ | — | ✅ | `netcdf/4.8.1` | C NetCDF library |
| **NetCDFCXX4** | — | ✅ | ✅ | — | NetCDF C++ bindings; depends on NetCDF |
| **perflibs** | — | — | ✅ | — | Metapkg: OpenMP + Threads; system only |
| **Spectra** | ✅ | ✅ | ✅ | `spectra/1.0.1` | Eigenvalue solver; depends on Eigen3 |
| **testing** | ✅ | ✅ | ✅ | `gtest/1.14.0` + `benchmark/1.8.3` | GTest + Google Benchmark |
| **Yaml** | ✅ | ✅ | ✅ | `yaml-cpp/0.8.0` | YAML parser |

---

## Test Coverage (test_config.yaml)

| Test | Packages | Modes | Status |
|------|----------|-------|--------|
| `eigen3_basic` | Eigen3 | CONAN | ✅ tested |
| `eigen3_cpm` | Eigen3 | CPM | ✅ tested |
| `eigen3_no_threading` | Eigen3 | CONAN | ✅ tested |
| `eigen3_with_mkl` | Eigen3, perflibs | CONAN, SYSTEM | ✅ tested (MKL optional) |
| `eigen3_spectra` | Eigen3, Spectra, perflibs | CONAN, SYSTEM | ✅ tested |
| `eigen3_spectra_no_threading` | Eigen3, Spectra, perflibs | CONAN, SYSTEM | ✅ tested |
| `eigen3_ceres` | Eigen3, Ceres, perflibs | CONAN, SYSTEM | ✅ tested |
| `logging_basic` | logging | CONAN | ✅ tested |
| `yaml_conan` | Yaml | CONAN | ✅ tested |
| `yaml_cpm` | Yaml | CPM | ✅ tested |
| `testing_gtest` | testing | CONAN | ✅ tested |
| `clipp_basic` | Clipp | CPM | ✅ tested |
| `csv_basic` | Csv | CPM | ✅ tested |
| `enum_basic` | Enum | CPM | ✅ tested |
| `netcdf_system` | NetCDF | SYSTEM | ✅ tested |
| `netcdf_cxx4` | NetCDF, NetCDFCXX4 | SYSTEM | ✅ tested |
| `grppi_basic` | Grppi, perflibs | CPM, SYSTEM | ✅ tested |
| `perflibs_basic` | perflibs | SYSTEM | ✅ tested |
| `mixed_conan_cpm` | Eigen3, Clipp | CONAN, CPM | ✅ tested |

---

## Mode Coverage Summary

| Package | CONAN tested | CPM tested | SYSTEM tested | Gaps |
|---------|:---:|:---:|:---:|------|
| Ceres | ✅ | — | — | CPM/SYSTEM untested |
| Clipp | — | ✅ | — | CONAN/SYSTEM untested |
| Csv | — | ✅ | — | — (CPM only) |
| Eigen3 | ✅ | ✅ | — | SYSTEM untested |
| Enum | — | ✅ | — | — (CPM only) |
| Grppi | — | ✅ | — | — (CPM only) |
| logging | ✅ | — | — | CPM/SYSTEM untested |
| NetCDF | — | — | ✅ | CONAN untested |
| NetCDFCXX4 | — | — | ✅ | CPM untested |
| perflibs | — | — | ✅ | — (SYSTEM only) |
| Spectra | ✅ | — | — | CPM/SYSTEM untested |
| testing | ✅ | — | — | CPM/SYSTEM untested |
| Yaml | ✅ | ✅ | — | SYSTEM untested |

---

## Notable Implementation Details

### logging (spdlog/1.15.3 + fmt/11.2.0)
Upgraded from spdlog/1.12.0 to resolve Clang 20 `consteval` issues in fmt 10.
fmt 11 is a breaking change for tula headers:
- `formatter<std::byte>` is now built-in — guarded with `#if FMT_VERSION < 110000`
- `format()` methods must be `const` — fixed in all tula formatters
- `fmt::ptr(shared_ptr)` removed — callers use `.get()`

### Ceres (ceres-solver/2.2.0)
API change from Ceres 2.1:
- `SubsetParameterization` → `SubsetManifold`
- `SetParameterization()` → `SetManifold()`
Fixed in `tula/include/tula/algorithm/ei_ceresfitter.h`.

System mode requires manual toolchain-phase detection:
- `CeresConfig.cmake` calls `CheckLibraryExists` which needs C/CXX language loaded
- `tula_Ceres_add_system()` detects toolchain phase via `CMAKE_CXX_COMPILER_LOADED`
  and uses `find_library` + `find_path` + `UNKNOWN IMPORTED` as fallback

### NetCDF / NetCDFCXX4 (system mode)
`CMAKE_SYSTEM_PREFIX_PATH` is empty during toolchain phase.
`CMAKE_PREFIX_PATH` is manually extended with `/usr/lib/<arch>/cmake/<pkg>` paths.
`FindNetCDFCXX4.cmake` uses `UNKNOWN IMPORTED` (not `SHARED IMPORTED`).

### GCC compatibility
`kidsdata.h` variant specializations (`_Extra_visit_slot_needed`) apply only to
GCC 9–13: `#if (__GNUC__ >= 9 && __GNUC__ < 14)`. GCC 14+ supports inherited
variant natively.

---

## Packages Not Implemented

Lower-priority packages from the v2 reference that are not yet in v3:

| Package | Notes |
|---------|-------|
| Boost | Large; CONAN/SYSTEM preferred when needed |
| CCfits | CFITSIO C++ wrapper; astronomy-specific |
| FFTW | System library preferred; not in current kidscpp build |
| Re2 | Google RE2; not in current kidscpp build |
| GramSavgol / Savgol | Savitzky-Golay filter; header-only candidates |
| Matplotlibcpp | Requires Python; specialist use |
| MXX | MPI C++ wrapper; requires MPI stack — referenced by `examples/mpi` (to be implemented) |
