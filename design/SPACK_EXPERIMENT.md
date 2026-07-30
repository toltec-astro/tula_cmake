# Native Spack vertical-slice experiment

Status: GCC 13 vertical slice implemented and verified, 2026-07-30.

## Question

Can Spack replace both the external-dependency provider matrix and the
first-party source-project graph while retaining these properties?

- one concretized, inspectable transitive graph;
- root control over direct and transitive package options;
- system installations, binary caches, and source builds;
- an explicit logging metapackage;
- perflibs configuration independent of a particular consumer;
- isolated, coexisting environments; and
- a transparent user interface based on established Spack commands.

This experiment does not remove or modify the working Conan/CPM
implementation. It is an evidence-gathering backend under `examples/spack/`.

## Deliberate use of native Spack concepts

The public experiment has no `tula-cmake` wrapper. Its control surfaces are:

- an API v2 custom package repository;
- `spack.yaml` environments and generated `spack.lock` files;
- package `variant()` declarations;
- root `^dependency` constraints;
- `BundlePackage` for the no-code logging metapackage;
- `develop` entries for local source trees;
- `packages.yaml` externals for the dev-container system libraries; and
- an environment view containing the runnable root executable.

The `just spack-vertical-slice` recipe is only a regression gate that invokes
those commands and checks results.

## Acceptance graph

```text
tula-downstream
├── tula-boilerplate
│   ├── tula-lib-a              flavor=vanilla|chocolate
│   ├── tula-logging            no-code BundlePackage
│   │   ├── fmt
│   │   └── spdlog
│   └── tula-perflibs           +openmp|~openmp
└── tula-lib-b                  flavor=fast|safe
```

`tula-lib-a` is intentionally transitive. A downstream root spec must still
be able to select its flavor:

```text
tula-downstream
^tula-lib-a flavor=chocolate
^tula-lib-b flavor=safe
^tula-perflibs~openmp
```

Spack's `^` constraint addresses any reachable transitive node, so the root
does not copy or reinterpret boilerplate's dependency declaration.

## Perflibs boundary

The first slice represents perflibs as an installable CMake interface package,
not a bundle. Its Spack `openmp` variant maps to
`TULA_PERFLIBS_ENABLE_OPENMP`; its installed `tula::perflibs` target carries
Threads, optional compiler-native OpenMP, C++23, and capability definitions
to consumers.

This first GCC 13 experiment deliberately excludes oneAPI/MKL. Those options
need their own package dependency and runtime tests. Adding unexercised
variants would obscure rather than prove the Spack model.

## Logging boundary

`tula-logging` is a `BundlePackage`: it has no source, install payload, or
CMake target. It constrains a compatible fmt/spdlog pair. Consumers use the
normal `fmt::fmt` and `spdlog::spdlog` CMake targets supplied by its
transitive dependencies.

The optional dev-container configuration marks the matching Ubuntu fmt and
spdlog installations as non-buildable externals. Omitting that configuration
leaves the same graph Spack-managed, allowing a build-cache match or source
build. External versus Spack-managed is acquisition policy; it does not
create a different logical dependency.

## Acceptance cases

| Environment | libA | libB | perflibs | Expected executable evidence |
|---|---|---|---|---|
| `default` | `vanilla` | `fast` | OpenMP enabled | all three values reported |
| `alternate` | `chocolate` | `safe` | OpenMP disabled | all three values changed |

Both cases must:

1. concretize from `tula-downstream`;
2. show one unified transitive graph;
3. install five local CMake packages plus the logging bundle dependencies;
4. export and rediscover CMake package configurations at every edge;
5. populate the environment view; and
6. run the installed downstream executable.

## Measured result

Both environments passed in the Ubuntu 24.04 arm64 development container with
Spack 1.2.2, GCC 13.3.0, CMake 3.28.3, and C++23.

The default executable reported:

```text
tula_downstream libA=vanilla perflibs.openmp=enabled libB=fast
```

The alternate executable reported:

```text
tula_downstream libA=chocolate perflibs.openmp=disabled libB=safe
```

Spack reused the dev-container CMake, GNU Make, fmt, and spdlog installations
as explicit externals. It installed independent concrete variants of libA,
libB, perflibs, boilerplate, and downstream, while reusing the same logging
bundle. Every CMake edge consumed an installed package configuration rather
than a sibling source target.

The first run incurred two network-bound bootstrap operations: cloning Spack's
separate package repository and obtaining the Clingo concretizer. Under the
active VPN those downloads dominated elapsed time. Once present, concretizing
and building the local graph completed in seconds.

## Decision boundary

This slice proves that separate Spack package builds satisfy the graph and
customization requirements. It does not yet prove:

- the full production package matrix;
- macOS and LLVM 20 portability;
- private binary-cache publication and signatures;
- oneAPI/MKL perflibs behavior;
- released Git source acquisition instead of `develop` paths;
- migration of Tula, Kidscpp, or Citlali; or
- acceptable incremental developer rebuild time.

Those are later gates. No existing backend is removed based on this slice
alone.
