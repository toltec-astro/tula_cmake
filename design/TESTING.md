# Testing

## 1. Objectives

Every infrastructure feature must be independently observable and exercised
through the same installed boundaries used by production packages.

The examples are documentation and minimal packages. Test-only variation lives
in explicit fixtures and Spack environments, not as a collection of manual
profiles inside `tula_boilerplate`.

## 2. Test layers

| Layer | Command | What it proves |
| --- | --- | --- |
| CMake package fixture | `just unit` | TulaCMake installs and can configure a producer |
| Installed consumer | part of `just unit` | Exported target/config/header contracts survive installation |
| Default Spack graph | `just spack-matrix` | Default direct and transitive variants build and run |
| Alternate Spack graph | `just spack-matrix` | Independent variant changes produce a distinct concrete graph |
| Package CTests | `spack install --test=all` | Native Spack invokes package-owned CTest targets |
| Runtime assertion | matrix output check | The installed executable observes selected variants |

## 3. CMake fixture coverage

`tests/cmake/fixture` uses all public TulaCMake modules:

- `find_package(TulaCMake CONFIG REQUIRED)`;
- target-scoped C++23 and warnings;
- configured capability header;
- explicit version/revision header;
- target alias inspection;
- relocatable target export; and
- package config/version generation.

The test script then:

1. installs TulaCMake to a temporary prefix;
2. configures and builds the producer from that prefix;
3. runs its CTest;
4. installs the producer;
5. configures a separate consumer from the same prefix;
6. builds the consumer; and
7. runs the consumer.

The fixture never includes modules from the source tree.

## 4. Spack matrix coverage

The default environment proves:

```text
libA=vanilla
libB=fast
perflibs.openmp=enabled
```

The alternate environment proves:

```text
libA=chocolate
libB=safe
perflibs.openmp=disabled
```

This covers:

- value variants;
- boolean variants;
- root constraints on a transitive dependency;
- root constraints on a direct dependency;
- a no-code logging bundle;
- dependency-provided system externals;
- compiler selection;
- local `develop` sources;
- package-isolated configure/build/install;
- CMake package discovery through prefixes;
- environment lock files and views; and
- the runnable installed root artifact.

## 5. Measured platform

Measured on 2026-07-30:

| Item | Value |
| --- | --- |
| Container | Ubuntu 24.04 arm64 |
| Compiler | GCC 13.3 |
| C++ language level | C++23 |
| CMake | 3.28.3 |
| Spack | 1.2.2 |
| Default environment | pass |
| Alternate environment | pass |
| TulaCMake installed consumer | pass |

## 6. Adding a feature

A new infrastructure feature is accepted in this order:

1. Add or extend one focused CMake fixture.
2. Make the behavior observable in a generated header, exported target, or
   executable output.
3. Add one Spack variant or dependency edge to the responsible package recipe.
4. Add the smallest environment matrix entry that changes that choice.
5. Run the native package tests.
6. Update the design documents and deck.

Do not add variant combinations to `tula_boilerplate` itself merely to create a
test matrix. The recipe/environment matrix owns package configuration; the
boilerplate stays a readable example.

## 7. Production migration gates

For Tula:

- all current header behavior tests pass;
- every enabled variant maps to explicit dependencies;
- generated `TULA_HAS_*` capability macros match the concrete graph;
- exported `tula::headers` works in a separate consumer.

For Kidscpp:

- solver tests pass;
- real TolTEC NetCDF reader fixture passes;
- exported `kids::kids` works in a separate consumer.

For Citlali:

- library tests pass;
- the installed CLI passes `--help`, `--version`, and config tests;
- the real-data RTC integration fixture passes when supplied;
- the complete package is consumed from an installed prefix.

No production package is marked migrated based only on CMake configuration.
