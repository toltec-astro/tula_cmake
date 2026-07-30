# Native Spack vertical slice

This directory contains the complete native Spack acceptance setup:

```text
config/
├── repos.yaml
└── devcontainer/packages.yaml

environments/
├── default/spack.yaml
└── alternate/spack.yaml

repository/
└── spack_repo/toltec/vertical_slice/
    ├── repo.yaml
    └── packages/
```

The repository is intentionally isolated while the production package recipes
are migrated to their owning repositories.

## Direct commands

```console
common=(-C config -C config/devcontainer)

spack "${common[@]}" -e environments/default concretize --force
spack "${common[@]}" -e environments/default install --test=all
spack "${common[@]}" -e environments/default find -clv
environments/default/.spack-view/bin/tula_downstream
```

Repeat with `environments/alternate` to verify the second concrete graph.

## Tested graph differences

| Node | Default | Alternate | Relationship |
| --- | --- | --- | --- |
| `tula-lib-a` | `flavor=vanilla` | `flavor=chocolate` | transitive |
| `tula-lib-b` | `flavor=fast` | `flavor=safe` | direct |
| `tula-perflibs` | `+openmp` | `~openmp` | transitive |

`tula-logging` is a `BundlePackage`. The dev-container configuration supplies
compatible fmt and spdlog installations as explicit externals. Removing that
scope lets Spack satisfy the same dependency nodes from a build cache or source
build.
