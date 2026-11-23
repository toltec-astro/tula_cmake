---
status: "accepted"
date: 2026-07-30
decision-makers: user [cpp 2026-07-30 03:56]
---

# Spack owns the graph and keeps its own interface

## Context and Problem Statement

The Conan 2 implementation (branch `v3.x_conan2`) made TulaCMake a Python
package with a Conan Python-require, a provider registry and a bootstrap
command, so that each dependency could come from Conan, CPM or the system.
Spack offers providers, variants, externals and environments natively. The
question was how much of TulaCMake's own layer to keep on top of Spack.

## Considered Options

* Conan 2 with the TulaCMake Python layer (provider registry, bootstrap command)
* Spack behind a TulaCMake command that wraps environments, specs and variants
* Spack with its own commands; TulaCMake is CMake only

## Decision Outcome

Chosen option: "Spack with its own commands; TulaCMake is CMake only". The
user: "if we can do everything in spack, it is better to do it with spack
way, not re-inventiing the wheel and add another cli layer that obscure the
actual phylosophy of spack. we'll add it later if proven useful and needed."

### Consequences

* Good, because users and maintainers use documented Spack commands, and
  TulaCMake installs only CMake files.
* Good, because provider choice is Spack configuration (externals or source
  builds) and needs no TulaCMake code.
* Bad, because the gates are `just` recipes that sequence Spack commands, not
  one command with its own options.
