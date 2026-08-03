# Architecture

## 1. System boundary

The TolTEC C++ build system has three layers:

```text
Spack
  resolves versions, variants, compilers, sources, patches, externals,
  binary caches, environments, and the complete dependency DAG

TulaCMake
  supplies reusable target-scoped CMake implementation conventions

Projects
  define C++ targets, public feature contracts, tests, and package recipes
```

Spack is the environment and graph manager. TulaCMake is not a graph manager.
A project remains a normal CMake project whose dependencies are already
available through Spack's prefix and compiler environment.

## 2. Repository ownership

Every production source repository owns the recipe that describes how that
source participates in Spack:

```text
tula_cmake
├── TulaCMake CMake modules
├── tula-logging bundle recipe
├── tula-ccfits bundle recipe
├── tula-perflibs source and recipe
├── narrow NetCDF C++4 recipe override and patch
├── tula-boilerplate example and recipe
└── tula-downstream example and recipe

tula
├── Tula header library
└── Tula recipe and variants

kidscpp
├── Kidscpp library
└── Kidscpp recipe and variants

citlali
├── Citlali library and executable
└── Citlali recipe and variants

tlaloc
├── Tlaloc readout executable and hardware utilities
└── minimal Tula ECSV recipe and pinned KATCP adapter
```

The example packages use the isolated `toltec.vertical_slice` repository.
Production recipes are decentralized under `toltec.tula_cmake`,
`toltec.tula`, `toltec.kidscpp`, `toltec.citlali`, and `toltec.tlaloc`. Root
environments compose only the accepted repositories needed by their selected
application.

The development checkout keeps the independent Git repositories as siblings:

```text
/workspaces/cpp/
├── tolteca_deploy/      location CLI + packaged profiles and revision manifest
├── tula_cmake/          infrastructure, examples, and root environments
│   ├── cmake/
│   ├── environments/
│   ├── examples/
│   ├── packages/
│   └── spack_repo/
├── tula/                common C++ base library
│   ├── include/tula/
│   ├── tests/
│   └── spack_repo/
├── kidscpp/             TolTEC reader and timestream solver
│   ├── include/kids/
│   ├── src/kids/
│   ├── tests/
│   └── spack_repo/
├── citlali/             reduction library and CLI
│   ├── include/citlali/
│   ├── src/citlali/
│   ├── tests/
│   └── spack_repo/
├── tlaloc/              readout controller; external Tula-ECSV consumer
│   ├── src/
│   ├── tests/
│   └── spack_repo/
└── tolteca_test_data/   optional real-data fixtures
```

Sibling placement is a development convenience, not a CMake composition
mechanism. The production environments bind specs to these checkouts with
`develop:` entries. Spack still builds and installs every package separately.

Each project-owned package repository follows Spack package API v2 layout:

```text
<project>/spack_repo/
├── develop.yaml          # local-development specs and repo-relative paths
└── toltec/
    └── <namespace>/
        ├── repo.yaml
        └── packages/
            └── <package_name>/
                ├── package.py
                └── <package-owned patches or resources>
```

For example, Tula owns `tula`, `tula-bitmask`, `tula-clipp`,
`tula-csv-parser`, `tula-grppi`, and `tula-meta-enum` recipes beneath
`tula/spack_repo/toltec/tula/packages/`. The environment references the inner
directory containing `repo.yaml` and `packages/`.

`tolteca_deploy` reads each selected source's `spack_repo/develop.yaml` and
composes the native environment `develop:` block. This keeps package/path
ownership beside the recipes instead of in a central deployment mapping.

## 3. Dependency topology

Build and link dependencies are different edges:

```text
                              build
                ┌────────────────────────────────┐
                ▼                                │
           tula-cmake                            │
                ▲                                │
                ├──────── tula                   │
                ├──────── tula-boilerplate       │
                ├──────── kidscpp                │
                └──────── citlali ───────────────┘

link/runtime:

citlali ──> kidscpp ──> tula

tula-downstream ──> tula-boilerplate

tlaloc ──> tula+ecsv
       ├─> tula-netcdf-cxx4
       ├─> fftw
       ├─> mariadb-c-client
       └─> tlaloc-katcp
```

