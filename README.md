# TulaCMake

TulaCMake is the shared, CMake-only build convention package for TolTEC C++
projects. Spack owns dependency resolution, variants, source acquisition,
patches, environments, binary caches, and the concrete dependency graph.
TulaCMake owns reusable target-scoped CMake mechanics.

There is no TulaCMake command-line wrapper, Python package, provider registry,
or second dependency language.

## Current status

The `v3.x_spack` branch contains a complete vertical slice:

```text
tula-downstream
├── tula-boilerplate
│   ├── tula-logging
│   │   ├── fmt
│   │   └── spdlog
│   ├── tula-lib-a
│   └── tula-perflibs
├── tula-lib-b
└── tula-cmake (build dependency)
```

Two GCC 14 feature environments are tested:

| Environment | Transitive libA | Direct libB | Perflibs |
| --- | --- | --- | --- |
| `default` | `flavor=vanilla` | `flavor=fast` | `+openmp` |
| `alternate` | `flavor=chocolate` | `flavor=safe` | `~openmp` |

Both environments concretize, build, install, run CTest package hooks, create
an environment view, and execute the installed downstream application.

The next verified slice separates provider-faithful dependency adapters from
higher-level Tula components:

```text
tula_deps::logging    -> tula::logging
tula_deps::yaml_cpp   -> tula::yaml
tula_deps::eigen3     -> tula::eigen
tula_deps::csv_parser -> tula::ecsv
tula_deps::perflibs   -> tula::perflibs
tula_deps::netcdf_cxx4 -> tula::netcdf
tula_deps::ccfits      -> Citlali FITS I/O (CCfits + its CFITSIO dependency)
```

`tula+ecsv` builds only that closure. `just tula-component-matrix` has passed
under GCC 14.2 and LLVM/Clang 20.1.2 in C++23 mode, including real TolTEC tune
reports, direct adapter-only consumption, installed Tula component discovery,
and required-component rejection.

`tula::perflibs` is also measured independently in four cases: GCC 14 and
LLVM 20, each with OpenMP enabled and disabled. Its graph contains only the
perflibs adapter and platform threading requirements.

On Darwin, `tula-perflibs+openmp` adds the exact `llvm-openmp` runtime to the
Spack graph. The installed adapter records the resolved `FindOpenMP` inputs so
consumers reconstruct that runtime instead of probing an unrelated host
library. The native Homebrew Clang 20.1.8 lane uses Spack-built
`llvm-openmp@20.1.8` and runs the same installed Tula consumer.

The enum and CLI components are independently measured in both compiler lanes.
The enum closure contains logging, bitmask, and meta-enum; CLI adds only Clipp.
NetCDF C++ discovery is normalized by its own relocatable adapter and verified
with real file I/O.
GrPPI is measured with OpenMP present and absent; its low-level adapter remains
independent from Tula logging, enum, and perflibs policy.
Fitting is measured as a minimal logging/Eigen/Ceres closure.

The complete production graph is also measured under both compilers: Tula
passes 16 tests, Kidscpp passes seven including real NetCDF ingestion, Citlali
passes six including the reader/solver ownership boundary, and independent
installed consumers and the installed CLI pass. A GCC 14 observation-level
run processes all 123 scans in the supplied 149101 fixture and writes raw and
filtered FITS products for all three arrays.

The native macOS arm64 Homebrew LLVM 20.1.8 location also installs the complete
OpenMP graph and processes all 123 scans. Citlali uses portable `getrusage`
memory reporting rather than a Linux-only `/proc` parser.

The clean-source gate fetches immutable commit snapshots for TulaCMake 3.2.0,
Tula 3.1.0, Kidscpp 3.1.0, and Citlali 4.1.0 with no `dev_path`.
Separate locked Unity/devcontainer graphs pass under GCC 14 and LLVM 20.
Generated version headers carry artifact identity—source/tree state, compiler,
C++ standard, package spec, and DAG. Citlali reads the active deployment
profile and lock identity at runtime so a shared Spack installation cannot
embed the identity of whichever environment happened to build it first.

The narrow Tlaloc integration is also measured in both lanes. It builds the
full `tlaloc_clip` executable with only `tula::ecsv`, keeps NetCDF/FFTW/
MariaDB/KATCP as Tlaloc-owned dependencies, excludes Kidscpp and Ceres, and
loads a required observation 149101 tune report in its package test.

