# Dependency Target Files# Package Modules



Each file defines a dependency with tri-modal resolution (CONAN → CPM → SYSTEM).This directory contains modern tri-modal package finder modules that support CONAN/CPM/SYSTEM modes with automatic fallback.



## Naming Convention (v3 Architecture)All modules use the `tula_deps_register()` system and create `tula::*` interface targets.



Target files must define functions following this pattern:## Architecture



```cmake### Three-Phase Workflow

function(TULA_{PACKAGE}_TRY_CONAN)

    # Try to find package via Conan```cmake

    # Set TULA_{PACKAGE}_CONAN_SUCCESS=TRUE/FALSE# Phase 1: Register dependencies (before Conan install)

endfunction()include(Eigen3)

include(bitmask)

function(TULA_{PACKAGE}_TRY_CPM)

    # Fetch package via CPM# Phase 2: Run Conan install for all registered CONAN dependencies

    # Set TULA_{PACKAGE}_CPM_SUCCESS=TRUE/FALSEtula_conan_install()

endfunction()

# Phase 3: Create targets (invokes callbacks, CPM, or find_package)

function(TULA_{PACKAGE}_TRY_SYSTEM)tula_deps_create_targets()

    # Find package via find_package```

    # Set TULA_{PACKAGE}_SYSTEM_SUCCESS=TRUE/FALSE

endfunction()### Automatic Fallback



function(TULA_{PACKAGE}_CREATE_WRAPPER)Each package tries modes in priority order until one succeeds:

    # Create tula::{PACKAGE} wrapper target1. **CONAN** - Conan package manager (callback-based target creation)

    make_tula_target({PACKAGE} dependencies...)2. **CPM** - CMake Package Manager (downloads from Git)

endfunction()3. **SYSTEM** - System-installed packages (find_package)



tula_deps_register({PACKAGE})If a mode fails, the next mode is automatically tried.

```

## Modules

## Migration Status

### Individual Libraries

### ✅ Updated to v3 Architecture- **`bitmask.cmake`** - Type-safe bitmask operations (header-only)

- **`CCfits.cmake`** - CCfits FITS file I/O library for astronomy (C++ wrapper for cfitsio)

- **Eigen3.cmake** - Reference implementation- **`Ceres.cmake`** - Ceres Solver nonlinear optimization library

  - Full tri-modal support with automatic fallback- **`Eigen3.cmake`** - Eigen3 linear algebra library ✓ Full tri-modal support

  - MKL and threading options- **`FFTW.cmake`** - FFTW Fast Fourier Transform library

  - Clean naming convention- **`MXX.cmake`** - MXX modern MPI C++ wrapper library

- **`NetCDF.cmake`** - NetCDF C library for scientific data

### ⏳ Legacy (v2) - Need Migration- **`NetCDFCXX4.cmake`** - NetCDF C++ bindings (NetCDF-CXX4)

- **`Re2.cmake`** - Google RE2 regular expression library

All other files still use the old callback-based system:- **`Spectra.cmake`** - Spectra eigenvalue solver library

- `bitmask.cmake`- **`Yaml.cmake`** - yaml-cpp YAML parser

- `CCfits.cmake`

- `Ceres.cmake`### Meta Packages

- `FFTW.cmake`- **`logging.cmake`** - Logging stack (spdlog + fmt) → creates `tula::logging`

- `fmt.cmake`- **`testing.cmake`** - Testing stack (GTest + Google Benchmark) → creates `tula::testing`

- `logging.cmake`- **`perflibs.cmake`** - Performance libraries (OpenMP + MKL + Threads) → creates `tula::perflibs`

- `MXX.cmake`

- `NetCDF.cmake`## Usage Pattern

- `NetCDFCXX4.cmake`

- `perflibs.cmake`### Basic Usage (Automatic Mode Selection)

- `Re2.cmake`

- `Spectra.cmake````cmake

- `testing.cmake`# In CMakeLists.txt (after project() call)

- `Yaml.cmake`include(Eigen3)                    # Register Eigen3

tula_conan_install()               # Install CONAN packages

## Target File Templatetula_deps_create_targets()         # Create all targets



Use `Eigen3.cmake` as a reference when migrating or creating new target files.target_link_libraries(my_target PRIVATE tula::Eigen3)

```

### Minimal Example

### Force Specific Mode

```cmake

include_guard(GLOBAL)```cmake

include(verbose_message)# Force CPM mode for Eigen3

cmake -DTULA_Eigen3_MODE=CPM ..

if(TARGET tula_{PACKAGE})

    return()# Valid modes: CONAN, CPM, SYSTEM

endif()```