TulaCMake is not linked and does not become a transitive runtime dependency.
Every project that calls its functions declares its own build dependency.
Tlaloc deliberately does not depend on Kidscpp: Tula ECSV parses tune reports,
while Tlaloc continues to own its readout controller and hardware behavior.

## 4. Vertical-slice graph

The acceptance graph intentionally contains both direct and transitive user
choices:

```text
tula-downstream
├── tula-boilerplate
│   ├── tula-lib-a       transitive value variant
│   ├── tula-perflibs    transitive boolean variant
│   └── tula-logging     no-code bundle
│       ├── fmt          system external in the dev container
│       └── spdlog       system external in the dev container
├── tula-lib-b           direct value variant
└── tula-cmake           build-only package
```

The root environment may constrain any reachable node:

```yaml
specs:
  - >-
    tula-downstream@0.1.0
    ^tula-lib-a flavor=chocolate
    ^tula-lib-b flavor=safe
    ^tula-perflibs~openmp
```

No intermediate package forwards those options. The concretizer merges root
constraints with recipe-owned edges before any package is built.

## 5. Dependency adapters and Tula components

The target namespace identifies the abstraction level:

| Layer | Example | Meaning |
| --- | --- | --- |
| TulaCMake functions | `tula_cmake_install_package()` | Build and packaging mechanics |
| dependency adapters | `tula_deps::yaml_cpp` | Provider-faithful normalized CMake target |
| Tula components | `tula::yaml` | Higher-level Tula C++ API and headers |

The adapter layer does not pretend that different libraries implement a common
semantic API. It retains names close to the concrete dependency:

```text
tula_deps::logging
tula_deps::yaml_cpp
tula_deps::csv_parser
tula_deps::eigen3
tula_deps::perflibs
tula_deps::netcdf_cxx4
tula_deps::ccfits
```

NetCDF C++4 4.3.1 is old enough that its installed metadata differs by
platform: Linux distributions commonly supply `netcdf-cxx4.pc`, while the
source-built macOS package does not. The adapter therefore discovers the
actual `netcdf` header, C++ library (`netcdf-cxx4` or `netcdf_c++4`), and C
library with CMake and records those resolved artifacts in its exported
interface. Downstream packages never repeat that platform distinction.

The first measured Tula component closure is:

```text
tula::ecsv
├── tula::logging ──> tula_deps::logging ──> fmt + spdlog
├── tula::yaml ─────> tula_deps::yaml_cpp ─> yaml-cpp
├── tula::eigen ────> tula_deps::eigen3 ───> Eigen
└───────────────────> tula_deps::csv_parser

tula::perflibs ─────> tula_deps::perflibs ──> Threads
                                               └── OpenMP::OpenMP_CXX
                                                   └── llvm-openmp@20.1.8 [Darwin]
tula::netcdf ───────> tula::eigen + tula_deps::netcdf_cxx4

citlali ─────────────> tula_deps::ccfits
                       ├── CCfits C++ interface (public API)
                       └── CFITSIO C library (implementation dependency)
```

The adapter header reports provider/platform facts. Tula's generated config
reports only Tula capabilities:

| Layer | Header | Macros |
| --- | --- | --- |
| adapter | `<tula_perflibs/config.h>` | `TULA_PERFLIBS_HAS_THREADS`, `TULA_PERFLIBS_HAS_OPENMP` |
| Tula | `<tula/config.h>` | `TULA_HAS_PERFLIBS`, `TULA_HAS_OPENMP` |

Spack owns the package edges and uses `requires()` for Tula component edges.
CMake exports only the selected `tula::*` component targets and verifies
consumer requests with `check_required_components(tula)`.

There is no `tula::headers` umbrella and no compatibility alias. A consumer
either links a concrete dependency adapter directly or requests a higher-level
Tula component.

The complete measured inventory is maintained in
[SUPPORT_MATRIX.md](SUPPORT_MATRIX.md). The detailed Tula contract is
[`../../tula/design/COMPONENTS.md`](../../tula/design/COMPONENTS.md).

## 6. TulaCMake code structure

