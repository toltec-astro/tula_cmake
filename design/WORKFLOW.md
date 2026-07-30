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

The post-create script pins Spack 1.2.2 at `/opt/spack`. It also installs GCC
13, GCC 14, LLVM 20, CMake, Ninja, Just, and the small system dependencies used
by the vertical slice.

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

## 4. Local multi-repository development

The eventual workspace environment composes the repositories and points
selected packages at local checkouts:

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

Spack hashes recipes, variants, dependency edges, and source identity. An
edited develop checkout is rebuilt through the normal package boundary.

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

## 7. External native CMake consumer

A project such as Tlaloc may remain outside the Spack root graph while
consuming an installed Kidscpp prefix:

```console
spack -e toltec-dev build-env kidscpp -- \
  cmake -S /path/to/tlaloc -B /path/to/tlaloc/build
cmake --build /path/to/tlaloc/build
```

Its CMake project uses `find_package(kidscpp CONFIG REQUIRED)`. This is useful
for integration, but packaging Tlaloc gives stronger reproducibility and lets
the concretizer reason about its full graph.

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
