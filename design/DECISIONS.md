# Decisions

## D001 — Spack owns the dependency graph

Accepted 2026-07-30.

Spack owns versions, variants, compilers, sources, patches, externals, caches,
environments, and concretization. TulaCMake does not maintain another package
or provider model.

## D002 — Keep native Spack UX

Accepted 2026-07-30.

No TulaCMake CLI wraps `spack concretize`, `spack install`, environments, specs,
or variants. Just recipes may sequence native commands for regression tests.

## D003 — TulaCMake is CMake-only

Accepted 2026-07-30.

The former Python project, Pydantic models, Conan Python-require, provider
registry, bootstrap command, and Sphinx API documentation are removed.
TulaCMake installs only `.cmake` files and package metadata.

## D004 — Tula is a peer project

Accepted 2026-07-30.

Tula follows the same CMake and Spack package conventions as Kidscpp, Citlali,
and the boilerplate. It does not own or control the build system.

## D005 — Boilerplate and downstream are acceptance packages

Accepted 2026-07-30.

`tula_boilerplate` is the smallest installed library using TulaCMake.
`tula_downstream` is the smallest installed application consuming it. They are
kept in the TulaCMake repository but remain independent projects and Spack
packages.

## D006 — Recipes are decentralized

Accepted 2026-07-30.

Each production source repository owns the recipe describing its source. A
root environment composes repositories. Integrator-only overrides may live in
an organization overlay without taking ownership away from the project.

## D007 — Logging is a bundle package

Accepted 2026-07-30.

`tula-logging` represents the supported fmt/spdlog combination as a real
no-code graph node. C++ consumers link fmt and spdlog targets normally.

## D008 — Perflibs is an installed interface package

Accepted 2026-07-30.

Perflibs is orthogonal platform capability policy. Its adapter package exports
`tula_deps::perflibs`, propagates Threads and optional OpenMP, and installs a
capability header. Tula may wrap it as the higher-level `tula::perflibs`
component. Its options are Spack variants.

## D009 — Build utilities are target-scoped

Accepted 2026-07-30.

Public functions require explicit targets and use the `tula_cmake_` prefix.
They do not modify global compiler flags, package registries, module paths, or
dependency targets.

## D010 — Provider origin is not a C++ feature

Accepted 2026-07-30.

Generated headers record capabilities such as OpenMP availability. They do not
record whether a dependency came from a system external, source build, or
binary cache.

## D011 — Markdown is canonical documentation

Accepted 2026-07-30.

Markdown is the searchable, reviewable, LLM-friendly source of truth. A
self-contained technical HTML deck is maintained for architecture reviews.
Sphinx is not used because there is no Python API.

## D012 — Preserve the Conan baseline before migration

Accepted 2026-07-30.

The current state is committed on the existing Conan branches and copied as
self-contained Git clones under
`archive/v3-conan2-baseline-2026-07-30`. Active development proceeds on
`v3.x_spack` without rewriting the baseline.

## D013 — Support GCC 14 and LLVM 20

Accepted 2026-07-30.

The measured compiler matrix is GCC 14.2 and LLVM/Clang 20.1.2, both using
C++23 and their matching OpenMP runtimes. GCC 13 is removed because it
duplicates the GNU lane. Native AppleClang does not satisfy the LLVM 20 lane.

## D014 — Generate local develop lock files

Accepted 2026-07-30.

Production-development `spack.yaml` files are versioned; their generated
`spack.lock` files are ignored because `develop` specs embed absolute workspace
paths and platform-specific external prefixes. Release environments replace
local develop paths with immutable Git tags and commit compiler/profile locks.

## D025 — Require release locks and preserve native Spack UX

Accepted 2026-08-03.

Development profiles regenerate with `spack concretize --force`. Release
profile metadata declares `lock: required`; deployment copies the packaged
lock and calls `spack concretize` without force. A missing lock is an error.
No custom dependency solver or opaque wrapper CLI is introduced.

## D026 — Keep large observation data outside releases

Accepted 2026-08-03.

The observation 149101 files remain local and are not pushed to GitHub.
`tolteca_deploy` packages a typed fixture contract that validates the required
paths/counts and expected runtime surface. Portable generated package tests
run without those files; development acceptance adds real reader/solver and
123-scan gates whenever the sibling fixture is present.

## D015 — Broad Tlaloc migration attempt

Rejected 2026-07-30.

The attempt changed more Tlaloc behavior than the approved build-system and
ECSV integration boundary. It is preserved in Git stash as evidence and is
not part of the active implementation.

## D016 — Separate dependency adapters from Tula components

Accepted 2026-07-31.

Provider-faithful normalized targets use `tula_deps::*`, for example
`tula_deps::yaml_cpp`. Higher-level Tula behavior uses `tula::*`, for example
`tula::yaml` and `tula::ecsv`. `tula_cmake::*` remains reserved for CMake
infrastructure targets.

There are no compatibility aliases. Direct dependency consumers may use a
`Tula*` adapter config without finding Tula. Tula consumers request explicit
components, and no umbrella target hides component mismatches.

## D017 — Keep Tlaloc outside the Kidscpp model boundary

Accepted 2026-07-31.

Tlaloc consumes only `tula::ecsv` for tune-report parsing. Its former
Kidscpp-based IQ/Rx model-evaluation path is removed, while NetCDF C++4, FFTW,
MariaDB, and KATCP remain Tlaloc-owned direct dependencies. The full executable
and required real tune-report test pass under GCC 14 and LLVM 20.