```text
tula_cmake/
├── CMakeLists.txt
├── cmake/
│   ├── TulaCMake.cmake
│   ├── TulaCMakeLog.cmake
│   ├── TulaCMakeInspectTarget.cmake
│   ├── TulaCMakeTargetDefaults.cmake
│   ├── TulaCMakeConfigHeader.cmake
│   ├── TulaCMakeGitVersion.cmake
│   └── TulaCMakeInstallPackage.cmake
├── packages/
│   ├── tula_eigen3/
│   ├── tula_logging/
│   ├── tula_ccfits/
│   ├── tula_netcdf_cxx4/
│   ├── tula_perflibs/
│   └── tula_yaml_cpp/
├── examples/
│   ├── tula_boilerplate/
│   ├── tula_downstream/
│   └── spack/
├── tests/
├── environments/
│   └── production/
├── spack_repo/
│   └── toltec/tula_cmake/packages/
│       ├── netcdf_cxx4/       # inherited builtin + narrow export patch
│       └── tula_*/
└── design/
```

### `TulaCMake.cmake`

Stable aggregator included by `TulaCMakeConfig.cmake`. Consumers do not append
an installed directory to `CMAKE_MODULE_PATH`.

### `TulaCMakeLog.cmake`

Provides `tula_cmake_log()`, a thin validation and project-context layer over
CMake's native `message()` levels. Visibility is controlled by native
`--log-level` and `--log-context` options.

### `TulaCMakeInspectTarget.cmake`

Provides opt-in target diagnostics. It resolves aliases, prints a curated or
caller-selected property set, distinguishes unset properties, and never
changes the target.

### `TulaCMakeTargetDefaults.cmake`

Applies C++ standard requirements and warnings to one target. It detects
interface targets, propagates their language-level requirement without
exporting a warning policy to consumers, avoids directory-global flags, and
never enables warnings-as-errors.

### `TulaCMakeConfigHeader.cmake`

Configures a caller-owned template and attaches correct build/install include
interfaces to a target. The caller owns feature meanings and values.

### `TulaCMakeGitVersion.cmake`

Generates a header containing a semantic project version and immutable source
revision. A package recipe supplies the revision for reproducible builds; Git
detection is a local-development fallback.

### `TulaCMakeInstallPackage.cmake`

Installs named targets, exports namespaced targets, and generates relocatable
package and version files with `CMakePackageConfigHelpers`. Project dependency
discovery remains visible in the project's config template.

## 7. Public CMake contract

All public functions use the `tula_cmake_` prefix because CMake functions
occupy a global namespace.

Functions are:

- explicit rather than implicit;
- target-scoped rather than directory-global;
- independent of a specific dependency catalog;
- usable outside the Tula library; and
- tested through an installed producer and a separate consumer.

## 8. Project CMake contract

An ordinary project:

1. calls `find_package(TulaCMake CONFIG REQUIRED)`;
2. calls `find_package()` for its resolved dependencies;
3. defines and links normal CMake targets;
4. maps package features to generated headers where appropriate;
5. exports a relocatable CMake config; and
6. owns behavior tests for its software.

Dependency adapter packages export `tula_deps::*`; Tula components export
`tula::*`. TulaCMake does not create aliases implicitly.

## 9. Spack recipe contract

A recipe owns:

- versions and source identity;
- patches required by that upstream version;
- variants exposed to users;
- conditional dependency edges;
- mapping variants to ordinary CMake cache variables;
- build, link, run, and test dependency types; and
- package-specific build or install exceptions.

Organization policy is represented by ordinary packages where appropriate.
For example, `tula-logging` installs a relocatable interface target backed by
a compatible fmt/spdlog set.

## 10. Artifact lifecycle

```text
spack.yaml
   │ abstract root specs, develop paths, configuration scopes
   ▼
spack concretize
   │
   └──> spack.lock
        exact DAG, versions, variants, compilers, externals, hashes
             │
             ▼
        spack install
             │ one isolated configure/build/test/install per package
             ├──> package prefixes
             ├──> CMake package configs and exported targets
             └──> build logs
                       │
                       ▼
                 environment view
                       │
                       └──> runnable root executable
```

The lock file and view are environment-local. Installed prefixes and download
caches are user-level Spack state. No system installation is modified.

## 11. Compiler contract

The supported development matrix is intentionally small:

| Lane | Exact compiler | Language | OpenMP |
| --- | --- | --- | --- |
| GNU | GCC 14.2 | C++23 | GNU libgomp |
| LLVM | Clang 20.1.2 | C++23 | LLVM libomp |

