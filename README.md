# tula_cmake 3.1

`tula_cmake` is the typed Conan 2 and CMake superbuild infrastructure for
TolTEC C++ packages.

It is distributed as:

- a Python wheel containing the `tula-cmake` CLI, validated models, and build
  workflow;
- a Conan `python_requires` recipe containing reusable recipe behavior and the
  installed registry/CMake resources.

## Downstream command

```sh
uvx --from tula-cmake==3.1.0 tula-cmake build .
```

The command exposes three phases:

1. bootstrap Conan configuration and profile state;
2. run `conan install --build=missing`;
3. configure and build through Conan's generated CMake preset.

CMake does not invoke Conan.

## Recipe integration

```python
python_requires = "tula-cmake/3.1.0"
python_requires_extend = "tula-cmake.TulaConan"
```

```cmake
include(TulaProject)
tula_resolve_features()
```

The current registry contains:

- `logging`: one meta-feature providing a compatible fmt + spdlog pair through
  disabled, system, Conan, or CPM acquisition;
- `perflibs`: a system feature centralizing Threads, optional OpenMP, optional
  oneMKL, runtime validation, and capability definitions.

## Source layout

```text
src/tula_cmake/
├── models.py
├── registry.py
├── recipe.py
├── workflow.py
├── cli.py
├── resources.py
├── py.typed
└── data/
    ├── registry.yaml
    ├── cmake/
    │   ├── infrastructure/
    │   │   ├── TulaProject.cmake
    │   │   ├── TulaConfigHeader.cmake
    │   │   └── TulaCPM.cmake
    │   └── resolvers/
    │       ├── logging.cmake
    │       └── perflibs.cmake
    ├── templates/
    └── profiles/
```

Pydantic models validate YAML and generated preset JSON boundaries. Package
data remains below the installed Python package so both wheels and Conan
exports resolve the same resources reliably.

Resolver wiring follows one convention instead of repeating Python/CMake
symbols in YAML. A registry feature named `logging` maps to
`cmake/resolvers/logging.cmake`, whose public entry point is
`tula_resolve_logging()`.

The Sphinx site explicitly renders every public Pydantic model, its field
descriptions, validators, and JSON schema. Documentation warnings fail the
build.

## Development

The project is linked to
[`Jerry-Ma/cookiecutter-pypackage`](https://github.com/Jerry-Ma/cookiecutter-pypackage)
at the `v2026` checkout through Cruft.

```sh
just qa
just docs
just build
just cruft-check
```

The repository-level container acceptance remains:

```sh
just all
```
