# tula_cmake 3.1

`tula_cmake` is the Tula superbuild infrastructure for Conan 2.31 and modern
CMake.

It is distributed in two forms:

- a Python wheel containing the `tula-cmake` bootstrap/build CLI;
- a Conan `python_requires` recipe containing reusable recipe behavior,
  registry data, CMake modules, templates, and profiles.

## User command

A downstream repository can pin the tool in a small checked-in script:

```sh
uvx --from tula-cmake==3.1.0 tula-cmake build .
```

The CLI performs three visible phases:

1. bootstrap Conan configuration/profile state;
2. run `conan install --build=missing`;
3. configure and build with Conan's generated CMake preset.

Useful options:

```sh
tula-cmake build . \
  --config-source https://example.org/conan-config.zip \
  --profile /path/to/compiler-profile \
  --output .tula
```

The wrapper follows Conan's recommended explicit install-plus-preset flow.
CMake does not invoke Conan.

## Recipe integration

Packages built with the infrastructure declare:

```python
python_requires = "tula-cmake/3.1.0"
python_requires_extend = "tula-cmake.TulaConan"
```

Projects then use an explicit post-`project()` CMake entry point:

```cmake
include(TulaProject)
tula_resolve_features()
```

The active registry contains generic `formatting` and custom `logging`
features. `logging` depends on `formatting`. Every enabled provider produces a
normalized `tula::<feature>` target.
