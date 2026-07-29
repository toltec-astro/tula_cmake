# tula_downstream

This project is the minimal recursive source-superbuild acceptance case:

```text
tula_downstream
└── tula_boilerplate                 cpm source project
    └── logging (fmt + spdlog)       Conan external feature
```

Build from a released package environment with:

```sh
./build
```

That one command bootstraps the pinned `tula-cmake` Python tool with `uvx`,
loads both `tula-project.yaml` manifests, runs Conan only for logging, and
configures both CMake projects in one source graph.

An organization may pass shared Conan configuration through:

```sh
./build --config-source <git-directory-file-or-url>
```

For development in this workspace:

```sh
TULA_CMAKE_DEV_PROJECT=../.. ./build
```

The downstream does not require a prebuilt `tula-boilerplate` Conan package.
It uses the `tula_cmake` superbuild directly and owns the final provider
selection for the complete transitive graph.
