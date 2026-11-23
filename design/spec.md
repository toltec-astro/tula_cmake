# TulaCMake specification

The TolTEC C++ packages (Tula, Kidscpp, Citlali, Tlaloc) are separate CMake
projects. Spack resolves, builds and installs them as one dependency graph.
TulaCMake supplies what these projects share: CMake conventions for targets
and installed packages, adapter packages for third-party libraries, the Spack
recipes for both, and the acceptance environments that verify the installed
chain.

Spack owns versions, variants, compilers, sources, patches, externals,
environments and the concrete graph. TulaCMake adds no second dependency
model: no provider registry, no wrapper command around Spack, no Conan, CPM or
FetchContent dispatch, and no `add_subdirectory()` composition across
packages.

Domains, in documentation-chapter order:

1. CMake conventions
2. Dependency adapters
3. Spack recipes
4. Acceptance gates

## CMake conventions

A project author uses TulaCMake to give targets consistent settings, generate
configuration and version headers, and install a relocatable CMake package,
without writing that CMake in each project.

- A project finds the installed package with
  `find_package(TulaCMake 3 CONFIG REQUIRED)`. Finding it defines the
  functions and changes no global state, including `CMAKE_MODULE_PATH`.
- TulaCMake is a build dependency only. It is not linked and is not a runtime
  dependency of any package.
- Public functions have the `tula_cmake_` prefix. Each function acts only on
  the targets it is given. No function sets directory-global flags, changes
  dependency targets or package registries, or enables warnings as errors.
- Target defaults apply a C++ standard and warnings to one target. An
  interface target passes its standard requirement to consumers but not its
  warning policy.
- A configured header is generated from a caller template. The caller owns
  the variables and their meaning; TulaCMake attaches the build and install
  include interfaces.
- A version header records the artifact identity: project version, source
  revision and Git state, compiler, C++ standard, and, when the recipe
  supplies them, the concrete package spec and DAG hash. It records no
  deployment identity (profile, lock); see "Handoffs".
- An installed package exports namespaced, relocatable targets and a
  same-major version file. The project's config template keeps its own
  dependency discovery. TulaCMake adds no include directory that the target
  does not declare.
- Diagnostics use CMake's native message levels and controls. Target
  inspection never changes the target.

## Dependency adapters

Third-party libraries ship different CMake metadata for each provider and
platform. A dependency adapter gives TolTEC projects one installed target per
library, so no project repeats the discovery.

- An adapter is an installed CMake package `Tula<Name>` that exports
  `tula_deps::<name>`. The name follows the wrapped library
  (`tula_deps::yaml_cpp`, not a semantic name), because the adapter provides
  no API of its own.
- A consumer can find an adapter without finding Tula.
- An adapter exports the same target whether its library is a system
  external or a Spack build. The provider does not appear in target names,
  generated headers or C++ macros.
- An adapter records the artifacts it resolved when it was built (headers,
  libraries, flags). A consumer of the installed adapter gets those artifacts
  and does not probe the host again.
- A library set that is used together is one adapter: `tula_deps::logging`
  (fmt and spdlog), `tula_deps::ccfits` (the CCfits C++ API and its CFITSIO
  implementation).
- `tula-perflibs` is the only TolTEC package that discovers OpenMP. It
  exports Threads and, when enabled, the resolved OpenMP compiler and runtime
  interface, and installs a header that reports the enabled capabilities.
- Target namespaces mark the level: `tula_cmake::` for CMake
  infrastructure, `tula_deps::` for adapters, `tula::` for Tula components
  (owned by Tula). There are no compatibility aliases and no umbrella target.

## Spack recipes

Spack builds every TolTEC package from a recipe, and the user selects
features with Spack variants on the root spec.

- Each source repository owns the recipes for its packages in
  `spack_repo/toltec/<namespace>/` (Spack package API v2). TulaCMake's
  repository `toltec.tula_cmake` holds the recipes for `tula-cmake`, the
  adapters, and the NetCDF C++4 override with its patch. It holds no recipe
  of another repository.
- A recipe owns the versions and source identity, patches for those
  versions, variants, conditional dependency edges, the mapping from variants
  to CMake cache variables, the dependency types, and package-specific build
  exceptions.
- Variants are the only feature options. A root environment can constrain
  any node it reaches; intermediate packages do not forward options.
- Version constraints state compatibility, not the version a site builds:
  - the lower bound is the lowest tested version, as an open range
    (`fftw@3.3.10:`);
  - an upper bound states a known incompatibility, for example a package
    whose CMake config accepts only its own major version (`eigen@3.4.0:3`);
  - TolTEC packages depend on each other within one major version
    (`tula@3.1:3`), matching the same-major version files;
  - an adapter has its own version for its CMake glue and a range on the
    library it wraps;
  - a recipe version names an immutable source: a commit, or a URL with its
    checksum.
- Each source repository maps its packages to repository-relative paths in
  `spack_repo/develop.yaml`, for local development builds.

## Acceptance gates

A maintainer runs the gates to confirm that the conventions, the adapters and
the package chain work as installed packages under the supported compilers,
before a change lands.

- Supported lanes: GCC 14 and LLVM 20, C++23. The gates run both lanes on
  Linux in the development container. The macOS lane (Homebrew LLVM 20) is
  verified in a `tolteca_deploy` location.
- A gate tests a feature at the boundary it creates: an installed producer
  and a separate consumer. No consumer uses a source or build tree.
- The gates and what each guarantees:

  | Gate | Guarantee |
  | --- | --- |
  | `unit` | TulaCMake installs; a separate producer and consumer use the installed functions; every repository-owned Spack include resolves |
  | `spack-matrix` | A root spec constrains direct and transitive variants with no forwarding |
  | `tula-*-matrix` | Each Tula component concretizes to its minimal closure, excludes unrelated heavy dependencies, and serves an installed consumer; a missing component fails `find_package` |
  | `tula-ccfits-matrix` | `tula_deps::ccfits` serves the same consumer with external and Spack-built providers |
  | `acceptance-matrix` | The Tula, Kidscpp and Citlali package tests pass, their named real-data tests run and pass, and installed consumers and the installed CLI work |
  | `snapshot-matrix` | The chain builds from immutable commits with no develop source, and the CLI reports the active profile and lock |
  | `citlali-real-workdir` | The installed CLI reduces observation 149101 completely and writes the products of all three arrays |

- A gate asserts that tests pass and that its required tests ran. It does
  not assert test counts.
- Gate environments are maintainer fixtures. They can refer to sibling
  checkouts and test-only repository composition. They are not deployment
  inputs.
- Real observation data stays outside the repository, in the sibling
  `tolteca_test_data` checkout.

## Handoffs

- **Tula** owns the `tula::` components, their variants and the component
  requirements between them. It builds on the adapters and conventions.
- **Kidscpp, Citlali** own their recipes, targets and behavior tests. They
  find TulaCMake, adapters and Tula with `find_package`.
- **Affiliated packages** (Tlaloc) are maintained outside TolTECA and keep
  their own repository, versions and releases. They use TulaCMake, the
  adapters and Tula the same way, and build in a `tolteca_deploy` location or
  against one. No TulaCMake gate builds them.
- **tolteca_deploy** owns deployment profiles, host library policy, release
  bundles and locks, and the composition of `develop.yaml` mappings into a
  location. It exports the deployment identity (`TOLTECA_SPACK_PROFILE`,
  `TOLTECA_SPACK_LOCK_SHA256`), which programs read at run time. It does not
  read TulaCMake's gate environments, and TulaCMake does not read its
  profiles.
