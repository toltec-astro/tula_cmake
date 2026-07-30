# Migration

## 1. Preserved baseline

| Repository | Baseline branch | Archived commit | Active branch |
| --- | --- | --- | --- |
| TulaCMake | `v3.x_conan2` | `0745f99` | `v3.x_spack` |
| Tula | `v3.x` | `08ae265` | `v3.x_spack` |
| Kidscpp | `v3.x` | `2ae77e9` | `v3.x_spack` |
| Citlali | `v4.x_conan2` | `bfb9378` | `v3.x_spack` |

Self-contained clones are stored in
`archive/v3-conan2-baseline-2026-07-30`.

## 2. Completed in TulaCMake

- CMake-only installable package.
- Python and Conan infrastructure removed.
- Public target-scoped utility modules implemented.
- Installed producer/consumer fixture passing.
- Logging bundle represented in Spack.
- Perflibs OpenMP variant represented in Spack.
- Boilerplate/downstream installed vertical slice passing.
- Direct and transitive variant matrix passing on GCC 13.
- Dev-container bootstrap changed to pinned Spack.
- Native Just validation surface established.

## 3. Production migration order

### Phase A — Tula

1. Create Tula-owned Spack repository and recipe.
2. Model current header capabilities as variants.
3. Add recipes for upstream header projects missing from the builtin index.
4. Replace resolver-generated aliases with explicit `find_package()` targets.
5. Retain `tula::headers` and behavior-compatible generated capability macros.
6. Run all existing Tula behavior tests and an installed consumer.

### Phase B — Kidscpp

1. Create Kidscpp-owned recipe.
2. Depend on Tula through Spack.
3. Keep raw TolTEC NetCDF ingestion in Kidscpp.
4. Preserve solver and metadata behavior.
5. Run synthetic solver tests and required real-data reader tests.
6. Validate installed `kids::kids`.

### Phase C — Citlali

1. Create Citlali-owned recipe.
2. Depend on Kidscpp and Citlali-specific packages.
3. Keep the Citlali CLI and RTC behavior unchanged.
4. Map OpenMP and numerical-library requirements to recipe variants.
5. Run library, CLI, installed-consumer, and real-data integration tests.

### Phase D — supported environments

1. GCC 13 development baseline.
2. GCC 14.
3. LLVM 20 on Linux.
4. Homebrew LLVM 20 on macOS.
5. Optional oneAPI/MKL environment after a suitable platform is available.

## 4. Removal rule

Conan-specific files are removed from a production repository only when the
corresponding Spack recipe and installed-package tests pass. Creating the
`v3.x_spack` branch does not by itself claim that the production package has
been migrated.
