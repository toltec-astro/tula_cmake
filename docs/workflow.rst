Build workflow
==============

The downstream entry point is:

.. code-block:: console

   $ ./build

The checked-in launcher runs the equivalent pinned command:

.. code-block:: console

   $ uvx \
       --from git+https://github.com/toltec-astro/tula_cmake.git@v3.1.0 \
       tula-cmake build .

During joint development, ``TULA_CMAKE_DEV_PROJECT`` selects a local
``tula_cmake`` checkout instead. ``TULA_CMAKE_SOURCE`` can override the
release source without editing the launcher.

Reproducible feature choices are supplied through Conan profiles. Repeatable
``--option NAME=VALUE`` arguments are available as higher-priority,
root-package overrides for experiments:

.. code-block:: console

   $ tula-cmake build . \
       --profile profiles/linux-gcc13-debug \
       --option perflibs=system \
       --option perflibs_openmp=auto

The command performs three visible phases:

``bootstrap``
   Optionally installs shared Conan configuration and ensures a default profile
   exists when the caller did not supply profiles.

The ``--config-source`` option can also be supplied through
``TULA_CONAN_CONFIG_SOURCE``. This is the future zero-configuration handoff
from the GitHub-hosted CLI to the TolTEC Conan remote definition.

``conan``
   Resolves the dependency graph and generates a toolchain, dependency files,
   feature manifest, and CMake presets. Enabled-feature options are materialized
   as generated preset cache variables.

``cmake``
   Reads the generated preset document through typed models, then configures
   and builds with that preset.

Projects consume the Conan recipe behavior with:

.. code-block:: python

   python_requires = "tula-cmake/3.1.0"
   python_requires_extend = "tula-cmake.TulaConan"

A production recipe may define its normal feature set without redeclaring
registry options:

.. code-block:: python

   tula_default_options = {
       "logging": "conan",
       "perflibs": "system",
       "eigen": "conan",
   }

The mixin validates every key against the registry. Profiles and explicit
root-package options can still override these defaults.

Public package chains
---------------------

Conan 2 package types do not imply that headers and static libraries should
cross every dependency edge. A library whose public headers or link interface
exposes a requirement declares that intent explicitly:

.. code-block:: python

   self.requires(
       "tula/3.1.0",
       transitive_headers=True,
       transitive_libs=True,
   )

The production chain uses this rule from Tula through kidscpp to Citlali.
Provider selection remains local to each recipe; visibility of an installed
package is ordinary Conan graph metadata.

The boilerplate and downstream example live in this repository. Tula,
kidscpp, and Citlali are intentionally not CPM entries: keeping them as Conan
requirements preserves package identity, binary reuse, graph conflicts, and
lockfile visibility.
