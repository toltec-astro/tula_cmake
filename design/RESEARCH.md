# Owned-project source integration research

Research date: 2026-07-29.

## Established mechanisms

CMake's `FetchContent` documentation explicitly supports complex hierarchical
dependency graphs. Higher-level projects can override lower-level declarations
because the first declaration for a dependency wins. It recommends declaring
all known dependency details before making any dependency available:

<https://cmake.org/cmake/help/latest/module/FetchContent.html>

CMake also provides dependency providers that can intercept `find_package()`
and `FetchContent_MakeAvailable()`:

<https://cmake.org/cmake/help/latest/guide/using-dependencies/index.html>

CPM is a thin wrapper around FetchContent. Its documented facilities match the
TolTEC source-project use case:

- recursive source dependencies and deduplication;
- Git or archive acquisition;
- `CPM_SOURCE_CACHE`;
- `CPM_<name>_SOURCE` local development overrides;
- package lock files; and
- immutable commit hashes as the recommended reproducible source identity.

<https://github.com/cpm-cmake/CPM.cmake>

Conan supports a CMake dependency-provider integration, but its documentation
describes explicit `conan install` followed by a generated toolchain/preset as
the recommended flow. Configure-time Conan installation is characterized as
an exceptional integration with known limitations:

<https://docs.conan.io/2/integrations/cmake.html>

## Resulting design

`tula_cmake` will use established CMake/CPM semantics rather than inventing a
second source package protocol.

### Owned-project catalog

`tula_cmake` publishes a typed catalog for TolTEC-owned source projects. An
entry contains acquisition and CMake identity, not dependency policy:

```yaml
projects:
  tula:
    version: 3.1.0
    source:
      git_repository: https://github.com/toltec-astro/tula.git
      git_revision: <immutable-commit>
    cmake_target: tula::headers
```

Kidscpp and Citlali receive equivalent entries only after their manifests pass
the source-superbuild acceptance gates.

This catalog is the meaning of making, publishing, or *exporting* an owned
project through `tula_cmake`. It is unrelated to `conan export`.

### Project-owned manifest

The `tula-project.yaml` inside each source repository remains authoritative
for that project's direct project and feature dependencies. The central
catalog must not copy that dependency list.

### Root overrides

The root chooses providers and may replace catalog acquisition with a local
checkout. The public override maps naturally to CPM's documented local-source
behavior. The implementation may expose a friendlier CLI, but it must generate
or honor `CPM_<name>_SOURCE` semantics.

### Reproducibility

Released catalog entries use immutable Git commits. A generated source lock
records the complete resolved project graph. Human-friendly branches may be
accepted only as explicit development overrides.

### Discovery before Conan

The manifests of source projects must be available before the explicit Conan
install so `tula_cmake` can calculate the union of Conan-selected external
features. Source preparation therefore precedes provider materialization:

```text
catalog + root overrides
  -> prepare project sources
  -> read recursive tula-project.yaml files
  -> compute Conan requirements
  -> conan install
  -> CPM adds the already-resolved source directories
```

The first vertical slice uses local source overrides and therefore tests the
graph without prematurely designing remote source-cache mechanics. Remote
catalog acquisition and source locking are the next infrastructure slice.
