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
       ├── templates/
       └── profiles/

All external YAML and JSON inputs cross a Pydantic boundary before they reach
Conan or CMake.  The registry is declarative; feature-specific behavior remains
in named CMake resolver modules.

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

CMake modules and templates are package data because they must be addressable
through the installed wheel and through Conan's exported Python-require.
Keeping them below ``tula_cmake/data`` avoids global installation paths and
makes resource ownership explicit.