## Responsibilities

TulaCMake provides:

- native CMake logging with project message context;
- opt-in target inspection;
- target-scoped C++ standard and warning defaults;
- configured-header generation;
- reproducible version and Git-revision headers;
- relocatable install/export/package-config generation; and
- installed-producer/consumer fixture tests.

TulaCMake does not provide:

- dependency versions or provider choices;
- Spack variants or concretization policy;
- `find_package()` calls for project dependencies;
- CPM, FetchContent, Conan, or system-package dispatch;
- Tula feature definitions; or
- runtime C++ targets.

## Source layout

```text
tula_cmake/
├── CMakeLists.txt
├── cmake/
│   ├── TulaCMake.cmake
│   ├── TulaCMakeConfigHeader.cmake
│   ├── TulaCMakeGitVersion.cmake
│   ├── TulaCMakeInspectTarget.cmake
│   ├── TulaCMakeInstallPackage.cmake
│   ├── TulaCMakeLog.cmake
│   └── TulaCMakeTargetDefaults.cmake
├── examples/
│   ├── tula_boilerplate/
│   ├── tula_downstream/
│   └── spack/
│       ├── config/
│       ├── environments/
│       └── repository/
├── environments/
│   ├── integration/          # focused feature/provider fixtures
│   └── acceptance/
│       ├── config/           # checkout-local composition
│       ├── development/      # local-source GCC 14 and LLVM 20
│       └── snapshot/         # immutable-source GCC 14 and LLVM 20
├── packages/
│   ├── tula_eigen3/
│   ├── tula_logging/
│   ├── tula_netcdf_cxx4/
│   ├── tula_perflibs/
│   └── tula_yaml_cpp/
├── spack_repo/
│   ├── develop.yaml              # repo-owned local-development package paths
│   └── toltec/tula_cmake/packages/
│       ├── tula_cmake/
│       ├── tula_csv_parser/
│       ├── tula_eigen3/
│       ├── tula_logging/
│       ├── tula_netcdf_cxx4/
│       ├── tula_perflibs/
│       └── tula_yaml_cpp/
├── tests/
│   ├── cmake/
│   ├── deps_consumer/
│   └── fixtures/spack/
├── design/
└── justfile
```

`tula_boilerplate` and `tula_downstream` are independent CMake projects and
independent Spack packages. They live here because together they are the
acceptance test for the public build conventions.

## Fresh dev-container setup

Rebuild the workspace dev container. Its post-create script installs:

- GCC 14;
- LLVM/Clang 20;
- CMake, Ninja, and Just;
- the system development packages used by the small offline slice; and
- Spack 1.2.2 at `/opt/spack`.

Inside the container:

```console
cd /workspaces/cpp
just all
```

The first Spack invocation may bootstrap its solver. Subsequent runs reuse the
user-level Spack cache and installed package prefixes.

## Native local CMake workflow

TulaCMake itself is a normal installable CMake package:

```console
cmake -S . -B build/unit -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/unit --parallel
ctest --test-dir build/unit --output-on-failure
cmake --install build/unit --prefix /tmp/tula-cmake-prefix
```

A consumer uses:

```cmake
find_package(TulaCMake 3 CONFIG REQUIRED)

add_library(example src/example.cpp)
tula_cmake_target_defaults(TARGET example WARNINGS)
```

The installed `TulaCMakeConfig.cmake` includes modules by their installed
location. It does not modify the consumer's global `CMAKE_MODULE_PATH`.

## Native Spack workflow

The validation automation sequences ordinary Spack commands; it is not a
replacement interface:

```console
spack \
  -C examples/spack/config \
  -C examples/spack/config/devcontainer \
  -e examples/spack/environments/default \
  concretize --force

spack \
  -C examples/spack/config \
  -C examples/spack/config/devcontainer \
  -e examples/spack/environments/default \
  install --test=all

examples/spack/environments/default/.spack-view/bin/tula_downstream
```

Or run both matrix entries:

```console
just environment-manifests
just spack-matrix
```

