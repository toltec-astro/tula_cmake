Native Spack experiment
=======================

``examples/spack`` is an isolated experiment that asks whether native Spack
can replace the custom project/provider graph. It does not change the current
Conan/CPM implementation.

The experiment intentionally exposes Spack's own interface. There is no
additional CLI or manifest language:

.. code-block:: console

   $ spack -C config -e environments/default spec
   $ spack -C config -e environments/default concretize
   $ spack -C config -e environments/default install
   $ spack -C config -e environments/default find -lv
   $ environments/default/.spack-view/bin/tula_downstream

Graph
-----

.. code-block:: text

   tula-downstream
   ├── tula-boilerplate
   │   ├── tula-lib-a
   │   ├── tula-logging
   │   │   ├── fmt
   │   │   └── spdlog
   │   └── tula-perflibs
   └── tula-lib-b

``tula-logging`` is a Spack
`BundlePackage <https://spack.readthedocs.io/en/latest/build_systems/bundlepackage.html>`_.
It constrains a compatible fmt/spdlog pair but has no source or installed
CMake target of its own.

``tula-perflibs`` is instead an installable interface package. Its ``openmp``
variant maps to an ordinary CMake option, and its exported
``tula::perflibs`` target propagates Threads, optional compiler-native OpenMP,
C++23, and capability definitions.

Root-owned transitive configuration
-----------------------------------

The complete configuration remains in native
`Spack spec syntax <https://spack.readthedocs.io/en/latest/spec_syntax.html>`_:

.. code-block:: yaml

   specs:
     - >-
       tula-downstream@0.1.0
       ^tula-lib-a flavor=chocolate
       ^tula-lib-b flavor=safe
       ^tula-perflibs~openmp

``tula-lib-a`` is not a direct downstream dependency. The ``^`` constraint
selects a reachable transitive package, so the root can configure it without
boilerplate forwarding or copying its option model. ``tula-lib-b`` is a direct
dependency and uses the same syntax.

Source, binary, and system acquisition
--------------------------------------

The logical dependency graph is independent of materialization:

``external``
   An optional dev-container ``packages.yaml`` pins GCC 13 and selects the
   compatible Ubuntu CMake, GNU Make, fmt, and spdlog installations as
   non-buildable externals.

``build cache``
   Spack may install a binary matching the exact concrete spec.

``source``
   If no binary matches and building is allowed, Spack builds the same spec
   from source.

The local TolTEC sources use standard ``develop`` entries during this
experiment. Released recipes would instead use immutable Git revisions or
checksummed source archives.

Acceptance boundary
-------------------

The default and alternate environments independently changed libA, libB, and
OpenMP values in the installed executable:

.. list-table::
   :header-rows: 1

   * - Environment
     - GCC
     - Installed executable output
   * - ``default``
     - 13.3.0
     - ``libA=vanilla perflibs.openmp=enabled libB=fast``
   * - ``alternate``
     - 13.3.0
     - ``libA=chocolate perflibs.openmp=disabled libB=safe``

Every CMake edge consumed an installed package configuration. Spack reused the
same logging bundle while installing distinct concrete variants of libA,
libB, perflibs, boilerplate, and downstream.

This establishes the native graph model, not production readiness. The full
dependency matrix, released Git sources, binary-cache publication, macOS,
LLVM 20, oneAPI/MKL, and production project migrations remain later gates.
