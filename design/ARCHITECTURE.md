# Recursive source-superbuild architecture

Status: boilerplate/downstream slice implemented and verified, 2026-07-29.

## Problem

The first Conan 2 implementation made the TolTEC projects themselves an
exclusive Conan package chain:

```text
citlali Conan package
└── kidscpp Conan package
    └── tula Conan package
```

That arrangement correctly exports binary package metadata, but it removes an
important property of the production v1 build. In v1, the top-level project
assembled Tula and Kidscpp from source and selected the acquisition mode of
each external dependency. A Citlali developer could therefore use Tula from
source, CCfits from Conan, and another dependency from the system in one
coherent configure operation.

The architecture must restore that flexibility without losing the one-command
v3 user experience.

## Governing model

`tula_cmake` owns one recursive build graph. The graph contains two different
kinds of nodes:

1. **Project dependencies** are TolTEC CMake projects such as Tula, Kidscpp,
   and the vertical-slice boilerplate. They support source (`cpm`), installed
   (`system`), and packaged (`conan`) acquisition where implemented.
2. **Feature dependencies** are external capabilities such as logging,
   NetCDF, CCfits, and Ceres. Each feature advertises only its implemented
   providers and resolves to one normalized CMake target.

These categories must not be collapsed. Conan is one provider in the graph;
it is not the graph itself.

```text
tula-cmake build <root>
├── load root project manifest
├── acquire and load transitive project manifests
├── validate one root-owned provider selection
├── conan install: only Conan-selected external/project nodes
├── CMake/CPM: source-selected project/feature nodes
├── find_package: system-selected project/feature nodes
└── configure and build one CMake graph
```

## Project manifest

Every participating project contains `tula-project.yaml`. The manifest is
declarative and contains no executable Python or CMake. TolTEC-owned project
source coordinates and expected targets live in a separate catalog distributed
by `tula_cmake`; downstream manifests refer to catalog names rather than
repeating organization-owned Git URLs.

```yaml
schema_version: 1
project:
  name: tula_downstream
  version: 3.1.0

dependencies:
  projects:
    tula_boilerplate:
      default_provider: cpm
  features: {}
```

The distributed catalog owns acquisition and target identity:

```yaml
projects:
  tula_boilerplate:
    name: tula_boilerplate
    version: 3.1.0
    source:
      git_repository: https://github.com/toltec-astro/tula_cmake.git
      git_revision: <immutable-commit>
      source_subdir: examples/tula_boilerplate
    cmake_target: tula_boilerplate::headers
```

A library declares only direct dependencies. Transitive dependencies are
discovered from the acquired project's own manifest:

```yaml
schema_version: 1
project:
  name: tula_boilerplate
  version: 3.1.0

dependencies:
  projects: {}
  features:
    logging:
      default_provider: conan
```

The root may override a transitive provider from the command line:

```sh
./build --provider logging=system
```

Defaults make each project independently buildable. Root overrides own the
final graph. Conflicting transitive defaults without a root override are
configuration errors; they are never resolved by traversal order.

## Resolution phases

### 1. Bootstrap

The checked-in `build` launcher is the stable user entry point. It locates or
installs the pinned `tula-cmake` Python distribution with `uv tool run`, then delegates
all remaining phases. A developer can point it at a local checkout with
`TULA_CMAKE_DEV_PROJECT`.

Bootstrap is intentionally thin and contains no dependency policy.

### 2. Project graph discovery

The Python layer validates the root manifest and owned-project catalog with
typed Pydantic models, prepares catalog sources or local development
overrides, walks transitive manifests,
rejects cycles and duplicate project identities, and computes the required
feature set.

The boilerplate slice implements catalog-backed immutable Git sources, an
explicit checkout cache, generated source locks, `--project-source` root
overrides, and the standard `CPM_<name>_SOURCE` environment override.
Conan and installed project providers remain staged extensions of the same
model.

### 3. Provider selection

The root selection is computed once. Every required feature receives exactly
one provider. Registry dependencies are expanded before validation. Disabled
features are omitted unless required by another enabled feature.

Provider selection is graph state, not state stored independently in every
Conan package recipe.

### 4. Conan materialization

Python computes the union of requirements for nodes selected as `conan` and
runs one Conan install at the root. Conan generates the toolchain and CMake
package metadata for those external dependencies.

Source projects are not converted to Conan packages merely to participate in
the development build.

### 5. CMake materialization

Python generates immutable CMake manifests containing:

- selected feature providers and resolver modules;
- resolved project source locations and providers;
- feature-owned cache variables.

`TulaProject.cmake` reads those manifests. CPM adds source projects to the same
CMake graph. Feature resolvers create normalized `tula::<feature>` targets.
Global guards guarantee that a transitive feature is resolved once.

### 6. Build

The workflow configures and builds through the Conan-generated toolchain. The
phase names remain visible in logs, while the user still invokes one command.

## Packaging is orthogonal

Tula, Kidscpp, and Citlali may still be exported as Conan packages for release
distribution. That workflow requires complete exported dependency metadata
and can use the project-owned NetCDF C++ recipe.

It is not the mandatory development graph. Selecting `tula=conan` is an
explicit provider choice; it must not be an architectural prerequisite.

## Ownership boundaries

- `tula_cmake` owns graph discovery, provider validation, generated inputs,
  bootstrap, and orchestration.
- Each project owns its direct dependency declaration and CMake targets.
- The root invocation owns final provider choices.
- Conan owns artifacts selected as `conan`.
- CPM/CMake owns source nodes selected as `cpm`.
- The operating environment owns nodes selected as `system`.

## Non-goals for the first slice

- Porting Tula, Kidscpp, or Citlali to the new manifest.
- Publishing Tula, Kidscpp, or Citlali in the owned-project catalog before
  each repository has a validated manifest.
- Implementing `system` or `conan` providers for project dependencies.
- Removing the existing Conan packaging mixin before the replacement passes.
- Expanding the external package matrix beyond logging.
