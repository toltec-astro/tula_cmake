Architecture
============

The package deliberately separates executable Python from installed build
resources:

.. code-block:: text

   src/tula_cmake/
   ├── models.py          # Pydantic contracts
   ├── registry.py        # YAML loading and manifest rendering
   ├── superbuild.py      # recursive project graph and generated inputs
   ├── recipe.py          # Conan python_requires mixin
   ├── workflow.py        # bootstrap → Conan → CMake orchestration
   ├── cli.py             # Typer command surface
   └── data/
       ├── registry.yaml
       ├── cmake/
       │   ├── infrastructure/
       │   └── resolvers/
       ├── templates/
       └── profiles/
           ├── linux-gcc13-debug
           ├── linux-gcc14-debug
           └── linux-clang20-debug

The repository additionally owns ``examples/tula_boilerplate`` and
``examples/tula_downstream``. Together they validate the smallest complete
source-superbuild without becoming feature-matrix fixtures.

Two graph categories
--------------------

The design deliberately separates:

``project dependencies``
   Owned CMake projects such as Tula, Kidscpp, and Citlali. Each repository
   declares its direct edges in ``tula-project.yaml``. The root recursively
   resolves those manifests and composes the result through CPM. The current
   vertical slice supports local paths; the accepted next slice adds a central
   catalog of immutable Git coordinates and expected targets.

``feature dependencies``
   External capabilities such as logging, yaml-cpp, or NetCDF. Their provider
   can be Conan, CPM, system, or disabled according to the feature registry.

Conan therefore remains a dependency provider, not the owner of the
first-party project graph. “Exporting” an owned project means adding its
source metadata to the catalog; it does not require a Conan package export.

All external YAML and JSON inputs cross a Pydantic boundary before they reach
Conan or CMake. The generated :doc:`models` page exposes those field contracts,
validators, and JSON schemas directly from the runtime models.

The registry is declarative; feature-specific behavior remains in CMake
resolver modules. Resolver wiring is derived rather than copied into YAML:

.. code-block:: text

   feature: logging
      │
      ├── module: data/cmake/resolvers/logging.cmake
      ├── conan:  tula_resolve_logging_conan()
      ├── cpm:    tula_resolve_logging_cpm()
      └── system: tula_resolve_logging_system()

``load_registry()`` verifies the convention-derived module exists before Conan
generation. ``TulaProject.cmake`` derives the provider entry point from both
the feature and selected mode, calls it with :command:`cmake_language(CALL)`,
and verifies that it created the normalized target. Resolver modules contain
no generic mode switch.

Feature contracts
-----------------

``logging``
   A single meta-feature.  Every provider supplies compatible ``fmt`` and
   ``spdlog`` targets, and consumers link only ``tula::logging``.

``yaml_cpp``
   The first one-package feature. Conan, CPM, and system providers all
   normalize yaml-cpp to ``tula::yaml_cpp``. The Tula ECSV core/header test is
   the first production consumer.

``csv_parser``
   The header-only parser used by production ECSV loading. The resolver pins
   the Jerry-Ma fork at commit ``bc3bebc`` with an archive checksum, exposes
   only the provider it can actually support (CPM), and publishes
   ``tula::csv_parser``. Tula's streaming ECSV test covers custom delimiters
   and quoted fields through this target.

``netcdf_c``
   The C library boundary. Conan supplies ``netcdf/4.8.1`` and system mode
   consumes the installed ``netCDF::netcdf`` config target. Both normalize to
   ``tula::netcdf_c``.

``netcdf_cxx4``
   The C++ API layered on ``netcdf_c``. System mode uses the distribution's
   ``netcdf-cxx4`` pkg-config interface. Conan mode uses the project-owned
   ``netcdf-cxx4/4.3.1`` recipe bundled with the wheel and Python-require. The
   recipe packages the upstream ``cxx4/nc*.cpp`` sources and public headers,
   publishes ``netCDF::netcdf-cxx4``, and propagates ``netcdf/4.8.1``.
   Consumers link only ``tula::netcdf_cxx4``.

``bitmask``
   The header-only implementation used by Tula's flag-enum API. CPM retrieves
   immutable commit ``0454f32`` with an archive checksum and publishes only
   ``tula::bitmask``.

