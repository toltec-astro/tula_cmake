# TulaBoilerplate

TulaBoilerplate is the minimal installed library package using TulaCMake and
the TolTEC Spack conventions. It is intentionally independent of the Tula C++
library.

Its Spack recipe declares:

- `tula-cmake` as a build dependency;
- `tula-logging` as the fmt/spdlog bundle;
- `tula-lib-a` as an observable transitive value variant; and
- `tula-perflibs` as an observable transitive OpenMP capability.

Its CMake project uses ordinary package discovery:

```cmake
find_package(TulaCMake CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(TulaLibA CONFIG REQUIRED)
find_package(TulaPerflibs CONFIG REQUIRED)
```

The installed target is:

```text
tula_boilerplate::tula_boilerplate
```

Use the parent repository's Spack environments rather than configuring this
source directory against ad hoc dependency prefixes:

```console
cd ../..
just spack-matrix
```
