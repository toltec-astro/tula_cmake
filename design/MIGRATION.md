# Migration status

## 1. Preserved baseline

| Repository | Preserved branch | Archived commit | Active branch |
| --- | --- | --- | --- |
| TulaCMake | `v3.x_conan2` | `0745f99` | `v3.x_spack` |
| Tula | `v3.x` | `08ae265` | `v3.x_spack` |
| Kidscpp | `v3.x` | `2ae77e9` | `v3.x_spack` |
| Citlali | `v4.x_conan2` | `bfb9378` | `v3.x_spack` |
| Tlaloc | `main` | `e967166` | `tula_ecsv_with_spack` |

Self-contained clones of the four Conan-era repositories are stored in
`archive/v3-conan2-baseline-2026-07-30`. Tlaloc's clean Git commit is its
baseline. Read-only `refs/` repositories remain behavioral evidence and are
never build inputs.

The old Conan design files formerly under `tula/design/` are additionally
indexed under `tula/design/archive/conan2/`.

## 2. Accepted infrastructure slice

- TulaCMake is an installed CMake-only package.
- Spack owns dependency resolution, source acquisition, variants, and the
  concrete graph.
- The boilerplate/downstream fixture proves root control of direct and
  transitive variants.
- TulaCMake utilities are target-scoped and pass an installed
  producer/consumer test.
- Export helpers preserve target-owned include contracts and do not inject a
  synthetic include directory.

## 3. Accepted Tula ECSV slice

- Third-party adapters use the provider-faithful `tula_deps::*` namespace.
- Tula's higher-level components use `tula::*`.
- `tula+ecsv` concretizes only logging, YAML, Eigen, csv-parser, and the ECSV
  component.
- Direct adapter-only consumers do not find Tula.
- Tula consumers require explicit CMake components.
- Missing required components fail at configure time.
- Ten package tests, including real TolTEC tune reports, pass under GCC 14 and
  LLVM 20 in C++23 mode.

## 4. Accepted Tula perflibs slice

- `tula_deps::perflibs` is the provider-faithful Threads/OpenMP adapter.
- `tula::perflibs` is the explicit higher-level Tula component.
- `+openmp` is optional and remains orthogonal to `+perflibs`.
- Tula and adapter capability macros have distinct ownership.
- Four minimal roots—GCC 14 and LLVM 20, each `+openmp` and `~openmp`—pass
  package tests and installed-component consumers.
- The concrete graphs contain no unrelated Tula component or heavy dependency.

## 5. Production migration status

The enum and CLI slices are now accepted independently:

- `+enum` brings only logging, bitmask, and meta-enum;
- `+cli` adds Clipp and requires enum;
- focused package tests and installed consumers pass under GCC 14 and LLVM 20.
- NetCDF C++ discovery is normalized by `tula_deps::netcdf_cxx4`; the focused
  component and installed file-I/O consumer pass in both lanes.
- GrPPI's adapter no longer carries Tula-specific dependencies; its four-case
  OpenMP matrix passes in both compiler lanes.
- The fitting slice contains only logging, Eigen, and canonical
  `Ceres::ceres`; package and installed-consumer tests pass in both lanes.

The production chain through Citlali is complete:

1. every Tula component required by Kidscpp and Citlali has a focused package
   and installed-consumer gate;
2. Kidscpp requests its exact Tula component closure and passes seven tests,
   including real NetCDF metadata and slice ingestion, under GCC 14 and LLVM
   20;
3. Citlali retains the Kidscpp reader/solver ownership boundary, passes six
   package tests and its installed consumer/CLI gates in both compiler lanes;
   and
4. the installed GCC 14 Citlali CLI completes observation 149101, processes
   all 123 scans, and writes raw and filtered products for all three arrays.

The narrow Tlaloc migration is accepted from its clean `main` baseline on
`tula_ecsv_with_spack`:

- Tlaloc requests only `tula COMPONENTS ecsv` and links `tula::ecsv`;
- its own NetCDF C++4, FFTW, MariaDB, and pinned KATCP dependencies remain
  direct package edges;
- the obsolete Kidscpp IQ-to-Rx/Rx-to-IQ model path and duplicated ECSV parser
  are removed without changing the remaining readout-controller behavior;
- the complete `tlaloc_clip` executable builds in both compiler lanes; and
- a required package test loads the observation 149101 tune report and checks
  all fourteen columns plus observation metadata.

The Tlaloc graph is now asserted to exclude Kidscpp and Ceres and is included
in the accepted `just all` gate.

The rejected broad Tlaloc attempt remains historical evidence only; the active
branch was restarted from clean commit `e967166`.

## 6. Compiler policy

The supported container lanes are GCC 14.2 and LLVM/Clang 20.1.2, both C++23.
GCC 13 is intentionally omitted. oneAPI/MKL remains outside current scope.
A future macOS lane must select and validate Homebrew LLVM major version 20;
native AppleClang is not that lane.

## 7. Release work

Local development uses Spack `develop` paths. Publishing later requires:

1. immutable source URLs and checksums for released TolTEC packages;
2. stable composition of the decentralized recipe repositories;
3. portable release lock files without local paths;
4. the same compiler/component gates against release archives; and
5. optional signed buildcache configuration.