GCC 13 is not a supported lane. Native AppleClang is not a substitute for the
LLVM 20 lane. A macOS environment must select and validate Homebrew LLVM 20.
The full macOS graph may use Homebrew GCC 14 only for an explicit Fortran
build-language edge; it does not replace LLVM for C or C++. Because Homebrew
`llvm@20` does not include an OpenMP runtime, the native profile builds exact
`llvm-openmp@20.1.8` with Spack. `tula-perflibs` discovers it and preserves
the resolved flags, header path, and library in its installed CMake config.
Citlali links `tula::perflibs`; it never repeats runtime probing. All three
production lanes retain `+openmp`, while `~openmp` remains a tested graph
choice.

## 12. Explicit exclusions

The architecture does not contain:

- a TulaCMake dependency YAML registry;
- provider modes named Conan, CPM, or system;
- generated Conan files;
- a bootstrap CLI that hides Spack;
- source inclusion through `add_subdirectory()` across production packages;
- global dependency-target rewriting; or
- feature-provider macros in C++ headers.

Acquisition origin is not a C++ capability. Generated headers record only
capabilities that can change software behavior or compilation.

## 13. Production boundary

Tula, Kidscpp, and Citlali remain separate installed packages:

```text
citlali::citlali
├── kids::kids
│   └── exact Tula component closure
├── exact Tula component closure
└── Citlali-owned Ceres/Boost/Spectra/FFTW dependencies
    └── tula_deps::ccfits ──> CCfits ──> CFITSIO
```

Kidscpp owns TolTEC NetCDF metadata, slicing, PSD construction, and
timestream solving. Citlali owns observation orchestration, mapmaking, and
the user-facing reduction CLI. The production gate verifies package tests,
three independent installed consumers, and the installed executable under
GCC 14 and LLVM 20.

The observation-level gate adds a distinct runtime boundary. The source
repositories and the separately maintained `tolteca_test_data` fixture are
sibling checkouts; installed dependencies remain inside the selected Spack
environment. Citlali resolves the fixture's NetCDF, ECSV, and tune-report
paths at runtime, while generated FITS products are isolated under `/tmp`.
This validates the complete executable without making science data a build
dependency or copying it into an install prefix.

## 14. Integration and deployment ownership

`tolteca_deploy` owns cross-repository composition without taking package
recipes away from their source repositories:

```text
tolteca_deploy/src/tolteca_deploy/data/spack/
├── stack.yaml                     accepted source revisions + Spack version
├── config/
│   └── macos-homebrew-llvm20/
│       └── packages.yaml          exact compiler/tool externals
└── profiles/development/
    ├── linux-gcc14/{profile.yaml,spack.yaml}
    ├── linux-llvm20/{profile.yaml,spack.yaml}
    ├── macos-homebrew-llvm20/{profile.yaml,spack.yaml}
    └── macos-homebrew-llvm20-citlali/{profile.yaml,spack.yaml}

LOCATION/
├── .tools/spack/                  pinned Spack checkout
├── .spack/{config,stage}/         location-specific mutable state
├── spack/<profile>/               independent environment
│   └── .spack-env/view/           native installed view
└── src/                           configured source checkouts
```

Developer environments use sibling `develop:` paths and intentionally ignore
local locks. A future release profile packaged by `tolteca_deploy` will replace
those paths with immutable sources, commit its lock, and own buildcache mirror
and trust configuration. Local editor/dev-container configuration is not a
release artifact and is deliberately outside this contract.

## 15. CCfits provider boundary

`tula-ccfits` is a no-code aggregate package like `tula-logging`. CCfits is the
public C++ API used by Citlali; CFITSIO is its required C implementation
dependency. The CMake config performs both provider-faithful `pkg-config`
discoveries once and exports one relocatable target. Citlali finds the adapter
and never repeats provider-specific target names.

Spack provider configuration is deliberately outside the CMake contract:

```text
external profile                 source profile
CFITSIO 4.3.1 at /usr            CFITSIO 4.6.3 built by Spack
CCfits 2.6 at /usr               CCfits 2.6 built by Spack
          \                       /
           tula_deps::ccfits
                    |
                 Citlali
```

The matrix checks both policies with GCC 14 and LLVM 20, then compiles and
runs a separate installed-package consumer that calls both APIs.
