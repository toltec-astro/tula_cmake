Feature matrix testing
======================

The feature matrix is tested independently of example and production
projects. ``tula_boilerplate`` demonstrates minimal project-author UX; it is
not a matrix fixture.

Source-superbuild acceptance
----------------------------

``just vertical-slice`` validates the graph boundary end to end. In isolated
build trees it:

#. clones an exact boilerplate commit through a local Git catalog URL;
#. resolves ``tula_downstream → tula_boilerplate`` from the two manifests;
#. builds and runs the executable with the default Conan logging provider;
#. verifies that the virtual Conan recipe contains ``fmt`` and ``spdlog`` but
   never ``tula_boilerplate``;
#. verifies the catalog source lock contains the exact Git revision;
#. repeats with a direct local-project override and system logging;
#. verifies that the system case has no Conan requirements and records a local
   source in its lock.

The gate therefore catches graph inversion: an owned project accidentally
placed in Conan fails even if the C++ executable itself still compiles.

Test architecture
-----------------

The production registry and the test matrix metadata have separate jobs:

``data/registry.yaml``
   Defines the product contract: features, providers, Conan requirements,
   option domains, defaults, and CMake mappings.

``tests/feature_matrix/matrix.yaml``
   Defines only testing information: the probe for each feature, the provider
   used for each option axis, companion options needed for meaningful
   combinations, and environment capabilities.

``tests/feature_matrix/project``
   One static minimal Conan/CMake consumer. Pytest copies it into a temporary
   directory and writes only ``matrix_case.cmake`` and the selected
   ``probe.cpp``.

``tests/test_feature_matrix.py``
   Executes each derived case through the normal :class:`BuildWorkflow`, then
   checks the generated preset and runs CTest.

Coverage is closed by convention. Every registry provider automatically
becomes a case. Every feature-owned option must have an option axis, from which
one case is generated for every declared value. The fast catalog test rejects
missing axes, unknown modes, unknown values, and invalid companion options.

Case lifecycle
--------------

Each matrix item performs:

#. create an isolated project and output directory with Pytest ``tmp_path``;
#. select exactly one feature/provider while disabling unrelated features;
#. run Conan install, CMake configure, and CMake build through
   :class:`BuildWorkflow`;
#. inspect Conan's generated ``CMakePresets.json``;
#. verify the normalized ``tula::<feature>`` target contract;
#. compile the feature probe and run it with CTest.

No matrix-specific Conan profiles or custom result-reporting framework are
needed. Pytest node IDs, selection, capture, timing, skip reasons, and JUnit
output remain available through standard Pytest behavior.

Test tiers
----------

.. code-block:: console

   $ just matrix
   $ just matrix-all
   $ just gcc14
   $ just clang20
   $ just compilers
   $ uv run pytest -m feature_matrix -k logging
   $ uv run pytest -m "feature_matrix and network"

``matrix`` excludes Conan and CPM provider cases which may require downloads.
``matrix-all`` includes every provider. Cases needing external
system facilities declare capabilities and are visibly skipped until the
environment advertises them:

.. code-block:: console

   $ TULA_TEST_CAPABILITIES=oneapi \
       TULA_TEST_INTEL_PROFILE=/profiles/intel-debug \
       just matrix-all

   $ TULA_TEST_PROFILE=/profiles/clang-debug \
       TULA_TEST_CAPABILITIES=llvm-openmp \
       TULA_TEST_LLVM_PROFILE=/profiles/clang-debug \
       just matrix-all

The Ubuntu 24.04 dev container installs GCC 13, GCC 14, Clang 20, and the
LLVM 20 OpenMP runtime. It also installs ``clang-tools-20`` because CMake's
C++20 module-dependency scan invokes ``clang-scan-deps``. ``matrix`` and
``matrix-all`` retain GCC 13 as the baseline. ``gcc14`` and ``clang20`` each
run the complete applicable feature matrix and then create the installed
Tula → kidscpp → Citlali package chain.
``TULA_TEST_PROFILE`` selects the ordinary matrix profile; runtime-specific
cases additionally require their matching capability and profile variable.
The Clang profile deliberately selects ``libstdc++11`` to match Ubuntu's
system packages and the rest of the packaged graph.