``meta_enum``
   The compile-time parser used by ``TULA_ENUM``. CPM retrieves immutable
   commit ``f940f15`` with an archive checksum and publishes only
   ``tula::meta_enum``. The package probe exercises the same internal parsing
   API as Tula; the unused upstream convenience macro contains a known typo
   and is not part of Tula's contract.

``clipp``
   The production single-header command-line parser. CPM retrieves a pinned
   maintained fork commit and normalizes it as ``tula::clipp``. ConanCenter's
   1.2.3 source is not offered because it still uses removed
   ``std::result_of``. Tula's builder test verifies flags, typed values,
   enum-backed choices, defaults, positional arguments, and ``FlatConfig``
   projection.

Tula modules that need no new provider
--------------------------------------

The feature registry models external acquisition boundaries, not every Tula
header namespace. ``FlatConfig`` and filename utilities use the existing
``logging`` target plus the C++23 standard library. ``YamlConfig`` composes
``logging`` and ``yaml_cpp``. They therefore add behavior tests but no
synthetic ``config`` or ``filesystem`` provider feature.

``perflibs``
   The first complex system feature.  It centralizes Threads, optional OpenMP,
   optional oneMKL, runtime validation, imported targets, and capability
   definitions behind ``tula::perflibs``.

``eigen``
   A package feature layered on ``perflibs``. It normalizes ``Eigen3::Eigen``
   as ``tula::eigen`` and publishes whether Eigen multithreading is enabled.
   Version 3.4.1 preserves the production API while taking the maintained 3.x
   bug-fix release.

Resource placement
------------------

``cmake/infrastructure``
   Public framework modules placed on ``CMAKE_MODULE_PATH``. They load the
   manifest, generate configuration headers, and provide shared CPM support.

``cmake/resolvers``
   Feature implementations loaded by absolute path from the generated
   manifest. One file exists per feature and one public entry point per
   supported provider mode.

Header-only CPM providers register their retrieved include tree with
``tula_register_bundled_headers``. A library that exposes those headers calls
``tula_install_bundled_headers`` at its install boundary. This keeps
checksummed, non-Conan header dependencies available to consumers of the
installed package instead of only to its source-tree build.

Configuration projection
------------------------

The registry distinguishes two kinds of CMake input:

``cmake_vars``
   Immutable implementation data such as pinned CPM URLs and checksums. These
   remain in the generated feature manifest.

``provider assignments``
   Root-selected feature acquisition supplied as repeatable
   ``--provider NAME=MODE`` values. They override the recursively collected
   manifest defaults and determine which external requirements enter the
   generated virtual Conan recipe.

``options``
   Feature-specific customization retained by the existing packaging path.
   As production projects migrate, these values will be projected from the
   root manifest into the same generated CMake state rather than duplicated
   in per-project profiles.

The generated preset is deliberately not edited by users. The workflow
rebases Conan's toolchain and build paths into a root
``CMakeUserPresets.json`` and injects the generated project and feature
manifests.

Recipes list publicly linked features in ``tula_public_features``. The shared
recipe mixin maps Conan requirements for those features to transitive header
and library edges. Provider selection and public API visibility are therefore
separate, explicit decisions.

System providers also declare any link libraries that must survive package
installation. ``TulaConan.package_info()`` projects those registry entries
into ``cpp_info.system_libs`` for public features. This is essential for
static libraries: a source-tree target can link ``PkgConfig::NETCDF_CXX4``,
but an installed ``kids::kids`` consumer still needs ``netcdf_c++4`` and
``netcdf`` on its final link line.

CMake resources and templates are package data because they must be
addressable through the installed wheel and through Conan's exported
Python-require. Keeping them below ``tula_cmake/data`` avoids global
installation paths and makes resource ownership explicit.

Testing boundary
----------------

Feature/provider behavior is exercised by the registry-driven
:doc:`testing` system, not by example packages. The production registry
declares the complete supported domains; small matrix metadata adds probes,
option-axis companion values, and environment capabilities. A catalog
completeness test rejects any provider or option value without coverage.

Repository boundary
-------------------

``tula_cmake`` is no longer nested below Tula as a Git submodule. A checked-in
``./build`` launcher obtains the pinned wheel with ``uvx`` before any CMake or
Conan graph exists. Local development selects this checkout through
``TULA_CMAKE_DEV_PROJECT``. The Conan Python-require remains available for
optional package production during the migration, but is not the bootstrap
boundary for the source-superbuild.
