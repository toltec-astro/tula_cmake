# Workflows

## 1. Fresh development machine

The supported development bootstrap is the repository dev container:

1. Install Docker and a client capable of opening `devcontainer.json`.
2. Clone the workspace repositories.
3. Rebuild the dev container.
4. Run the acceptance surface inside the container:

   ```console
   cd /workspaces/cpp
   just all
   ```

The post-create script pins Spack 1.2.2 at `/opt/spack`. It installs GCC 14,
LLVM 20, CMake, Ninja, Just, and the system development packages used by the
measured chain. GCC 13 is deliberately absent from the supported matrix.
The devcontainer also mounts `${HOME}/Codes/toltec/toltec_astro/run`
read-only at the same absolute path, preserving the raw-data symlink targets
without copying 6.1 GB into the workspace or container.

The expected checkout inside the container is:

```text
/workspaces/cpp/
├── tula_cmake/
├── tula/
├── kidscpp/
├── citlali/
├── tlaloc/
├── tolteca_test_data/
├── .devcontainer/
└── justfile
```

Once the production environment is installed, run the observation fixture
from the work-directory root so its relative `./data` path resolves:

```console
cd /workspaces/cpp/tolteca_test_data/tolteca_workdir
/workspaces/cpp/tula_cmake/environments/production/gcc14/.spack-view/bin/citlali \
  redu/citlali_o149101_0_2_c1.yaml
```

Citlali resolves every path in that YAML at runtime. A complete reduction
requires the science and telescope NetCDF files, APT ECSV file, and the tune
fit reports selected by `solver.fitreportdir`; the executable itself has no
source-tree dependency.

The repeatable gate performs the same invocation, captures the full log, and
asserts filtered products for all three arrays:

```console
cd /workspaces/cpp
just citlali-real
```

## 2. Native Spack commands

The Just recipes are regression-test sequences. Every step is available as a
normal Spack command:

```console
root=/workspaces/cpp/tula_cmake/examples/spack
common=(-C "$root/config" -C "$root/config/devcontainer")

spack "${common[@]}" -e "$root/environments/default" concretize --force
spack "${common[@]}" -e "$root/environments/default" install --test=all
spack "${common[@]}" -e "$root/environments/default" find -clv
"$root/environments/default/.spack-view/bin/tula_downstream"
```

## 3. Environment profiles

A profile is a versioned Spack environment rather than a second preset model.
Each environment can specify:

- root specs and variants;
- compiler requirements;
- external packages;
- repository composition;
- concretizer unification policy;
- local development source paths; and
- the environment view.

The exact result is `spack.lock`. Separate environment directories may coexist
and may select different compilers, variants, or package versions.

The production settings are split by ownership:

```text
tula_cmake/environments/production/
├── config/
│   ├── repos.yaml
│   │   repository namespace composition
│   └── devcontainer/
│       └── packages.yaml
│           system externals and their exact prefixes
├── gcc14/
│   ├── spack.yaml
│   ├── spack.lock       generated local concrete DAG
│   └── .spack-view/     generated root-package view
└── llvm20/
    ├── spack.yaml
    ├── spack.lock       generated local concrete DAG
    └── .spack-view/     generated root-package view
```

The accepted Tula ECSV slice uses a separate component matrix:

```text
tula_cmake/environments/integration/tula_ecsv/
├── gcc14/
│   ├── spack.yaml
│   ├── spack.lock       generated local concrete DAG
│   └── .spack-view/
└── llvm20/
    ├── spack.yaml
    ├── spack.lock
    └── .spack-view/
```

The YAML manifests, repository configuration, recipes, and patches are
versioned. Development locks and views remain local because develop specs
contain absolute checkout paths and the views link to machine-local prefixes.

## 4. Local multi-repository development

The implemented production environments compose the decentralized repositories
and point selected packages at local checkouts:

```yaml
spack:
  specs:
    - citlali@4

  develop:
    tula-cmake:
      spec: tula-cmake@3.2
      path: ../../tula_cmake
    tula:
      spec: tula@3
      path: ../../tula
    kidscpp:
      spec: kidscpp@3
      path: ../../kidscpp
    citlali:
      spec: citlali@4
      path: ../../citlali
```

Typical edit cycle:

```console
spack -e dev concretize --force
spack -e dev install --test=root
spack -e dev find -lv
```

For this workspace, use the committed environments directly:

```console
spack -e tula_cmake/environments/production/gcc14 concretize --force
spack -e tula_cmake/environments/production/gcc14 \
  install --test=all --overwrite --show-log-on-error

spack -e tula_cmake/environments/production/llvm20 concretize --force
spack -e tula_cmake/environments/production/llvm20 \
  install --test=all --overwrite --show-log-on-error
```

`just production` sequences those native commands and also builds independent
consumers of the installed Tula, Kidscpp, and Citlali package configs.
Spack hashes recipes, variants, dependency edges, and source identity. The
explicit overwrite is required while iterating on a `develop` checkout because
the checkout path retains its concrete DAG hash.

The following Tlaloc commands are reserved for its pending acceptance work and
are not part of `just all`:

```console
just tlaloc

# or one native lane
spack -e tula_cmake/environments/integration/tlaloc/gcc14 \
  install --test=all --overwrite --show-log-on-error
```

The edit/build/install boundaries remain visible on disk:

```text
/workspaces/cpp/<project>/       editable Git source
          │
          ▼
<Spack stage root>/              isolated CMake build and package log
          │
          ▼
<Spack install tree>/<hash>/     installed headers, libraries, configs, CLI
          │
          ▼
<environment>/.spack-view/       links for runnable root packages
```

Do not use the source or stage directory as a downstream prefix. Package tests
and consumers must use the installed prefix or environment view.

## 5. Debugging a package build

Use Spack and CMake diagnostics directly:

```console
spack -e dev install --verbose --show-log-on-error citlali
spack logs citlali
spack build-env citlali -- /bin/bash
cmake --debug-find ...
cmake --build ... --verbose
```

TulaCMake target inspection is for concise target-contract diagnostics, not a
replacement for these tools.

## 6. End-user installation

The intended released workflow is:

```console
git clone --branch v1.2.2 https://github.com/spack/spack.git
. spack/share/spack/setup-env.sh

git clone <toltec environment repository>
spack env activate <environment>
spack concretize
spack install
spack load citlali
citlali --help
```

An organization environment repository can pin the TolTEC recipe repositories,
root spec, compiler policy, mirrors, and trusted binary caches. Users still see
native Spack concepts and commands.

When a matching signed buildcache artifact exists, Spack installs it. Otherwise
the same concrete spec is built from source. This does not change the user
interface or graph.

## 7. External application integration

A project may remain outside a Spack root graph while consuming an installed
prefix. Its native CMake boundary remains ordinary component discovery:

```cmake
find_package(tula 3.1 CONFIG REQUIRED COMPONENTS ecsv)
target_link_libraries(tlaloc_clip PRIVATE tula::ecsv)
```

Packaging the external application as a Spack root is preferred once its
integration is accepted, because the concretizer can then verify its complete
graph. Tlaloc migration is currently pending; the rejected broad attempt is
not the model to follow.

## 8. Release workflow

Each source repository:

1. tags and publishes its source;
2. updates the version/checksum in its owned recipe;
3. passes source-build and package tests;
4. is concretized in the supported environment matrix;
5. optionally publishes signed buildcache artifacts; and
6. updates the organization environment lock.

The recipe and CMake package config are tested together. A source tag is not
considered releasable if only an in-tree build passes.