The compiler gates exercise all logging levels; every
yaml-cpp and Eigen provider; the disabled and CPM csv-parser cases; every
NetCDF C and C++ provider; disabled and CPM bitmask and meta-enum cases; the
CPM clipp provider; disabled and CPM GrPPI cases; both Eigen
multithreading values; disabled and Conan Spectra, Boost, FFTW, CCfits, and
Ceres cases; disabled and system features; all OpenMP
policies; and the matching GNU or LLVM OpenMP runtime. oneAPI,
Intel OpenMP, and MKL threading cases remain first-class collected tests for
the corresponding validation images. Runtime cases assert
a matching compiler family rather than accepting the requested runtime label
alone.

Measured compiler results
-------------------------

The Ubuntu 24.04 ARM64 dev container produced these results on 26 July 2026:

.. list-table::
   :header-rows: 1
   :widths: 16 19 23 18 24

   * - Gate
     - Compiler
     - Applicable matrix
     - Runtime case
     - Installed chain
   * - ``just gcc14``
     - GNU 14.2.0
     - 55 passed, 6 capability-skipped
     - GNU OpenMP passed
     - 13 Tula, 5 kidscpp, 6 Citlali tests, and all consumers passed
   * - ``just clang20``
     - Clang 20.1.2
     - 55 passed, 6 capability-skipped
     - LLVM OpenMP passed
     - 13 Tula, 5 kidscpp, 6 Citlali tests, and all consumers passed

All 61 cases remain collected. The six deliberate skips correspond to
oneMKL/threading, Intel OpenMP, and the alternate compiler family's OpenMP
runtime.

macOS validation uses the checked-in ``macos-brew-llvm-debug`` profile. It
selects ``$(brew --prefix llvm@20)/bin/clang++`` with libc++, never native
AppleClang, and obtains OpenMP from Homebrew ``libomp``. Profile rendering
validates the detected major version and stops before graph resolution when
the keg or symlink is not LLVM 20. CMake 3.31.12 is pinned where a dependency
declares a CMake tool requirement. The profile also exports
``CMAKE_POLICY_VERSION_MINIMUM=3.5`` so a host CMake 4 installation cannot
break older CFITSIO sources when a third-party recipe bypasses that tool
requirement.

The current host has a stale ``llvm@20`` prefix resolving to Clang 21.1.4, and
the profile correctly rejects it. A measured macOS LLVM 20 package-chain result
therefore remains pending until that keg is repaired. The Linux baseline
independently passes the chain with GCC 13.3.0 from a clean Conan home.

The Tula package gate separately runs thirteen behavior executables. In addition
to core, Eigen, nddata, and ECSV coverage, these verify ``FlatConfig`` typed
and optional access, ``YamlConfig`` nested lookup/merge/validation, and
filename parsing, directory creation, and regex discovery. The NetCDF test
verifies type mapping, typed dispatch, scalar I/O, and formatting; the enum
test verifies metadata lookup, nested enums, flag concepts, decomposition,
and fmt rendering. The CLI test verifies builder-to-``FlatConfig`` projection
for flags, typed values, enum choices, defaults, and positional arguments.
The GrPPI test verifies that the normalized dynamic execution policy can run a
sequential map.

The final package-chain gate is ``just citlali``. It creates Tula, kidscpp,
and Citlali as installed Conan packages, compiles the five-source Citlali v4
library plus its reduction CLI, and runs six regressions covering Gaussian
behavior, CLI help/version/default configuration, and real-file adapter
equivalence. Public package edges opt in
to transitive headers and libraries, so Citlali receives ``tula::headers``
through ``kids::kids`` rather than from workspace include paths.

Tula, kidscpp, and Citlali each include a Conan ``test_package``. These small
consumers compile against the packaged CMake target after ``conan create``;
they catch missing installed headers, target metadata, and transitive public
requirements that source-tree tests cannot detect. In particular, this gate
verifies Tula's bundled CPM header closure, Kidscpp's installed raw-reader
symbol and NetCDF system include/link metadata, and Citlali's public Ceres
include path. The Citlali consumer also executes the packaged ``citlali --version``
and ``citlali --dump_config`` commands through ``VirtualRunEnv``.

If ``TOLTECA_TEST_DATA_ROOT`` points at the sibling ``tolteca_test_data``
checkout, Kidscpp additionally opens the 2024
``toltec0_018230_111_0000`` timestream. It asserts metadata, dimensions,
tone-model labels, exact first-sample I/Q/time values, slice metadata, and
invalid-stride rejection. Citlali uses the same fixture to compare its
file/slice adapter with a direct Kidscpp reader/solver call, including
metadata, axes, model inputs, solved arrays, and matching NaNs. The package
test remains hermetic. The workspace ``just kidscpp`` and ``just citlali``
acceptance gates require the fixture and fail early when it is unavailable,
so real-data coverage cannot silently skip there.