## D018 — ECSV views borrow stable table state

Accepted 2026-07-31.

`ECSVTable` and `ECSVDataLoader` accessors return const references for owned
headers, views, reference indices, and loaders. Returning copies allowed lazy
ranges to reference a destroyed temporary. The reference-returning API matches
the ownership model and is validated by Tula, Tlaloc, Kidscpp, and Citlali
tests.

## D019 — CCfits and its CFITSIO dependency form one adapter package

Accepted 2026-07-31.

Citlali consumes `tula-ccfits` through `TulaCcfits` and the aggregate
`tula_deps::ccfits` target. The adapter owns discovery and propagation of the
CCfits C++ API and its CFITSIO C implementation dependency. It accepts CCfits
2.6 and CFITSIO 4.3 or newer, avoiding an external-only dependency on the
unlisted CFITSIO 4.3.1 patch release. Fortran bindings are disabled because the aggregate's C
and C++ contract does not use them.

Provider origin remains Spack policy. The same adapter is tested with both
system externals and Spack source builds; no provider fact enters CMake target
names or generated C++ headers.

## D020 — `tolteca_deploy` owns integration and deployment policy

Accepted 2026-08-03; supersedes the local standalone-stack prototype.

Package recipes remain decentralized. The wheel-shipped
`tolteca_deploy/src/tolteca_deploy/data/spack/` assets own the multi-repository revision
manifest, platform configuration, development and required-lock release profiles,
and fixture contracts. A generated location owns its
pinned Spack checkout, environment, stage, and view; the configured storage
policy owns the install store and cache. This keeps
portable deployment inputs separate from reusable TulaCMake infrastructure
while leaving the native `spack -e` interface visible. Buildcache trust is a
deferred optimization. The superseded
standalone composition repository has been removed.

## D024 — Independent environments are visible; reusable storage is policy

Accepted 2026-08-03.

Each deployment location owns one visible independent environment at
`spack/<profile>/`. Its lock, generated configuration, and native
`.spack-env/view` stay together. The install store and source cache are
user-shared by default and may be location-scoped or redirected to an explicit
storage root. Build stages remain location-local. This follows Spack's native
environment model, removes redundant `environments/cpp` and `views/cpp`
layers, and avoids overloading `.spack_repo`, which denotes project-owned
package recipes.

Wheel-shipped deployment inputs remain inside the Python import package as
`tolteca_deploy/src/tolteca_deploy/data/{configs,location,spack}`. This preserves reliable
`importlib.resources` access from both editable installs and wheels while
removing the generic `data/stacks/cpp` nesting.

## D021 — OpenMP is a transitive package variant

Accepted 2026-07-31.

Citlali and Kidscpp expose an `openmp` Spack variant and constrain their Tula
dependency to the same state. Citlali maps the concrete variant to its
generated capability header and validates that Tula has the same state;
`tula::perflibs` carries the compile/link interface. This makes `+openmp`
versus `~openmp` part of the solved DAG; it cannot be selected accidentally
from undeclared host state.

Linux GCC 14, Linux LLVM 20, and native Homebrew LLVM 20 production profiles
retain the default `+openmp`. The Homebrew compiler keg does not contain the
runtime, so `tula-perflibs+openmp` depends on the matching Spack
`llvm-openmp@20.1.8` package on Darwin.

## D022 — Patch NetCDF C++4 at the package-recipe boundary

Accepted 2026-07-31.

The TolTEC Spack repository inherits the builtin `netcdf-cxx4` recipe and adds
one patch for release 4.3.1. The dormant upstream CMake project imports the
NetCDF C target before reconstructing its `hdf5::hdf5_hl` link-interface
target. The patch creates that imported interface from CMake's discovered HDF5
HL libraries first.

This is package integration metadata, so it lives beside the decentralized
TulaCMake recipes. It is not a host-profile flag and does not change NetCDF or
Tula runtime behavior.

## D023 — Perflibs owns OpenMP runtime integration

Accepted 2026-08-01.

`tula-perflibs` is the only TolTEC package that discovers and exports the
OpenMP compiler/runtime contract. Its low-level target is
`tula_deps::perflibs`; Tula exposes `tula::perflibs`. Citlali and Kidscpp do
not call `find_package(OpenMP)` independently.

On Darwin the Spack recipe pairs exact Homebrew Clang 20.1.8 with
`llvm-openmp@20.1.8`. The adapter's installed config preserves the resolved
flags, include directory, and library so an installed consumer cannot silently
select a different Homebrew `libomp`. Whether `llvm-openmp` is source-built or
a reviewed external remains environment policy, not a package variant.

## D027 — Discover Homebrew Fortran; isolate pkg-config metadata

Accepted 2026-08-03.

The native macOS profile does not encode a Homebrew GCC major, patch version,
or versioned `gfortran-N` path. Before concretization, the location runs
Spack's native `compiler find /opt/homebrew/opt/gcc/bin`. Spack records the
detected external compiler in the location-scoped user config and uses it only
for packages with Fortran edges; Homebrew LLVM 20 remains the C/C++ provider.

The profile source-builds `pkgconf@2.5.1` instead of registering Homebrew's
binary. Its compiled-in `/opt/homebrew/lib/pkgconfig` search directory exposes
unrelated formula metadata and can mix Homebrew HDF5 headers with a Spack HDF5
library in the NetCDF C build. An isolated pkgconf prefix makes every detected
NetCDF/HDF5 dependency an explicit node in the concrete Spack graph.
