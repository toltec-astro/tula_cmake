# tula_cmake 3.1

The authoritative architecture and implementation decisions live in
[`design/`](design/README.md). Sphinx documentation under `docs/` describes
the currently validated user interface.

`tula_cmake` is the typed source-superbuild infrastructure for TolTEC C++
projects. It separates two graphs:

- the project graph (Tula, Kidscpp, Citlali, and other owned source projects)
  is composed recursively with CMake/CPM;
- the external dependency graph uses the provider selected for each feature:
  Conan, CPM, system, or disabled.

The Python wheel contains the `tula-cmake` CLI, Pydantic models, graph
resolver, feature registry, and installed CMake resources. Conan recipes
remain available for package production and regression testing, but Conan is
not required to own the first-party project graph.

## Downstream command

```sh
./build
```

Released projects carry the same thin launcher. It obtains the pinned CLI from
the `tula_cmake` GitHub tag with `uvx`, then:

1. validates and recursively resolves `tula-project.yaml`;
2. prepares only the external dependencies assigned to Conan;
3. writes inspectable CMake project and feature manifests;
4. composes owned projects through CPM and builds with the generated preset.

CMake does not invoke Conan.

`TULA_CMAKE_DEV_PROJECT=/path/to/tula_cmake` selects a local checkout.
`TULA_CONAN_CONFIG_SOURCE` may point at an organization `conan config install`
source. Once the TolTEC Conan remote is deployed, that shared configuration
will define the remote and profiles without requiring package-specific setup.

## Repository ownership

This repository owns the complete minimal vertical slice:

- `examples/tula_boilerplate`: the minimal logging and generated-header
  package;
- `examples/tula_downstream`: a source-superbuild consumer that acquires
  boilerplate with CPM.

Tula, Kidscpp, and Citlali remain separate repositories. Each repository owns
its direct dependencies in `tula-project.yaml`; a root project recursively
composes that graph. A central owned-project catalog will provide default,
immutable Git coordinates and expected CMake targets. Local path overrides
use CPM's normal source override semantics and are implemented in the current
slice.

In this context, making a project “available” means publishing catalog source
metadata, not exporting it as a Conan package.

## Project integration

```yaml
# tula-project.yaml
project:
  name: tula_downstream
  version: 3.1.0
dependencies:
  projects:
    - name: tula_boilerplate
      provider: cpm
      source:
        path: ../tula_boilerplate
      target: tula_boilerplate::headers
```

```cmake
include(TulaProject)
tula_resolve_project_dependencies()
tula_resolve_features()
```

The first slice intentionally supports local project paths. Catalog-backed Git
acquisition, immutable revision locking, and per-project local overrides are
the next implementation slice; their accepted design is recorded in
[`design/`](design/README.md).

The current registry contains:

- `logging`: one meta-feature providing a compatible fmt + spdlog pair through
  disabled, system, Conan, or CPM acquisition;
- `yaml_cpp`: yaml-cpp 0.9.0 through Conan or CPM, with a system-provider path
  for distribution packages;
- `csv_parser`: the production Jerry-Ma fork pinned by commit and checksum,
  acquired as a header-only CPM source and normalized as `tula::csv_parser`;
- `netcdf_c`: NetCDF C 4.8.1 through Conan or the system NetCDF config target;
- `netcdf_cxx4`: NetCDF C++ 4.3.1 through a project-owned Conan recipe or the
  system pkg-config interface, layered on `netcdf_c`;
- `bitmask`: the production header-only bitmask implementation, pinned by
  commit and checksum and normalized as `tula::bitmask`;
- `meta_enum`: the production compile-time enum parser, pinned by commit and
  checksum and normalized as `tula::meta_enum`;
- `clipp`: clipp 1.2.3 through Conan Center or a checksummed CPM archive,
  normalized as `tula::clipp`;
- `perflibs`: a system feature centralizing Threads, optional OpenMP, optional
  oneMKL, runtime validation, and capability definitions;
- `eigen`: Eigen 3.4.1 through Conan or CPM, or a system package, with explicit
  multithreading state and a dependency on `perflibs`.

## Source layout

