# TulaCMake

TulaCMake is the shared CMake package of the TolTEC C++ projects (Tula,
Kidscpp, Citlali, Tlaloc). It provides:

- target-scoped CMake functions: target defaults, configuration and version
  headers, relocatable package installation and diagnostics;
- dependency adapters, which give one CMake target per third-party library
  (`tula_deps::yaml_cpp`, `tula_deps::ccfits`, …) for any provider;
- the Spack recipes for TulaCMake and the adapters; and
- acceptance gates that build and test the installed package chain with
  GCC 14 and LLVM 20.

Spack resolves and builds the dependency graph; TulaCMake adds no wrapper
command and no dependency model of its own. To install the TolTEC C++ chain,
use a `tolteca_deploy` location.

## Quick start

```cmake
find_package(TulaCMake 3 CONFIG REQUIRED)

add_library(example src/example.cpp)
tula_cmake_target_defaults(TARGET example CXX_STANDARD 23 WARNINGS)
```

## Documentation

| Guide | Use it to |
| --- | --- |
| [CMake conventions](docs/cmake-conventions.md) | set target defaults, generate headers, install a package |
| [Dependency adapters](docs/dependency-adapters.md) | link a third-party library or a Tula component, choose a provider, enable OpenMP |
| [Spack recipes](docs/spack-recipes.md) | write a recipe, select features, develop from checkouts |
| [Acceptance gates](docs/acceptance-gates.md) | run and extend the gates |

The specification is [`design/spec.md`](design/spec.md).

## Branches

`v3.x_spack` is the active branch. The earlier Conan 2 implementation is on
`v3.x_conan2`.
