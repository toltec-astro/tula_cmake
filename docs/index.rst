tula-cmake
===========

``tula-cmake`` is the typed Python distribution that connects Conan 2 package
recipes to reusable CMake feature resolvers.  It owns the feature registry,
Conan recipe mixin, generated manifest, installed CMake modules, and the
one-command downstream workflow.

.. toctree::
   :maxdepth: 2

   architecture
   workflow
   distribution
   features
   testing
   models
   api

The registry and workflow inputs are Pydantic models. Their generated field
contracts and JSON schemas are available in :doc:`models`.
