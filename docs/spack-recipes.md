# Spack recipes

Each TolTEC repository holds the Spack recipes for its own packages. A Spack
environment composes the recipe repositories and selects features with
variants on its root specs.

## Recipe repository layout

```text
<project>/spack_repo/
├── develop.yaml              # package → repository-relative path
└── toltec/<namespace>/
    ├── repo.yaml
    └── packages/<package_name>/
        ├── package.py
        └── <patches>
```

TulaCMake's repository is `toltec.tula_cmake`: `tula-cmake`, the adapters
and an override of `netcdf-cxx4` with one patch. Tula, Kidscpp, Citlali and
Tlaloc each have their own. An environment lists the inner directory, the one
that contains `repo.yaml`:

```yaml
repos:
  toltec.tula_cmake: ../tula_cmake/spack_repo/toltec/tula_cmake
  toltec.tula: ../tula/spack_repo/toltec/tula
```

## Write a recipe

A recipe states the versions, their sources and patches, the variants, the
dependencies with their types, and how variants become CMake cache variables:

```python
version("4.1.0", commit="<full commit hash>")

variant("openmp", default=True, description="Enable OpenMP")

depends_on("tula-cmake@3.2:3", type="build")
depends_on("tula@3.1:3+ecsv+openmp", when="+openmp", type=("build", "link"))
depends_on("fftw@3.3.10:", type=("build", "link"))
depends_on("eigen@3.4.0:3", type=("build", "link"))

def cmake_args(self):
    return [self.define_from_variant("CITLALI_ENABLE_OPENMP", "openmp")]
```

Version ranges:

| Rule | Example |
| --- | --- |
| Lower bound: the lowest tested version, open | `fftw@3.3.10:` |
| Upper bound only for a known incompatibility | `eigen@3.4.0:3` (Eigen's config accepts only 3.x) |
| TolTEC packages: within one major version | `tula@3.1:3` |
| An adapter has its own version; the wrapped library has a range | `tula-ccfits@1.0:1` → `ccfits@2.6:` |
| A recipe version is an immutable source | a commit, or a URL with its checksum |

A deployment profile and its lock choose the exact versions a location
builds; see `tolteca_deploy`.

## Select features

Constrain any package in the graph from the root spec. Intermediate packages
do not forward options:

```yaml
specs:
  - >-
    tula-downstream@0.1.0
    ^tula-lib-a flavor=vanilla
    ^tula-lib-b flavor=fast
    ^tula-perflibs+openmp
```

Here `tula-lib-a` and `tula-perflibs` are dependencies of
`tula-boilerplate`, not of the root. Spack merges the root constraints with
the recipes' dependency edges and writes the result to `spack.lock`. Run the
vertical slice that shows this:

```console
spack -C examples/spack/config -C examples/spack/config/devcontainer \
  -e examples/spack/environments/default concretize --force
spack -C examples/spack/config -C examples/spack/config/devcontainer \
  -e examples/spack/environments/default install --test=all
examples/spack/environments/default/.spack-view/bin/tula_downstream
```

## Develop from checkouts

`spack_repo/develop.yaml` maps each package of the repository to its source
path:

```yaml
develop:
  tula-cmake: {spec: "tula-cmake@3.2.0", path: .}
  tula-perflibs: {spec: "tula-perflibs@0.1.0", path: packages/tula_perflibs}
```

A `tolteca_deploy` location composes these mappings into its environment;
see its native-environment guide. After you edit a checkout, rebuild:

```console
spack -e "$TOLTECA_CPP_ENV" concretize --force
spack -e "$TOLTECA_CPP_ENV" install --test=root --overwrite
```

`--overwrite` is needed because a develop checkout keeps its DAG hash after
an edit.

Always consume the installed prefix or the environment view; never a source
or stage directory.
