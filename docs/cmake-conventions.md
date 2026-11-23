# CMake conventions

Use TulaCMake in a project's `CMakeLists.txt` to set target defaults,
generate configuration and version headers, and install a relocatable CMake
package. [`examples/tula_boilerplate`](../examples/tula_boilerplate) is a
complete library that uses every function, and
[`examples/tula_downstream`](../examples/tula_downstream) is an application
that consumes it.

## Find TulaCMake

```cmake
find_package(TulaCMake 3 CONFIG REQUIRED)
```

TulaCMake is a build dependency: declare it as `type="build"` in the
package's Spack recipe. Finding it does not change `CMAKE_MODULE_PATH` or
other global settings.

To build and install TulaCMake by hand:

```console
cmake -S . -B build/unit -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/unit --parallel
ctest --test-dir build/unit --output-on-failure
cmake --install build/unit --prefix /tmp/tula-cmake-prefix
```

## Set target defaults

```cmake
tula_cmake_target_defaults(
    TARGET my_library
    CXX_STANDARD 23
    WARNINGS
)
```

The function changes only `my_library`. It never adds directory-global flags
and never enables warnings as errors. For an `INTERFACE` target, consumers
get the C++ standard requirement but not the warnings.

## Generate a configuration header

```cmake
set(MY_PACKAGE_HAS_FEATURE 1)
tula_cmake_generate_config_header(
    TARGET my_library
    INPUT "${CMAKE_CURRENT_SOURCE_DIR}/include/my_package/config.h.in"
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/my_package/config.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
```

Your project sets the variables and decides what they mean. TulaCMake
configures the template and adds the build and install include directories
to the target.

## Generate a version header

```cmake
tula_cmake_generate_version_header(
    TARGET my_library
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/my_package/version.h"
    BUILD_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated"
    NAMESPACE my_package
    VERSION "${PROJECT_VERSION}"
    REVISION "${MY_PACKAGE_GIT_REVISION}"
    PACKAGE_SPEC "${MY_PACKAGE_PACKAGE_SPEC}"
    DAG_HASH "${MY_PACKAGE_DAG_HASH}"
)
```

The header records the version, source revision and Git state, compiler,
C++ standard, and the Spack package spec and DAG hash. Pass `REVISION`,
`PACKAGE_SPEC` and `DAG_HASH` from the recipe for a reproducible build, as
Citlali's recipe does:

```python
def cmake_args(self):
    return [
        self.define("CITLALI_PACKAGE_SPEC", str(self.spec)),
        self.define("CITLALI_DAG_HASH", self.spec.dag_hash()),
    ]
```

Without `REVISION` (a local build), TulaCMake reads the current Git commit.
The header holds no deployment profile or lock: a program reads those at run
time from `TOLTECA_SPACK_PROFILE` and `TOLTECA_SPACK_LOCK_SHA256`, which a
`tolteca_deploy` location sets.

## Install a package

```cmake
tula_cmake_install_package(
    PACKAGE MyPackage
    EXPORT MyPackageTargets
    NAMESPACE my_package::
    VERSION "${PROJECT_VERSION}"
    TARGETS my_library
    CONFIG_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/MyPackageConfig.cmake.in"
)
```

The package exports relocatable targets and a version file that accepts the
same major version. Your config template finds the package's dependencies:

```cmake
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
find_dependency(TulaPerflibs CONFIG)

include("${CMAKE_CURRENT_LIST_DIR}/MyPackageTargets.cmake")
check_required_components(MyPackage)
```

A target that has headers declares its own build and install include
directories; TulaCMake adds none.

## Diagnose a build

```cmake
tula_cmake_log(VERBOSE "Configured optional feature X")
tula_cmake_inspect_target(TARGET my_package::dependency LEVEL DEBUG)
```

Use CMake's own controls to show the messages:

```console
cmake --preset dev --log-level=DEBUG --log-context
cmake --preset dev --debug-find
cmake --build --preset dev --verbose
```

For a package that Spack builds, use Spack's diagnostics:

```console
spack -e <env> install --verbose --show-log-on-error citlali
spack logs citlali
spack build-env citlali -- /bin/bash
```
