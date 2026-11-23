# TulaCMake architecture

How the repository realizes the specification (`design/spec.md`).

## Repository layout

```text
tula_cmake/
├── CMakeLists.txt            installs the modules; builds tests/cmake when testing
├── cmake/                    the TulaCMake modules
├── packages/<adapter>/       CMake projects of the adapters built from this repository
├── spack_repo/
│   ├── develop.yaml          package → repository-relative path
│   └── toltec/tula_cmake/    recipe repository toltec.tula_cmake
├── examples/
│   ├── tula_boilerplate/     smallest installed library that uses TulaCMake
│   ├── tula_downstream/      smallest installed application that uses it
│   └── spack/                vertical-slice environments and their recipe repository
├── environments/
│   ├── integration/<gate>/<case>/spack.yaml   focused gate environments
│   └── acceptance/
│       ├── config/           configuration scopes the environments include
│       ├── development/      local-source chain, GCC 14 and LLVM 20
│       └── snapshot/unity/   immutable-source chain, GCC 14 and LLVM 20
├── tests/                    CMake fixture, consumers, manifest checker
└── justfile                  the gates
```

## Modules

`TulaCMakeConfig.cmake` includes `TulaCMake.cmake`, which includes each module
by its installed path.

| Module | Functions |
| --- | --- |
| `TulaCMakeLog.cmake` | `tula_cmake_log()`: argument check and project context over `message()` |
| `TulaCMakeInspectTarget.cmake` | `tula_cmake_inspect_target()`: resolves aliases; prints a curated or selected property set; separates unset properties |
| `TulaCMakeTargetDefaults.cmake` | `tula_cmake_target_defaults()`: standard and warnings per target; interface targets get only `INTERFACE` compile features |
| `TulaCMakeConfigHeader.cmake` | `tula_cmake_generate_config_header()` |
| `TulaCMakeGitVersion.cmake` | `tula_cmake_generate_version_header()`, `tula_cmake_detect_git_revision()`, `tula_cmake_detect_git_state()` |
| `TulaCMakeInstallPackage.cmake` | `tula_cmake_install_package()` over `CMakePackageConfigHelpers` (`SameMajorVersion`) |

The version header takes the revision, Git state, package spec and DAG hash
as arguments. When the revision or the Git state is omitted, the module runs
Git in the source directory; a recipe passes them for a reproducible build.
The compiler and C++ standard come from the target and the toolchain.

## Adapters

Logging, YAML, Eigen, perflibs, NetCDF C++4 and CCfits are small CMake
projects in `packages/`. Their recipes build them from this repository.
`tula-csv-parser` installs the pinned upstream headers and a config file
directly from its recipe.

- `tula-netcdf-cxx4` resolves the `netcdf` header, the C++ library
  (`netcdf_c++4` on Linux distributions, `netcdf-cxx4` from source builds)
  and the C library at build time, and writes the resolved paths into its
  exported interface.
- `tula-perflibs` writes the resolved `FindOpenMP` flags, include directory
  and library into its installed config. On Darwin its recipe adds the exact
  `llvm-openmp` that matches the Homebrew LLVM compiler, so a consumer gets
  that runtime and not another `libomp` on the host.
- `tula-ccfits` runs the `pkg-config` discovery of CCfits and CFITSIO once
  and exports one target.
- The recipe `netcdf_cxx4` inherits Spack's builtin recipe and adds one patch
  for 4.3.1: the upstream CMake project imports the NetCDF C target before it
  defines the `hdf5::hdf5_hl` target that this import needs. The patch defines
  that target from CMake's HDF5 HL libraries first.

## Gate environments

Each environment includes configuration scopes from
`environments/acceptance/config/`:

| Scope | Content |
| --- | --- |
| `repos.yaml` | recipe repositories: this repository and the sibling `tula`, `kidscpp`, `citlali` checkouts |
| `devcontainer/packages.yaml` | the container's system externals with their prefixes |
| `source-fits/packages.yaml` | overrides CFITSIO and CCfits to Spack builds (CCfits source cases) |
| `stage.yaml` | `build_stage: $env/.spack-stage` |

Each environment stages its builds in its own `.spack-stage/`. Spack 1.2
reuses a configured develop build without reconfiguring it, so a stage that
is shared with another environment or install tree can install nothing into
the new tree. Locks, views and stages stay untracked: develop specs contain
absolute paths, and views link to local prefixes.

`tests/check_spack_manifest_paths.py` (recipe `environment-manifests`, run
before every gate) resolves every repository-owned relative include in every
`spack.yaml`, without the sibling checkouts.

The development acceptance environments bind packages to the sibling
checkouts with `develop:` entries. The snapshot environments fetch the
recipe commits; `snapshot-matrix` redirects the GitHub URLs to the sibling
checkouts with `GIT_CONFIG_*` so that it can test commits before they are
pushed, and sets the profile and lock identity that the CLI must report.

`acceptance-matrix` reads each installed package's test log: the log must
report "100% tests passed" with at least one test, and must list the named
real-data test of that package as passed.
