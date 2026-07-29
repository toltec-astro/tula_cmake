Build workflow
==============

The downstream entry point remains one checked-in command:

.. code-block:: console

   $ ./build

The launcher obtains the pinned Python tool before any dependency graph
exists:

.. code-block:: console

   $ uvx \
       --from git+https://github.com/toltec-astro/tula_cmake.git@v3.1.0 \
       tula-cmake build .

During joint development, ``TULA_CMAKE_DEV_PROJECT`` selects a local
``tula_cmake`` checkout. ``TULA_CMAKE_SOURCE`` can override the release source
without editing the launcher.

Project manifest
----------------

Every project describes its identity and direct edges in
``tula-project.yaml``:

.. code-block:: yaml

   project:
     name: tula_downstream
     version: 3.1.0
   dependencies:
     projects:
       - name: tula_boilerplate
         provider: cpm
         source:
           path: ../tula_boilerplate
         target: tula_boilerplate::headers

The dependency's own manifest declares its external features:

.. code-block:: yaml

   project:
     name: tula_boilerplate
     version: 3.1.0
   dependencies:
     features:
       - name: logging
         provider: conan

Only direct dependencies are repeated. The root graph resolver loads
transitive manifests, verifies identity, detects cycles and duplicate sources,
and computes one effective provider assignment for each feature.

Lifecycle and artifacts
-----------------------

``bootstrap``
   ``uvx`` supplies the versioned CLI. The workflow optionally installs shared
   Conan configuration and ensures that a profile exists.

``resolve projects``
   Pydantic models validate the recursive ``tula-project.yaml`` graph. The
   workflow writes ``.tula/generated/tula_projects.cmake`` and
   ``tula_features.cmake``.

``prepare Conan externals``
   The workflow creates a virtual ``.tula/generated/conanfile.txt`` containing
   only external requirements whose selected provider is Conan. It invokes
   ``conan install --build=missing`` explicitly; CMake never invokes Conan.

``compose source projects``
   ``TulaProject.cmake`` reads the generated project manifest and calls
   ``CPMAddPackage(SOURCE_DIR ...)`` for each owned project. A recursion guard
   ensures that a dependency cannot start a second graph traversal.

``configure and build``
   The workflow rebases Conan's generated toolchain into a root
   ``CMakeUserPresets.json``, injects ``TulaBootstrap.cmake`` and both
   manifests, then runs CMake configure and build through that preset.

Provider overrides
------------------

The root can change an external feature provider without changing a child
project:

.. code-block:: console

   $ ./build --provider logging=system

Project acquisition and feature acquisition are separate decisions.
``tula_boilerplate`` is always a source project in this example; only its
logging implementation changes provider.

Remote source catalog
---------------------

The implemented slice uses local source paths so the entire orchestration can
be tested without publishing repositories. The next slice replaces those
paths with defaults from a central owned-project catalog:

.. code-block:: yaml

   tula:
     git: https://github.com/toltec-astro/tula.git
     revision: <immutable-commit>
     target: tula::headers

Each project will continue to own its direct dependency declaration. The
catalog supplies only acquisition coordinates and expected targets. Root
local overrides, a shared CPM source cache, and a generated lock record retain
the same workflow for development, CI, and releases.

Optional package workflow
-------------------------

The existing Conan recipes, Python-require mixin, package tests, and compiler
matrix remain useful for producing and verifying installed packages. They are
a separate release/validation path and no longer define how the ordinary
downstream source graph is assembled.
