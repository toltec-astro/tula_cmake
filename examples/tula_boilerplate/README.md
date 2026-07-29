# tula_boilerplate

This is the minimal project-author example for `tula_cmake`. Its manifest
declares one external meta-feature:

```yaml
dependencies:
  projects: {}
  features:
    logging:
      default_provider: conan
```

Its CMake target links only the normalized `tula::logging` contract; it does
not branch on fmt, spdlog, Conan, CPM, or system acquisition.

Build it directly with:

```sh
./build
```

For development against the surrounding checkout:

```sh
TULA_CMAKE_DEV_PROJECT=../.. ./build
```

The executable prints the project version and effective logging provider.
`tula_downstream` demonstrates acquiring this project transitively through the
owned-project catalog.
