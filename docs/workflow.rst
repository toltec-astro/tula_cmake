Build workflow
==============

The downstream entry point remains one checked-in command:

.. code-block:: console

   $ ./build

The launcher obtains the pinned Python tool before any dependency graph
exists:

.. code-block:: console

   $ uv tool run \
       --from git+https://github.com/toltec-astro/tula_cmake.git@v3.1.0 \
       tula-cmake build .

During joint development, ``TULA_CMAKE_DEV_PROJECT`` selects a local
``tula_cmake`` checkout. ``TULA_CMAKE_SOURCE`` can override the release source
without editing the launcher.

Project manifest and catalog
----------------------------

Every project describes its identity and direct edges in
``tula-project.yaml``:

.. code-block:: yaml

   schema_version: 1
   project:
     name: tula_downstream
     version: 3.1.0
   dependencies:
     projects:
       tula_boilerplate:
         default_provider: cpm
     features: {}

The dependency's own manifest declares its external features:

.. code-block:: yaml

   schema_version: 1
   project:
     name: tula_boilerplate
     version: 3.1.0
   dependencies:
     projects: {}
     features:
       logging:
         default_provider: conan

The installed ``projects.yaml`` entry supplies acquisition and CMake identity:

.. code-block:: yaml

   tula_boilerplate:
     name: tula_boilerplate
     version: 3.1.0
     source:
       git_repository: https://github.com/toltec-astro/tula_cmake.git
       git_revision: <immutable-40-character-commit>
       source_subdir: examples/tula_boilerplate
     cmake_target: tula_boilerplate::headers

Only direct dependency names are repeated. Repository URLs and expected
targets remain centralized; transitive dependency policy remains in each
project's own manifest.

Lifecycle and artifacts
-----------------------

``bootstrap``
   ``uv tool run`` supplies the versioned CLI. The workflow optionally installs shared
   Conan configuration and ensures that a profile exists.

``prepare source projects``
   The source manager resolves catalog entries into an immutable checkout
   cache. It checks out the exact commit before reading the dependency's
   manifest. Existing checkouts are verified with ``git rev-parse``.

``resolve the recursive graph``
   Pydantic models validate catalogs and manifests. The resolver checks
   project name/version identity, duplicate sources, cycles, unused overrides,
   feature defaults, and provider support.

``prepare Conan externals``
   The workflow creates a virtual ``.tula/generated/conanfile.txt`` containing
   only external requirements whose selected provider is Conan. It invokes
   ``conan install --build=missing`` explicitly; CMake never invokes Conan.

``compose source projects``
   ``TulaProject.cmake`` reads ``tula_projects.cmake`` and calls
   ``CPMAddPackage(VERSION ... SOURCE_DIR ...)`` for each prepared owned
   project. A recursion guard ensures that a dependency cannot start another
   graph traversal.

``configure and build``
   The workflow rebases Conan's generated toolchain into a root
   ``CMakeUserPresets.json``, injects ``TulaBootstrap.cmake`` and the generated
   manifests, then configures and builds through that preset.

Generated output
----------------

The default output root is ``.tula``:

.. code-block:: text

   .tula/
   ├── sources/                         # immutable Git checkouts
   ├── generated/
   │   ├── conanfile.txt                # Conan-selected externals only
   │   ├── tula_features.cmake          # effective feature providers/options
   │   ├── tula_projects.cmake          # prepared source dirs and targets
   │   └── tula-project-lock.yaml       # resolved source provenance
   ├── generators/                      # Conan CMakeDeps/toolchain output
   └── build/                           # root CMake build tree

The source lock records either the catalog repository, commit, and
subdirectory or the explicit local path used by an override.

Root overrides and caches
-------------------------

Change an external feature provider:

.. code-block:: console

   $ ./build --provider logging=system

Use a local owned-project checkout:

.. code-block:: console

   $ ./build \
       --project-source tula_boilerplate=../tula_boilerplate

The equivalent CPM-style environment variable is
``CPM_tula_boilerplate_SOURCE``. Explicit CLI assignments are validated and
unused assignments fail.

``--source-cache`` or ``TULA_CMAKE_SOURCE_CACHE`` selects a shared checkout
cache. ``CPM_SOURCE_CACHE`` is honored as a fallback. ``--catalog`` selects an
alternate validated catalog, which is useful for organization overlays and
local Git acceptance tests.

Optional package workflow
-------------------------

The production Conan recipes, Python-require mixin, package tests, and
compiler matrix remain useful for producing and verifying installed Tula,
Kidscpp, and Citlali packages. The boilerplate and downstream examples no
longer contain Conan recipes: their only purpose is to demonstrate the
ordinary source-superbuild UX.