function(TULA_{PACKAGE}_TRY_CONAN)## Creating New Package Modules

    find_package({PACKAGE} QUIET CONFIG)

    if({PACKAGE}_FOUND OR TARGET {PACKAGE}::{PACKAGE})### Template for Callback-Based Package

        set(TULA_{PACKAGE}_CONAN_SUCCESS TRUE PARENT_SCOPE)

    else()```cmake

        set(TULA_{PACKAGE}_CONAN_SUCCESS FALSE PARENT_SCOPE)# MyPackage.cmake - Description

    endif()include(verbose_message)

endfunction()

if(TARGET mypackage::mypackage)

function(TULA_{PACKAGE}_TRY_CPM)    message(STATUS "(MyPackage) Target already exists, skipping")

    include(CPM)    return()

    CPMAddPackage(endif()

        NAME {PACKAGE}

        GITHUB_REPOSITORY org/{PACKAGE}# Callback for CONAN mode target creation

        GIT_TAG v1.0.0function(_tula_mypackage_create_conan_target)

    )    if(TARGET mypackage::mypackage)

    if({PACKAGE}_ADDED OR TARGET {PACKAGE}::{PACKAGE})        return()

        set(TULA_{PACKAGE}_CPM_SUCCESS TRUE PARENT_SCOPE)    endif()

    else()    

        set(TULA_{PACKAGE}_CPM_SUCCESS FALSE PARENT_SCOPE)    # Find package in CMAKE_INCLUDE_PATH (set by conan_toolchain.cmake)

    endif()    set(MYPACKAGE_INCLUDE_DIR "")

endfunction()    foreach(_path IN LISTS CMAKE_INCLUDE_PATH)

        if(_path MATCHES "mypackage")

function(TULA_{PACKAGE}_TRY_SYSTEM)            set(MYPACKAGE_INCLUDE_DIR "${_path}")

    find_package({PACKAGE} QUIET CONFIG)            break()

    if({PACKAGE}_FOUND OR TARGET {PACKAGE}::{PACKAGE})        endif()

        set(TULA_{PACKAGE}_SYSTEM_SUCCESS TRUE PARENT_SCOPE)    endforeach()

    else()    

        set(TULA_{PACKAGE}_SYSTEM_SUCCESS FALSE PARENT_SCOPE)    if(NOT MYPACKAGE_INCLUDE_DIR)

    endif()        message(STATUS "  ✗ MyPackage not found in CMAKE_INCLUDE_PATH, will try next mode")

endfunction()        return()

    endif()

function(TULA_{PACKAGE}_CREATE_WRAPPER)    

    include(make_tula_target)    # Create target

    make_tula_target({PACKAGE} {PACKAGE}::{PACKAGE})    add_library(mypackage::mypackage INTERFACE IMPORTED GLOBAL)

endfunction()    target_include_directories(mypackage::mypackage INTERFACE "${MYPACKAGE_INCLUDE_DIR}")

    message(STATUS "  ✓ Created mypackage::mypackage target from Conan: ${MYPACKAGE_INCLUDE_DIR}")

tula_deps_register({PACKAGE})endfunction()

```

# Register dependency

## Notestula_deps_register(MyPackage

    CONAN_NAME mypackage

- **Conan packages**: Listed in `../../conanfile.py`    CONAN_TARGET_CALLBACK _tula_mypackage_create_conan_target

- **CPM cache**: `~/.tula_cache/cpm/`    CONAN_TARGET_NAME mypackage::mypackage

- **Mode override**: `-DTULA_{PACKAGE}_MODE=CONAN|CPM|SYSTEM`    CPM_GITHUB_REPOSITORY org/mypackage

    CPM_GIT_TAG v1.0.0
    SYSTEM_NAME MyPackage
    FIND_PACKAGE_ARGS CONFIG
)

# Create tula wrapper target (after tula_deps_create_targets())
if(TARGET mypackage::mypackage)
    include(make_tula_target)
    make_tula_target(MyPackage mypackage::mypackage)
endif()
```

## Configuration

### Global Mode Selection
Set in CMakeLists.txt or via command line:
```cmake
# Command line
cmake -DTULA_PACKAGE_MODE=CPM ..

# Valid values: CONAN (default), CPM, SYSTEM
```

### Per-Package Override
```cmake
cmake -DTULA_Eigen3_MODE=SYSTEM -DTULA_bitmask_MODE=CPM ..
```

## Requirements

- **CMake 4.1+** (uses modern policies and features)
- **Conan 2.x** (for CONAN mode)
- **Git** (for CPM mode)
- **System packages** (for SYSTEM mode fallback)
