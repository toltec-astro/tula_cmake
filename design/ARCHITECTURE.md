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
├── tula-perflibs source and recipe
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
```

The current measured slice keeps its recipes in the isolated
`toltec.vertical_slice` repository while production recipes are migrated. The
final repository namespaces are decentralized and composed by the root Spack
environment.

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
```

TulaCMake is not linked and does not become a transitive runtime dependency.
Every project that calls its functions declares its own build dependency.

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

## 5. TulaCMake code structure

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

## 6. Public CMake contract

All public functions use the `tula_cmake_` prefix because CMake functions
occupy a global namespace.

Functions are:

- explicit rather than implicit;
- target-scoped rather than directory-global;
- independent of a specific dependency catalog;
- usable outside the Tula library; and
- tested through an installed producer and a separate consumer.

## 7. Project CMake contract

An ordinary project:

1. calls `find_package(TulaCMake CONFIG REQUIRED)`;
2. calls `find_package()` for its resolved dependencies;
3. defines and links normal CMake targets;
4. maps package features to generated headers where appropriate;
5. exports a relocatable CMake config; and
6. owns behavior tests for its software.

Normalized targets such as `tula::headers` belong to Tula. TulaCMake does not
create aliases for arbitrary dependencies.

## 8. Spack recipe contract

A recipe owns:

- versions and source identity;
- patches required by that upstream version;
- variants exposed to users;
- conditional dependency edges;
- mapping variants to ordinary CMake cache variables;
- build, link, run, and test dependency types; and
- package-specific build or install exceptions.

Organization policy is represented by ordinary packages where appropriate.
For example, `tula-logging` is a `BundlePackage` that selects a compatible
fmt/spdlog set without installing code.

## 9. Artifact lifecycle

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

## 10. Explicit exclusions

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
