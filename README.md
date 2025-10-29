# tula_cmake

Modular CMake infrastructure for TolTEC C++ projects.

## Features

- **Tri-modal dependency resolution** (CONAN → CPM → SYSTEM) with automatic fallback
- **Sensible C++23 defaults** (RPATH, output directories, compiler settings)
- **Minimal boilerplate** for dependency management
- **Unified cache** at `~/.tula_cache`

## Quick Start

```cmake
cmake_minimum_required(VERSION 4.1)
project(MyProject LANGUAGES CXX)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/tula_cmake/cmake" ${CMAKE_MODULE_PATH})
include(tula_cmake)

# Register dependencies
include(Eigen3)
include(NetCDF)

# Create all targets
tula_deps_create_targets()

# Use in your targets
target_link_libraries(MyTarget PRIVATE tula::Eigen3 tula::NetCDF)
```

## Usage

### Standalone Sensible Defaults Only

If you only want build configuration without dependency management:

```cmake
project(MyProject LANGUAGES CXX)
include(tula_sensible)  # Just build defaults, no dependency management
```

### Full Dependency Management

For projects needing tri-modal dependency resolution:

```cmake
project(MyProject LANGUAGES CXX)
include(tula_cmake)     # Build defaults + dependency management
```

**IMPORTANT:** Both files must be included **AFTER** `project()` call.

## Dependency Resolution

Dependencies are resolved automatically with fallback:

1. **CONAN** - Conan package manager (runs `conan install` automatically)
2. **CPM** - Downloads to `~/.tula_cache/cpm`
3. **SYSTEM** - Uses system-installed packages

Override per-package:
```bash
cmake -B build -DTULA_Eigen3_MODE=CPM     # Force CPM for Eigen3
cmake -B build -DTULA_Eigen3_MODE=SYSTEM  # Force system packages
```

## Available Dependencies

**Ready to use (v3 architecture):**
- ✅ Eigen3 - Linear algebra library

**Legacy (v2 - pending migration):**
- ⏳ bitmask, CCfits, Ceres, FFTW, fmt, logging
- ⏳ MXX, NetCDF, NetCDFCXX4, perflibs, Re2
- ⏳ Spectra, testing, Yaml

See `targets/README.md` for details on target file structure.

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `TULA_{PACKAGE}_MODE` | Force mode for package | Auto-fallback |
| `TULA_CACHE_ROOT` | Cache directory | `~/.tula_cache` |
| `CPM_SOURCE_CACHE` | CPM downloads | `${TULA_CACHE_ROOT}/cpm` |
| `CONAN_COMMAND` | Conan executable | Auto-detected |

## Examples

**Default (auto-fallback):**
```bash
cmake -B build
```

**Force specific mode:**
```bash
cmake -B build -DTULA_Eigen3_MODE=CPM
```

**Custom cache location:**
```bash
cmake -B build -DTULA_CACHE_ROOT=/custom/cache
```

## Requirements

- CMake 4.1+
- C++23 compiler
- Conan 2.x (optional, for CONAN mode)
- Git (for CPM mode)

## License

BSD-3

