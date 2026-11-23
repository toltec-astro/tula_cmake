# Acceptance gates

Run the gates before a change to TulaCMake, Tula, Kidscpp or Citlali lands.
Each gate is a `just` recipe that runs Spack and CMake commands; each verifies
one part of the specification (`design/spec.md`).

## Prerequisites

- The development container (`cpp/.devcontainer`): Ubuntu 24.04 with GCC 14,
  LLVM 20, CMake, Ninja, `just` and Spack 1.2.2.
- The sibling checkouts in one folder:

  ```text
  /workspaces/cpp/
  ├── tula_cmake/
  ├── tula/
  ├── kidscpp/
  ├── citlali/
  └── tolteca_test_data/   real-data fixtures (acceptance-matrix, citlali-real-workdir)
  ```

`just unit` needs only CMake. The other gates need Spack.

## Gates

| Gate | Verifies | Spec section |
| --- | --- | --- |
| `just unit` | TulaCMake installs; a fixture producer and a separate consumer use the installed functions; every repository-owned Spack include resolves | CMake conventions |
| `just spack-matrix` | Two vertical-slice environments constrain direct and transitive variants from the root | Spack recipes |
| `just tula-component-matrix` | `tula+ecsv` closure, adapter-only consumer, installed component consumer, real tune reports, missing-component failure | Dependency adapters |
| `just tula-perflibs-matrix` | `tula+perflibs` with OpenMP on and off | Dependency adapters |
| `just tula-enum-cli-matrix` | `tula+enum` and `tula+cli` closures | Dependency adapters |
| `just tula-netcdf-matrix` | `tula+netcdf` closure with file I/O | Dependency adapters |
| `just tula-grppi-matrix` | `tula+grppi` with OpenMP on and off | Dependency adapters |
| `just tula-fitting-matrix` | `tula+fitting` closure with Ceres | Dependency adapters |
| `just tula-ccfits-matrix` | `tula_deps::ccfits` with system and Spack-built CCfits and CFITSIO | Dependency adapters |
| `just acceptance-matrix` | Tula, Kidscpp and Citlali package tests, their required real-data tests, installed consumers and the installed CLI | Acceptance gates |
| `just snapshot-matrix` | The chain from immutable commits, no develop source; the CLI reports the profile and lock | Acceptance gates |
| `just citlali-real-workdir` | The installed CLI reduces observation 149101 and writes FITS products for a1100, a1400 and a2000 | Acceptance gates |
| `just check` | `unit` and `spack-matrix` | |

Each `tula-*`, `acceptance` and `snapshot` gate runs GCC 14 and LLVM 20.
`citlali-real-workdir` takes `compiler=gcc14` (default) or `compiler=llvm20`
and needs `acceptance-matrix` first. Every recipe takes `spack=<path>` to use
another Spack.

A gate fails when a test fails, or when a required real-data test did not run
or did not pass. Other tests may skip; for example, Citlali skips the tests
whose evidence manifests are not configured.

The macOS lane (Homebrew LLVM 20) is verified in a `tolteca_deploy`
location, not by these gates.

## Gate environments

```text
environments/
├── integration/<gate>/<case>/spack.yaml     one case of a focused gate
└── acceptance/
    ├── config/                              shared configuration scopes
    ├── development/{gcc14,llvm20}/          the chain from the sibling checkouts
    └── snapshot/unity/{gcc14,llvm20}/       the chain from commits
```

You can run any environment with Spack directly:

```console
spack -e environments/acceptance/development/gcc14 concretize --force
spack -e environments/acceptance/development/gcc14 \
  install --test=all --overwrite --show-log-on-error
```

Spack writes `spack.lock`, `.spack-view/` and `.spack-stage/` beside each
`spack.yaml`; Git ignores them. These environments are test fixtures; deploy
with a `tolteca_deploy` location instead.

## Add a Tula component gate

1. Add an adapter in `packages/` only where the component needs a library
   that has none.
2. Add the component target and its variant edges in Tula.
3. Add `environments/integration/tula_<component>/{gcc14,llvm20}/spack.yaml`
   with only `tula+<component>` as the root.
4. Add a recipe to the `justfile` that checks the minimal concrete graph and
   the excluded heavy dependencies, runs the package tests and builds an
   installed consumer.