`environment-manifests` validates every repository-owned relative Spack
include before a compiler matrix starts, so directory reorganizations cannot
leave checked-in environments pointing at removed paths. It does not require
the sibling development checkouts and also runs as part of `just unit`. Unit
configuration is fresh on every run so the same checkout can move between a
devcontainer and its host without retaining an incompatible CMake cache path.

Run the production compiler matrix:

```console
just acceptance-matrix
just deployment-profile-consistency
```

Run the verified Tula ECSV component slice:

```console
just tula-component-matrix
```

Run the verified perflibs component slice:

```console
just tula-perflibs-matrix
just tula-enum-cli-matrix
just tula-netcdf-matrix
just tula-ccfits-matrix
just tula-grppi-matrix
just tula-fitting-matrix
just tlaloc-matrix
```

These component commands concretize and install Tula under GCC 14 and LLVM
20, run package CTests, validate minimal dependency graphs, and build
independent installed consumers. `acceptance-matrix` remains the separate
Tula → Kidscpp → Citlali gate. `tlaloc-matrix` is the independent readout
controller gate.

The root spec controls reachable transitive variants directly:

```yaml
specs:
  - >-
    tula-downstream@0.1.0
    ^tula-lib-a flavor=vanilla
    ^tula-lib-b flavor=fast
    ^tula-perflibs+openmp
```

There is no option forwarding through `tula-boilerplate`. Spack merges the
root constraints with package-owned dependency edges and records the complete
result in `spack.lock`.

## CMake API

### Target defaults

```cmake
tula_cmake_target_defaults(
    TARGET my_library
    CXX_STANDARD 23
    WARNINGS
)
```

The function changes only the named target. It never enables warnings as
directory-global compiler flags and never enables warnings-as-errors.

### Configured header

```cmake
set(MY_PACKAGE_HAS_FEATURE 1)
tula_cmake_generate_config_header(
    TARGET my_library
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/include/my_package/config.h.in"
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/my_package/config.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
```

The caller owns the variables and their meaning. TulaCMake owns only the
generation and target include-interface mechanics.

### Version header

```cmake
tula_cmake_generate_version_header(
    TARGET my_library
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/my_package/version.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
    NAMESPACE my_package
    VERSION "${PROJECT_VERSION}"
    REVISION "${MY_PACKAGE_GIT_REVISION}"
)
```

Package recipes should pass an immutable revision. Local developer builds may
omit `REVISION`, in which case TulaCMake detects the current Git commit.
Spack recipes additionally pass package spec, DAG hash, profile, and lock
SHA-256 through the documented `TOLTECA_*` build environment.

### Installable package

```cmake
tula_cmake_install_package(
    PACKAGE MyPackage
    EXPORT MyPackageTargets
    NAMESPACE my_package::
    VERSION "${PROJECT_VERSION}"
    TARGETS my_library
    CONFIG_TEMPLATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/MyPackageConfig.cmake.in"
)
```

The helper uses `CMakePackageConfigHelpers`, exports relocatable targets, and
generates a same-major version file. Dependency discovery remains explicit in
the project's config template.

### Diagnostics

```cmake
tula_cmake_log(VERBOSE "Configured optional feature X")
tula_cmake_inspect_target(
    TARGET my_package::dependency
    LEVEL DEBUG
)
```

Use native CMake controls:

```console
cmake --preset dev --log-level=DEBUG --log-context
cmake --preset dev --debug-find
cmake --build --preset dev --verbose
```

## Documentation

The design is maintained as Markdown so it is easy to review in Git, render on
GitHub, search locally, and supply directly to development tools and language
models:

- [`design/ARCHITECTURE.md`](design/ARCHITECTURE.md)
- [`design/WORKFLOW.md`](design/WORKFLOW.md)
- [`design/TESTING.md`](design/TESTING.md)
- [`design/DECISIONS.md`](design/DECISIONS.md)
- [`design/MIGRATION.md`](design/MIGRATION.md)
- [`design/tula-spack-system.html`](design/tula-spack-system.html)

## Historical baseline

The last Conan 2 implementation remains on `v3.x_conan2`. A self-contained
copy is also stored at:

```text
../archive/v3-conan2-baseline-2026-07-30/
```

The earlier provider-matrix workspace archive and the read-only production
references remain separate evidence. They are not inputs to the Spack build.
