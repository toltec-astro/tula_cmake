# TulaCMake Test Suite

Automated testing framework for TulaCMake dependency management system.

## Quick Start

```bash
# Run quick smoke test (~5-10 min)
./run_all_tests.sh --quick

# Run full matrix (~30-60 min)
./run_all_tests.sh

# Test specific package
uv run test_matrix.py --package Eigen3 --mode CONAN

# List all tests
uv run test_matrix.py --list-tests

# Show real-time output
uv run test_matrix.py --verbose
```

## Prerequisites

```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Required tools:**
- **uv** - Python package manager (manages conan/cmake)
- **conan** - Dependency manager
- **cmake** - Build system

**Compiler Selection**: Tests use `../profiles/default` which automatically selects:
- **macOS**: Homebrew LLVM (brew-llvm-debug)
- **Linux**: System GCC (linux-gcc-debug)

To use a different compiler, set the profile in your environment or modify the test configuration.

## Test Configuration

Edit `test_config.yaml`:

```yaml
package_info:
  Eigen3:
    supported_modes: [CONAN, CPM]
    priority: 1

tests:
  eigen3_basic:
    package: Eigen3
    mode: CONAN
    config: Debug
  
  eigen3_spectra:
    packages:
      Eigen3: CPM
      Spectra: CONAN
    config: Debug
```

## Package Modes

- **CONAN**: Conan package manager
- **CPM**: CMake FetchContent
- **SYSTEM**: System find_package

## Results

```
results/latest/
├── summary.txt          # Human-readable summary
├── matrix.csv          # Spreadsheet format
├── results.json        # Machine-readable
└── logs/<test_name>/
    ├── conan.log       # Dependency resolution
    ├── cmake.log       # Configuration
    ├── build.log       # Compilation
    └── run.log         # Execution
```

**Status:**
- ✅ PASS - All phases succeeded
- ❌ FAIL - Error in phase
- ⏱️ TIMEOUT - Exceeded time limit

## Command-Line Options

```bash
--package NAME       # Filter by package
--mode MODE          # Filter by mode (CONAN/CPM/SYSTEM)
--config CONFIG      # Filter by config (Debug/Release)
--quick              # Run priority tests only
--verbose, -v        # Show real-time command output
--list-tests         # List available tests
```

## Debugging

### Inspect Failures

```bash
# Check summary
cat results/latest/summary.txt

# Review logs
cat results/latest/logs/<test_name>/cmake.log

# Manual reproduction
cd results/latest/logs/<test_name>/project
conan install . -s build_type=Debug --build=missing
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=build/generators/conan_toolchain.cmake
cmake --build build
./build/test_executable
```

## Adding Tests

### 1. Add to test_config.yaml

```yaml
tests:
  mytest:
    package: MyPackage
    mode: CONAN
    config: Debug
```

### 2. Create test template (optional)

`templates/_test_MyPackage.inc.j2`:

```cpp
#include <mypackage/header.h>

void test_mypackage() {
    // Test code
}
```

## File Structure

```
tests/
├── test_matrix.py          # Test runner
├── test_config.yaml        # Test definitions
├── run_all_tests.sh       # Convenience script
├── templates/
│   ├── package.cmake.j2   # CMakeLists template
│   └── _test_*.inc.j2     # Test code templates
└── results/
    └── test_run_*/        # Test results
```

## CI/CD Integration

```yaml
- name: Test TulaCMake
  run: |
    cd tula_cmake/tests
    ./run_all_tests.sh --quick
```
