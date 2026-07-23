# tula_cmake 3.1

`tula_cmake` preserves the Tula feature/provider contract while delegating each
provider to the strongest available implementation:

- `disabled`: the feature contributes no requirement or CMake target.
- `conan`: Conan owns acquisition, graph resolution, and CMake discovery.
- `cpm`: Tula uses pinned, checksummed CPM source archives.
- `system`: CMake discovers an already-installed package.

Every enabled provider produces the same logical `tula::<feature>` target.
The initial vertical slice contains only `logging` (`spdlog` plus `fmt`).

Downstream CMake is deliberately explicit:

```cmake
project(my_project LANGUAGES CXX)
include(TulaProject)
tula_resolve_features()
```

Profiles select the feature and provider:

```ini
[options]
&:logging=conan
&:logging_level=info
```

Compose that project profile with the compiler profile shipped by the installed
package:

```sh
base_profile="$(uv run tula-cmake profile linux-clang20-debug)"
uv run conan install . \
  --profile:all="${base_profile}" \
  --profile:all=profiles/logging-conan \
  --build=missing
```

Run the fast unit loop with:

```sh
uv run python -m unittest discover -s tests -v
```
