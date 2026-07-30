tula-cmake
===========

``tula-cmake`` is the typed Python source-superbuild for TolTEC C++ projects.
It recursively composes owned projects with CMake/CPM while selecting Conan,
CPM, system, or disabled acquisition independently for external features. It
owns the project-manifest models, feature registry, generated manifests,
installed CMake modules, and one-command downstream workflow.

.. toctree::
   :maxdepth: 2

   architecture
   spack_experiment
   workflow
   distribution
   features
   testing
   models
   api

The registry and workflow inputs are Pydantic models. Their generated field
contracts and JSON schemas are available in :doc:`models`.
