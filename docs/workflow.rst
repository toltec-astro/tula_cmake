Build workflow
==============

The downstream entry point is:

.. code-block:: console

   $ uvx --from tula-cmake==3.1.0 tula-cmake build

The command performs three visible phases:

``bootstrap``
   Optionally installs shared Conan configuration and ensures a default profile
   exists when the caller did not supply profiles.

``conan``
   Resolves the dependency graph and generates a toolchain, dependency files,
   feature manifest, and CMake presets.

``cmake``
   Reads the generated preset document through typed models, then configures
   and builds with that preset.

Projects consume the Conan recipe behavior with:

.. code-block:: python

   python_requires = "tula-cmake/3.1.0"
   python_requires_extend = "tula-cmake.TulaConan"
