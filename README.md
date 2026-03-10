# tula_cmake

CMake infrastructure for tula v3 — Conan-centric, tri-modal dependency management.

---

## Architecture

`tula_cmake` is consumed **exclusively through Conan**. The `TulaConan` base class (in `tula_conan.py`) is subclassed by each project's `conanfile.py`. It:

1. Reads `targets/packages.yaml` — the single source of truth for all package definitions
2. Adds Conan requirements for packages in AUTO or CONAN mode
3. Generates `conan_toolchain.cmake` containing:
   - `tula_setup` block — includes `tula_sensible.cmake` and `tula_deps.cmake`
   - `tula_<Pkg>` blocks — one per enabled package; sets mode/vars and calls `tula_deps_add()`
   - `tula_target` block — creates `tula::headers` and `tula::tula` INTERFACE targets

### Toolchain Phase Constraints

CMake toolchain files run before `project()` enables languages. This means:
- `add_library(SHARED IMPORTED)` is forbidden — use `UNKNOWN IMPORTED`
- `CheckLibraryExists` is forbidden — use `find_library` + `find_path` directly
- `CMAKE_SYSTEM_PREFIX_PATH` is empty — must manually extend `CMAKE_PREFIX_PATH`
  with arch-specific dirs like `/usr/lib/aarch64-linux-gnu/cmake/<pkg>`

The `tula_<Pkg>.cmake` files and `tula_try_system()` in `utils/_deps_callbacks.cmake`
handle these constraints with `if(NOT CMAKE_CXX_COMPILER_LOADED)` guards.

### `tula::tula` Target Provision

The `tula_target` block (last in toolchain) creates:

```cmake
# tula::headers — header-only tula library
add_library(tula_headers INTERFACE)
target_include_directories(tula_headers INTERFACE "<tula_root>/include")
add_library(tula::headers ALIAS tula_headers)

# tula::tula — headers + all enabled deps
add_library(tula_all INTERFACE)
target_link_libraries(tula_all INTERFACE tula::headers ${TULA_DEPS})
add_library(tula::tula ALIAS tula_all)
```

`TULA_DEPS` is a CMake list accumulating each package's wrapper target (`tula::<Pkg>`)
as packages are processed. The `tula_target` block always runs last, so it sees
the fully-populated `TULA_DEPS`.

---

## Package System

### `targets/packages.yaml`

Single YAML file defining all 13 packages. Each entry has:
- `modes` — supported resolution modes (`conan`, `cpm`, `system`)
- `conan_requires` — Conan package refs (empty `[]` for CPM/system-only)
- `cmake_vars` — CMake vars passed to the package cmake file

### `targets/<Pkg>.cmake`

Each package has a corresponding cmake file with these functions:

| Function | Purpose |
|----------|---------|
| `tula_<Pkg>_add_conan()` | Find via Conan-generated CMakeDeps |
| `tula_<Pkg>_add_cpm()` | Fetch from source via CPM |
| `tula_<Pkg>_add_system()` | Find via system `find_package()` |
| `tula_<Pkg>_create_wrapper()` | Create `tula::<Pkg>` INTERFACE target |

The `tula_deps_add(TULA_DEPS <Pkg>)` call (from the toolchain block) runs mode
selection and appends the resulting `tula::<Pkg>` to `TULA_DEPS`.

### Mode Selection Logic

```
TULA_<PKG>_MODE = AUTO (default)
  → try CONAN (if conan_requires non-empty and Conan available)
  → try CPM   (if mode in package's supported list)
  → try SYSTEM
  → FATAL_ERROR if none succeed

TULA_<PKG>_MODE = CONAN/CPM/SYSTEM
  → try only that mode; FATAL_ERROR on failure (no fallback)

TULA_<PKG>_MODE = DISABLED
  → skip; package not added to TULA_DEPS
```

---

## File Structure

```
tula_cmake/
├── tula_conan.py          # TulaConan base class (Conan Python)
├── tula_sensible.cmake    # Standalone build defaults (RPATH, C++23, etc.)
├── tula_deps.cmake        # tula_deps_add() API
├── targets/
│   ├── packages.yaml      # All package definitions (SSOT)
│   ├── Ceres.cmake
│   ├── Clipp.cmake
│   ├── Csv.cmake
│   ├── Eigen3.cmake
│   ├── Enum.cmake
│   ├── Grppi.cmake
│   ├── logging.cmake
│   ├── NetCDF.cmake
│   ├── NetCDFCXX4.cmake
│   ├── perflibs.cmake
│   ├── Spectra.cmake
│   ├── testing.cmake
│   └── Yaml.cmake
├── utils/
│   ├── _deps_callbacks.cmake  # tula_try_system/conan/cpm helpers
│   └── ...
├── cmake/
│   ├── FindNetCDFCXX4.cmake   # Custom Find module (UNKNOWN IMPORTED)
│   └── ...
├── profiles/
│   ├── _base/                 # Composable profile fragments
│   │   ├── base
│   │   ├── debug
│   │   ├── release
│   │   ├── linux-clang18
│   │   ├── linux-clang20
│   │   ├── linux-gcc
│   │   ├── linux-gcc14
│   │   ├── brew-llvm
│   │   └── brew-gcc
│   ├── linux-clang20-debug    # Primary Linux profile
│   ├── linux-clang20-release
│   ├── linux-clang18-debug/release
│   ├── linux-gcc14-debug/release
│   ├── linux-gcc-debug/release
│   ├── brew-llvm-debug/release
│   ├── brew-gcc-debug/release
│   └── default-debug/release  # Platform autodetect
└── tests/
    ├── test_matrix.py         # Test runner
    ├── test_config.yaml       # Test definitions
    └── results/               # Test outputs
```

---

## Profiles

Profiles compose modular `_base/` fragments. Example:

```ini
# linux-clang20-debug
include(_base/base)
include(_base/linux-clang20)
include(_base/debug)
```

The `_base/linux-clang20` fragment:
```ini
{% set cc = "clang-20" %}
{% set cxx = "clang++-20" %}
{% set compiler, version, _ = detect_api.detect_clang_compiler(cxx) %}
[settings]
os=Linux
arch={{ detect_api.detect_arch() }}
compiler={{ compiler }}
compiler.version={{ detect_api.default_compiler_version(compiler, version) }}
compiler.libcxx=libstdc++11
compiler.cppstd=23
[buildenv]
CC={{ cc }}
CXX={{ cxx }}
```

---

## Tests

The test framework (`tests/test_matrix.py`) builds a small project for each test in
`tests/test_config.yaml`, running conan install → cmake configure → build → execute.

```bash
# Run quick smoke tests
cd tula_cmake/tests
uv run test_matrix.py --group quick --verbose

# Run all tests
uv run test_matrix.py --group full

# Test a specific package + mode
uv run test_matrix.py --package Eigen3 --mode cpm
```

See `tests/README.md` for details.
