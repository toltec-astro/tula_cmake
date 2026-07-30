# Native Spack vertical slice

This experiment uses Spack directly.  It does not invoke `tula-cmake`, Conan,
CPM, or a project-specific wrapper.

The graph is:

```text
tula-downstream
├── tula-boilerplate
│   ├── tula-lib-a
│   ├── tula-logging (Spack bundle)
│   │   ├── fmt
│   │   └── spdlog
│   └── tula-perflibs
└── tula-lib-b
```

Spack 1.2.2 is the validated version.  After obtaining Spack and sourcing its
shell support:

```sh
git clone --depth 1 --branch v1.2.2 https://github.com/spack/spack.git
. spack/share/spack/setup-env.sh
```

Inspect, concretize, and install the default configuration with native Spack
commands:

```sh
spack -C config -e environments/default spec
spack -C config -e environments/default concretize
spack -C config -e environments/default install
spack -C config -e environments/default find -lv
environments/default/.spack-view/bin/tula_downstream
```

The alternative environment proves that the downstream root can change a
transitive `tula-lib-a`, its direct `tula-lib-b`, and transitive perflibs:

```sh
spack -C config -e environments/alternate concretize
spack -C config -e environments/alternate install
environments/alternate/.spack-view/bin/tula_downstream
```

The important configuration is ordinary Spack spec syntax:

```yaml
specs:
  - >-
    tula-downstream@0.1.0
    ^tula-lib-a flavor=vanilla
    ^tula-lib-b flavor=fast
    ^tula-perflibs+openmp
```

`^tula-lib-a` is transitive through `tula-boilerplate`; the root does not need
to duplicate boilerplate's dependency declaration.  Local source trees use
Spack's standard `develop` entries during this development experiment.

The development container contains GCC 13 plus compatible distro builds of
CMake, GNU Make, fmt, and spdlog. Add the optional configuration scope below
to pin that compiler and exercise Spack's external-package path:

```sh
spack -C config -C config/devcontainer \
    -e environments/default concretize
spack -C config -C config/devcontainer \
    -e environments/default install
```

Without that additional scope, the exact same package graph is built through
Spack from source or a matching build cache.
