# Boilerplate/downstream vertical slice

Status: implementation acceptance specification, 2026-07-29.

## Purpose

The slice proves the architectural distinction between a source project and
an external feature:

```text
tula_downstream
└── tula_boilerplate                 provider: cpm
    └── logging (fmt + spdlog)       provider: conan
```

`tula_boilerplate` must never be created or consumed as a Conan package during
this test. Conan must contain only the external logging requirements.

## User experience

From a fresh `tula_downstream` checkout:

```sh
./build
```

That command must:

1. bootstrap the pinned `tula-cmake` tool;
2. discover the boilerplate manifest transitively;
3. install Conan-selected logging dependencies;
4. add boilerplate from source through CPM;
5. configure and build both projects as one CMake graph; and
6. run a downstream executable that reports both project and feature-provider
   identity.

For development in this repository:

```sh
TULA_CMAKE_DEV_PROJECT=../.. ./build
```

No manual `conan export`, `conan create`, `conan install`, or CMake preset
selection is part of the public workflow.

## Required assertions

Automated tests must prove:

- both manifests validate through typed models;
- traversal discovers `tula_boilerplate` and its logging feature;
- the resolved project provider is `cpm`;
- the resolved logging provider is `conan`;
- generated Conan requirements contain fmt and spdlog but not
  `tula-boilerplate`;
- generated CMake project metadata points at the boilerplate source tree;
- CMake reports `tula_boilerplate: cpm` and `logging: conan`;
- the downstream binary links and runs;
- a root `--provider logging=...` override changes the transitive selection or
  fails clearly when that provider is unavailable.

## Completion boundary

The slice is complete only after it passes from an isolated output directory
inside the GCC 13 development container and the design, Sphinx documentation,
and current-state slide deck describe the implemented behavior rather than
the superseded package-first workflow.
