Distribution topology
=====================

The release design separates source control, package distribution, and the
user command:

.. code-block:: text

   GitHub tags                       TolTEC Conan virtual remote
   ├── tula_cmake v3.1.0             ├── tula-cmake/3.1.0
   ├── tula v3.1.0                   ├── tula/3.1.0
   ├── kidscpp v3.1.0                ├── kidscpp/3.1.0
   └── citlali v4.0.0                ├── citlali/4.0.0
                                      └── cached ConanCenter packages
             │                                      │
             └────────────── ``./build`` ───────────┘

GitHub is the authoritative source origin. The Conan remote stores recipe
revisions and compatible binaries, so Tula and kidscpp remain visible in the
dependency graph instead of becoming CMake subprojects.

Repository boundaries
---------------------

``tula_cmake``
   Python wheel, Conan Python-require, registry, CMake infrastructure,
   feature-matrix tests, boilerplate, and independent downstream example.

``tula``
   The C++ utility package. It has no infrastructure submodule.

``kidscpp``
   A normal Conan requirement on ``tula/3.1.0``.

``citlali``
   A normal Conan requirement on ``kidscpp/3.1.0``.

Every production repository carries the same small ``build`` launcher. The
launcher contains no dependency graph logic; it only selects the pinned
``tula-cmake`` CLI and forwards user arguments.

Remote layout
-------------

The intended Artifactory topology is:

.. code-block:: text

   toltec-dev-local
   toltec-release-local
   conancenter-remote
           │
           └── toltec (virtual read endpoint)

Developers receive read access. CI alone uploads to local repositories and
promotes tested recipe and binary revisions to the release repository.
Authentication and the final service URL do not belong in package recipes.
They are installed as shared Conan client configuration.

Bootstrap configuration
-----------------------

``tula-cmake build`` accepts a source supported by
``conan config install``:

.. code-block:: console

   $ TULA_CONAN_CONFIG_SOURCE=https://example.org/toltec-conan-config.zip \
       ./build

The URL is intentionally not hard-coded until the service exists. For a
released stack, the organization configuration defines the virtual remote,
profiles, global configuration, and allowed package patterns. Credentials are
handled by Conan's remote authentication, not stored in Git.

Local pre-publication flow
--------------------------

Before a remote exists, the workspace gate uses one isolated Conan home and
creates packages in dependency order:

.. code-block:: text

   conan export tula_cmake
       → tula-cmake bootstrap
       → conan export netcdf-cxx4/4.3.1
       → conan create tula
       → conan create kidscpp
       → conan create citlali

That path is a release-pipeline simulation, not the intended end-user
installation procedure. Each ``conan create`` runs source behavior tests and
an installed-target ``test_package`` consumer.

``tula-cmake bootstrap`` exports project-owned third-party recipes into the
active Conan home. Once the TolTEC remote exists, CI uploads the same recipe
and binaries; the bundled export remains the deterministic pre-publication
path.

Release order
-------------

#. Tag and publish the ``tula_cmake`` wheel and Python-require.
#. Build and upload Tula.
#. Build and upload kidscpp against packaged Tula.
#. Build and upload Citlali against packaged kidscpp.
#. Promote the verified graph and its lockfile from development to release.

Once these artifacts exist, a Citlali user clones only Citlali and runs
``./build``. Conan retrieves the internal and third-party graph from the
configured virtual remote.
