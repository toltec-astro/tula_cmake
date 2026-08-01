# Testing strategy

## 1. Rule

Every feature is tested at the boundary it creates. Examples remain readable
usage examples; feature combinations and negative cases live in dedicated
fixtures and Spack environments.

## 2. Test layers

| Layer | Boundary exercised | Current command |
| --- | --- | --- |
| TulaCMake unit fixture | Installed helper modules, producer export, separate consumer | `just unit` |
| Spack vertical slice | Variants, transitive root constraints, develop sources, package tests, environment view | `just spack-matrix` |
| Adapter consumer | Four `tula_deps::*` configs and targets, no Tula discovery or headers | part of `just tula-component-matrix` |
| Tula package tests | Enabled component headers and behavior in the package build | `spack install --test=all` |
| Installed component consumer | `find_package(tula COMPONENTS ecsv)` and `tula::ecsv` | part of `just tula-component-matrix` |
| Negative component fixture | Required absent component sets `tula_FOUND` false | part of `just tula-component-matrix` |
| Real ECSV fixture | Actual TolTEC tune reports through Tula ECSV + csv-parser | part of `just tula-component-matrix` |
| Perflibs component matrix | Minimal Threads/OpenMP graph and installed Tula consumer | `just tula-perflibs-matrix` |
| Enum/CLI component matrix | Independent enum and CLI closures and installed consumers | `just tula-enum-cli-matrix` |
| NetCDF component matrix | Normalized adapter, exact closure, real file I/O, installed consumer | `just tula-netcdf-matrix` |
| GrPPI component matrix | Adapter boundary and execution behavior with/without OpenMP | `just tula-grppi-matrix` |
| Fitting component matrix | Minimal Ceres closure and installed fitting consumer | `just tula-fitting-matrix` |
| CCfits provider matrix | CCfits API and CFITSIO implementation under external and source policy | `just tula-ccfits-matrix` |
| Production package matrix | Tula, Kidscpp, Citlali package tests, installed consumers, installed CLI | `just production-matrix` |
| Citlali observation gate | Full 149101 input set through the installed CLI and FITS output | `just citlali-real-workdir` |
| Tlaloc integration matrix | Minimal ECSV closure, full executable, required real tune report, excluded Kidscpp/Ceres | `just tlaloc-matrix` |

## 3. TulaCMake fixture

`tests/cmake/fixture` installs and exercises:

- `tula_cmake_log`;
- `tula_cmake_inspect_target`;
- `tula_cmake_target_defaults`;
- configured capability headers;
- Git/version headers; and
- relocatable package export.

The installed-consumer test ensures the fixture never succeeds merely because
modules are available in the source tree.

`tula_cmake_install_package()` does not invent include directories. A target
that owns headers declares its own build and install interfaces. This behavior
is covered by the installed fixture and by pure interface adapter consumers.

## 4. Tula ECSV matrix

The two environments are:

```text
environments/integration/tula_ecsv/
├── gcc14/spack.yaml
└── llvm20/spack.yaml
```

Each root requests only:

```text
tula@3.1.0+ecsv
```

The Tula recipe's `requires()` directives produce:

```text
+logging +yaml +eigen +ecsv
~netcdf ~enum ~cli ~perflibs ~openmp ~grppi ~fitting
```

The test fails unless the concrete DAG contains `tula-logging`,
`tula-yaml-cpp`, `tula-csv-parser`, and `tula-eigen3`. It separately rejects
any graph containing Ceres.

The package build currently runs ten tests:

1. core/config header smoke;
2. ECSV header;
3. ECSV typed table;
4. ECSV csv-parser streaming;
5. real tune reports;
6. YAML configuration;
7. flat configuration;
8. filename utilities;
9. Eigen utilities and formatting; and
10. Eigen-backed nddata.

## 5. Real data

The reader uses the public ECSV sequence:

```cpp
auto header = tula::ecsv::ECSVHeader::read(input);
auto rows = aria::csv::CsvParser(input).delimiter(header.delimiter());
auto table = tula::ecsv::ECSVTable(std::move(header));
table.load_rows(rows);
```

Astropy ECSV metadata uses the YAML ordered-map tag, so observation values are
read through Tula's existing `meta_to_map` API rather than plain YAML-map
indexing.

The fixture first selects valid `*_tune.txt` links under
`tolteca_test_data/tolteca_workdir/data`. In the dev container those symlinks
may point to a host path outside the mount, so it falls back to eleven regular
reports under `tolteca_test_data/data_lmt/toltec/reduced`.

## 6. Measured result

Measured on 2026-08-01:

| Lane | Component closure | Package tests | Adapter consumer | ECSV consumer | Missing component |
| --- | --- | --- | --- | --- | --- |
| GCC 14.2 / C++23 | correct | 10/10 | pass | pass | rejected |
| LLVM 20.1.2 / C++23 | correct | 10/10 | pass | pass | rejected |

TulaCMake's native installed fixture also passes.

## 7. Tula perflibs matrix

The four independent roots are:

```text
environments/integration/tula_perflibs/
├── gcc14_openmp/spack.yaml
├── gcc14_no_openmp/spack.yaml
├── llvm20_openmp/spack.yaml
└── llvm20_no_openmp/spack.yaml
```

Each requests only `tula+perflibs` and the intended `+openmp` or `~openmp`
state. The gate rejects every unrelated Tula component and dependency,
including logging, YAML, csv-parser, Eigen, Ceres, and NetCDF.

For every case, Spack runs Tula's header smoke and focused perflibs test. A
separate installed consumer then requests:

```cmake
find_package(tula 3.1 CONFIG REQUIRED COMPONENTS perflibs)
target_link_libraries(app PRIVATE tula::perflibs)
```

The consumer verifies the high-level `TULA_HAS_OPENMP` value against the
adapter's `TULA_PERFLIBS_HAS_OPENMP`; enabled cases also compile with
`_OPENMP` and call `omp_get_max_threads()`.

Measured on 2026-07-31:

| Compiler | `+openmp` package/consumer | `~openmp` package/consumer |
| --- | --- | --- |
| GCC 14.2 / C++23 | pass / pass | pass / pass |
| LLVM 20.1.2 / C++23 | pass / pass | pass / pass |

Native macOS adds Homebrew LLVM 20.1.8 plus Spack-built
`llvm-openmp@20.1.8`; the enabled installed consumer passes and its Mach-O
dependency list contains `libomp.dylib` from that prefix.

## 8. Tula enum and CLI matrix

Four environments cover GCC 14 and LLVM 20 for each root:

```text
tula+enum -> +logging + bitmask + meta-enum
tula+cli  -> +logging +enum + Clipp
```

The gate asserts every enabled and disabled Tula variant, checks the adapter
DAG, runs package tests, and builds installed consumers of `tula::enum` and
`tula::cli`. The enum graph explicitly rejects Clipp, proving CLI remains an
optional layer.

| Root | GCC 14 package/consumer | LLVM 20 package/consumer |
| --- | --- | --- |
| `tula+enum` | pass / pass | pass / pass |
| `tula+cli` | pass / pass | pass / pass |

## 9. Tula NetCDF matrix

`tula+netcdf` is tested under GCC 14 and LLVM 20. It requires only logging,
Eigen, `tula-netcdf-cxx4`, NetCDF C++4, and the C library below it. The adapter
exports `tula_deps::netcdf_cxx4`; Tula and downstream projects no longer
repeat a discovery target name. The adapter's CMake discovery recognizes both
the Linux `libnetcdf_c++4` and source/macOS `libnetcdf-cxx4` filenames.

Both package tests and an installed consumer perform real NetCDF file I/O.
Every unrelated Tula component and Ceres is rejected from the graph.

| Root | GCC 14 package/consumer | LLVM 20 package/consumer |
| --- | --- | --- |
| `tula+netcdf` | pass / pass | pass / pass |

## 10. Tula GrPPI matrix

Four roots cover GCC 14 and LLVM 20 with OpenMP enabled and disabled.
`+grppi` requires logging, enum, and perflibs at the Tula layer; the
`tula-grppi` adapter contains only upstream GrPPI headers.

The package test executes sequential mapping in every case, executes an
OpenMP mapping when enabled, and requires the `omp` mode to be absent when
disabled. The installed consumer independently checks the exported execution
mode list.

| Compiler | `+openmp` package/consumer | `~openmp` package/consumer |
| --- | --- | --- |
| GCC 14.2 / C++23 | pass / pass | pass / pass |
| LLVM 20.1.2 / C++23 | pass / pass | pass / pass |

## 11. Tula fitting matrix

`tula+fitting` enables logging and Eigen and adds Ceres. It excludes YAML,
ECSV, NetCDF, enum, CLI, perflibs, and GrPPI. Ceres' upstream
`Ceres::ceres` target is already canonical, so Tula links it directly.

The focused package test and installed consumer validate the public
`ParamSetting` API under GCC 14 and LLVM 20.

## 12. Production package matrix

The production roots request Citlali and therefore concretize the complete
Tula → Kidscpp → Citlali graph. Both GCC 14 and LLVM 20 lanes run:

| Package | Package tests | Behavior covered |
| --- | --- | --- |
| Tula | 16/16 | all eleven components, real ECSV, NetCDF, OpenMP, fitting |
| Kidscpp | 7/7 | real metadata/slice ingestion, rejection cases, PSD, solver |
| Citlali | 6/6 | Gaussian models, reader/solver boundary, CLI contract |

Each lane then builds an independent consumer from each installed CMake
package and runs the installed `citlali --version`. No consumer uses a source
or build-tree package config. The gate reads each installed package-test log,
requires the exact 16/7/6 totals and named real-data cases, and fails if any
case is reported as skipped.

## 13. CFITSIO/CCfits provider matrix

Four independent environments test the cross-product rather than assuming that
an external success implies a source build works:

```text
environments/integration/tula_ccfits/
├── gcc14_external/spack.yaml
├── llvm20_external/spack.yaml
├── gcc14_source/spack.yaml
└── llvm20_source/spack.yaml
```

Every root contains only `tula-ccfits`. External cases require the Ubuntu
CFITSIO 4.3.1 and CCfits 2.6 prefixes at `/usr`. Source cases override those
two package policies, select Spack CFITSIO 4.6.3 and CCfits 2.6, and reject
`/usr` as their installed prefixes. Each case then builds a separate CMake
consumer against the installed `TulaCcfits` config and calls the public CCfits
C++ API plus its underlying CFITSIO C API through `tula_deps::ccfits`.

The native macOS environment adds a fifth focused case: Homebrew LLVM 20.1.8
is registered as the exact compiler external while Spack builds the two FITS
libraries and `llvm-openmp@20.1.8` from source. The gate validates
`clang++ --version`, builds an installed `tula::perflibs` consumer, requires
`_OPENMP`, runs `omp_get_max_threads()`, and checks the final binary's
`libomp.dylib` linkage.
The separate complete native graph requests `citlali+openmp`; the capability
propagates through Kidscpp and Tula while only `tula-perflibs` handles runtime
discovery.
That graph pins source NetCDF C 4.9.3 rather than Spack's broken 4.8.1 patch
path or the incompatible 4.10/HDF5 target export with C++4 4.3.1.

Measured result: Citlali builds with OpenMP, 6/6 root package tests pass, and
the installed CLI reports Citlali 4.0.0 and Kidscpp 3.1.0. The focused
source-built CFITSIO/CCfits and installed OpenMP consumers also pass.

## 14. Citlali observation gate

`just citlali-real-workdir` runs the installed GCC 14 CLI against observation
149101. The input set contains eleven TolTEC NetCDF timestreams, the recomputed
telescope stream, and the APT ECSV table. The raw data remains outside the
workspace and is mounted read-only; output is isolated under `/tmp`.

The measured 2026-07-31 run:

- loaded all input interfaces and 5,270 detector records;
- processed all 123 scans with OpenMP;
- produced raw FITS maps for a1100, a1400, and a2000;
- produced filtered FITS maps and PSD/histogram/index products; and
- exited successfully in 2m53s after the rebuilt container bootstrap.

The complete console record is retained at
`tula_cmake/build/citlali-real-workdir/gcc14.log` by the repeatable recipe.

## 15. Tlaloc integration matrix

The GCC 14 and LLVM 20 roots build the complete `tlaloc_clip` executable from
the clean Tlaloc baseline. The gate asserts this graph before installation:

```text
tlaloc
├── tula+ecsv
│   ├── tula-logging
│   ├── tula-yaml-cpp
│   ├── tula-csv-parser
│   └── tula-eigen3
├── tula-netcdf-cxx4
├── tlaloc-katcp
├── fftw
└── mariadb-c-client
```

All unrelated Tula variants are disabled; Kidscpp and Ceres are rejected from
the DAG. The package test is enabled by `spack install --test=all` and requires
the real observation 149101 tune report. It exercises the public Tula ECSV
reader, typed column storage, and observation metadata.

This integration exposed a real lifetime defect: `ECSVTable::header_view()`
returned a temporary while its lazy column range retained references into it.
Tula now returns stable const references from table, loader, header, and view
accessors. Both the focused ECSV matrix and the complete production matrix pass
after the correction.

## 16. Adding the next component

For each new Tula component:

1. identify the exact headers and direct dependency targets it uses;
2. add provider-faithful `tula_deps::*` adapters only where needed;
3. add the Tula component target and Spack variant edges;
4. add a focused behavior test linked only to that component;
5. assert the minimal concrete graph and excluded heavy dependencies;
6. exercise an installed component consumer;
7. run GCC 14 and LLVM 20; and
8. update the component contract, support matrix, and technical deck.

Kidscpp, Citlali, and the narrow Tlaloc ECSV integration are now measured
boundaries.
