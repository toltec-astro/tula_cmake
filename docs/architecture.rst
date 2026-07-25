Architecture
============

The package deliberately separates executable Python from installed build
resources:

.. code-block:: text

   src/tula_cmake/
   ├── models.py          # Pydantic contracts
   ├── registry.py        # YAML loading and manifest rendering
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

All external YAML and JSON inputs cross a Pydantic boundary before they reach
Conan or CMake. The generated :doc:`models` page exposes those field contracts,
validators, and JSON schemas directly from the runtime models.

The registry is declarative; feature-specific behavior remains in CMake
resolver modules. Resolver wiring is derived rather than copied into YAML:

.. code-block:: text

   feature: logging
      │
      ├── module: data/cmake/resolvers/logging.cmake
      └── command: tula_resolve_logging()

``load_registry()`` verifies the convention-derived module exists before Conan
generation. ``TulaProject.cmake`` derives the corresponding command directly
and verifies that it and the normalized target exist during configure; the
generated manifest does not repeat the command name.

Feature contracts
-----------------

``logging``
   A single meta-feature.  Every provider supplies compatible ``fmt`` and
   ``spdlog`` targets, and consumers link only ``tula::logging``.

``perflibs``
   The first complex system feature.  It centralizes Threads, optional OpenMP,
   optional oneMKL, runtime validation, imported targets, and capability
   definitions behind ``tula::perflibs``.

Resource placement
------------------

``cmake/infrastructure``
   Public framework modules placed on ``CMAKE_MODULE_PATH``. They load the
   manifest, generate configuration headers, and provide shared CPM support.

``cmake/resolvers``
   Feature implementations loaded by absolute path from the generated
   manifest. One file and one public command exist per feature.

CMake resources and templates are package data because they must be
addressable through the installed wheel and through Conan's exported
Python-require. Keeping them below ``tula_cmake/data`` avoids global
installation paths and makes resource ownership explicit.