```text
src/tula_cmake/
├── models.py
├── registry.py
├── superbuild.py
├── recipe.py
├── workflow.py
├── cli.py
├── resources.py
├── py.typed
└── data/
    ├── registry.yaml
    ├── cmake/
    │   ├── infrastructure/
    │   │   ├── TulaBootstrap.cmake
    │   │   ├── TulaProject.cmake
    │   │   ├── TulaConfigHeader.cmake
    │   │   └── TulaCPM.cmake
    │   └── resolvers/
    │       ├── bitmask.cmake
    │       ├── clipp.cmake
    │       ├── csv_parser.cmake
    │       ├── eigen.cmake
    │       ├── logging.cmake
    │       ├── meta_enum.cmake
    │       ├── netcdf_c.cmake
    │       ├── netcdf_cxx4.cmake
    │       ├── perflibs.cmake
    │       └── yaml_cpp.cmake
    ├── templates/
    ├── profiles/
    └── recipes/
        └── netcdf-cxx4/
```

The repository also contains `examples/tula_boilerplate` and
`examples/tula_downstream`; feature-matrix fixtures remain under `tests`.

Pydantic models validate YAML and generated preset JSON boundaries. Package
data remains below the installed Python package so both wheels and Conan
exports resolve the same resources reliably.

Resolver wiring follows one convention instead of repeating Python/CMake
symbols in YAML. A registry feature named `logging` maps to
`cmake/resolvers/logging.cmake`. The driver selects one provider entry point:
`tula_resolve_logging_conan()`, `tula_resolve_logging_cpm()`, or
`tula_resolve_logging_system()`. Resolver modules contain no provider-mode
switch.

## User configuration

Project acquisition and feature acquisition are deliberately distinct.
Project dependencies are declared in `tula-project.yaml`; root provider
overrides select feature acquisition without editing downstream CMake:

```sh
./build --provider logging=system
```

The default downstream slice selects Conan for the `logging` meta-feature, so
the generated virtual Conan recipe contains only `fmt` and `spdlog`.
`tula_boilerplate` itself never enters that Conan graph.

Existing Conan recipe options remain supported by the optional package-build
path while production projects migrate to the root-owned source graph.

## Feature matrix tests

Feature/provider validation does not use `tula_boilerplate`. The package keeps
one internal generated-project fixture under `tests/feature_matrix/` and executes
each case as an individually selectable Pytest item:

```sh
just matrix
just matrix-all
just gcc14
just clang20
just compilers
uv run pytest -m feature_matrix -k logging
```

The compiler gates select the bundled GCC 14 or Clang 20 Conan profile, run
the applicable 61-case matrix, and then build the installed
Tula → kidscpp → Citlali package chain. GCC 13 remains the default baseline.
The dev container installs the versioned compiler executables, matching
OpenMP runtimes, and `clang-tools-20` (needed by CMake for
`clang-scan-deps`).

Provider cases are derived from `registry.yaml`. The matrix metadata defines
one option axis per feature-owned option, and the runner derives one case for
every allowed value. A fast catalog test fails when a registry feature,
provider, or option value lacks coverage.

Each executable case:

1. copies the minimal matrix project to a Pytest temporary directory;
2. supplies root-scoped Conan options without creating an overlay profile;
3. runs the normal `BuildWorkflow`;
4. checks enabled options in Conan's generated preset;
5. verifies normalized-target presence or absence;
6. compiles a feature-specific C++ probe and runs it with CTest.

Cases requiring unavailable system facilities are capability-gated, not
removed. Set `TULA_TEST_CAPABILITIES` to a comma-separated list in an image
that provides those facilities. Runtime-specific cases additionally require
`TULA_TEST_INTEL_PROFILE` or `TULA_TEST_LLVM_PROFILE`, preventing a runtime
label from passing under the wrong compiler. Conan and CPM provider cases
carry the `network` marker so the fast local tier can exclude them.

`tula_boilerplate` is consequently only a minimal usage example. It has no
feature-matrix profiles.

The source-superbuild acceptance is independent:

```sh
just vertical-slice
```

It builds `tula_downstream → tula_boilerplate` twice (Conan logging and system
logging), runs the resulting binaries, and asserts that the generated Conan
input contains external libraries but never the owned boilerplate project.

The Sphinx site explicitly renders every public Pydantic model, its field
descriptions, validators, and JSON schema. It also generates the provider
support and package-option reference directly from `registry.yaml`.
Documentation warnings fail the build.

## Development

The project is linked to
[`Jerry-Ma/cookiecutter-pypackage`](https://github.com/Jerry-Ma/cookiecutter-pypackage)
at the `v2026` checkout through Cruft.

```sh
just qa
just docs
just build
just cruft-check
```

The repository-level container acceptance remains:

```sh
just all
```
