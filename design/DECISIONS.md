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

Perflibs is orthogonal platform capability policy. It exports
`tula::perflibs`, propagates Threads and optional OpenMP, and installs a
capability header. Its options are Spack variants.

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
