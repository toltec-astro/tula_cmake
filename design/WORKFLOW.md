# Workflows

## 1. Fresh development machine

The clean-machine location workflow is owned by `tolteca_deploy`. Clone the
editable repositories as siblings, write a location config containing local
`file://` sources (or immutable remote Git sources), and bootstrap it:

```console
uvx --from ./tolteca_deploy tolteca_deploy setup \
  --config ./toltec_astro_dev.yaml
cd ./toltec_astro_dev
source dotbashrc                    # or: direnv allow
just run update                     # reconcile sources + generate Spack env
just cpp-install                    # concretize, install, test, smoke-check
```

The location pins Spack 1.2.2 under `.tools/spack`. Its config, build stage,
environment, lock, and view are location-specific; its compiled store and
download cache are user-shared by default and can be location-scoped.
Linux profiles require GCC 14 or LLVM 20; GCC 13 is deliberately absent.
Editor and dev-container files are local developer conveniences, not exported
deployment inputs. The profile plus native Spack commands is the portable
contract.

The expected checkout inside the container is:

```text
/workspaces/cpp/
├── tolteca_deploy/
├── tula_cmake/
├── tula/
├── kidscpp/
├── citlali/
├── tlaloc/
├── tolteca_test_data/   optional integration fixtures
├── toltec_astro_dev.yaml
└── toltec_astro_dev/    generated self-contained location
```

Once the production environment is installed, run the observation fixture
from the work-directory root so its relative `./data` path resolves:

```console
cd /workspaces/cpp/tolteca_test_data/tolteca_workdir
/workspaces/cpp/toltec_astro_dev/spack/development/linux-gcc14/.spack-env/view/bin/citlali \
  redu/citlali_o149101_0_2_c1.yaml
```

Citlali resolves every path in that YAML at runtime. A complete reduction
requires the science and telescope NetCDF files, APT ECSV file, and the tune
fit reports selected by `solver.fitreportdir`; the executable itself has no
source-tree dependency.

The repeatable gate performs the same invocation, captures the full log, and
asserts filtered products for all three arrays:

```console
cd /workspaces/cpp/tula_cmake
just citlali-real-workdir
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

Tlaloc uses the same two-lane integration layout:

```text
tula_cmake/environments/integration/tlaloc/
├── gcc14/spack.yaml
└── llvm20/spack.yaml
```

The YAML manifests, repository configuration, recipes, and patches are
versioned. Development locks and views remain local because develop specs
contain absolute checkout paths and the views link to machine-local prefixes.

The FITS adapter has an explicit provider matrix:

```text
tula_cmake/environments/integration/tula_ccfits/
├── gcc14_external/spack.yaml
├── llvm20_external/spack.yaml
├── gcc14_source/spack.yaml
└── llvm20_source/spack.yaml
```

Run it with `just tula-ccfits-matrix`. Both upstream libraries switch policy
together; Citlali sees the same `tula_deps::ccfits` target in every case.

## 4. Native macOS

The tested native compiler is the keg-only Homebrew LLVM 20.1.8, not
AppleClang and not an unversioned Homebrew LLVM:

```console
brew install llvm@20 gcc@14 cmake ninja pkgconf
/opt/homebrew/opt/llvm@20/bin/clang++ --version
```

The packaged `tolteca_deploy` profile registers the absolute compiler paths in
`data/spack/config/macos-homebrew-llvm20/packages.yaml`; developers do not
need to link the keg or modify their shell PATH. Its generated location exposes
the pinned Spack bootstrap and native commands.

The full Citlali graph also registers Homebrew GCC 14's `gfortran` for FFTW's
build-language edge and pins Spack CMake 3.27.9 because the Ceres 2.2 recipe
does not accept CMake 4.x. C and C++ compilation remains exact LLVM 20.1.8.
It selects serial NetCDF C 4.9.3 from source, bypassing the stale 4.8.1 patch
path and retaining a working export contract with NetCDF C++4 4.3.1.
The compiler keg does not include OpenMP, so the profile builds the matching
`llvm-openmp@20.1.8` runtime with Spack and requests `citlali+openmp`. The
option propagates across Citlali, Kidscpp, Tula, and `tula-perflibs`; the
adapter alone resolves and exports the compiler/runtime details.

## 5. Local multi-repository development

Each selected source repository owns a small `spack_repo/develop.yaml` mapping:

```yaml
# kidscpp/spack_repo/develop.yaml
develop:
  kidscpp: {spec: "kidscpp@3.1.0", path: .}
```

`location.spack.develop.sources` lists source repositories once. During
generation, `tolteca_deploy` reads their mappings, resolves paths relative to
each repository root, and composes the native environment's `develop:` block.
It rejects duplicate package ownership and does not maintain a second central
package-to-path map.

Typical edit cycle:

```console
source toltec_astro_dev/dotbashrc
spack -e "$TOLTECA_CPP_ENV" concretize --force
spack -e "$TOLTECA_CPP_ENV" install --test=root
spack -e "$TOLTECA_CPP_ENV" find -lv
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

The accepted Tlaloc matrix is also part of `just all`:

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

## 6. Debugging a package build

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

## 7. End-user installation

The released workflow is owned by a `tolteca_deploy` location:

```console
uvx --from git+https://github.com/toltec-astro/tolteca_deploy.git@v0.1.0 \
  tolteca_deploy config write toltec_cpp_release location.yaml
uvx --from git+https://github.com/toltec-astro/tolteca_deploy.git@v0.1.0 \
  tolteca_deploy setup --config location.yaml
cd /path/to/location
source dotbashrc
just run update
just cpp-install
citlali --version
```

`tolteca_deploy` packages the accepted recipe-repository sources, root spec,
compiler/external policy, and required lock. Users still see native Spack
concepts and commands.

The current release gate builds the locked graph from source. Signed buildcache
publication is a deferred optimization and will not change this interface.

## 8. External application integration

A project may remain outside a Spack root graph while consuming an installed
prefix. Its native CMake boundary remains ordinary component discovery:

```cmake
find_package(tula 3.1 CONFIG REQUIRED COMPONENTS ecsv)
target_link_libraries(tlaloc_clip PRIVATE tula::ecsv)
```

Packaging the external application as a Spack root is preferred once its
integration is accepted, because the concretizer can then verify its complete
graph. Tlaloc now follows that model: its repository owns the recipe, the root
environment selects the compiler and local checkout, and CMake requests only
the Tula ECSV component it uses.

## 9. Release workflow

Each source repository:

1. tags and publishes its source;
2. updates the version/checksum in its owned recipe;
3. passes source-build and package tests;
4. is concretized in the supported environment matrix;
5. updates and tests the `tolteca_deploy` release locks; and
6. may later publish signed buildcache artifacts.

The recipe and CMake package config are tested together. A source tag is not
considered releasable if only an in-tree build passes.
