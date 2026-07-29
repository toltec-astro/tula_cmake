# Architecture decisions

## D001 — `tula_cmake/design` is authoritative

Accepted 2026-07-29.

`tula_cmake` is now an independent repository, so its design record belongs
under `tula_cmake/design/`. User documentation remains under `docs/`.

## D002 — Conan is a provider, not the project graph

Accepted 2026-07-29.

The default development workflow must not require Tula, Kidscpp, or Citlali to
be materialized as Conan packages. Conan remains available for external
dependencies and explicit packaged-project consumption.

## D003 — Root-owned recursive manifests

Accepted 2026-07-29.

Every project declares direct dependencies in `tula-project.yaml`.
`tula_cmake` recursively loads those manifests and computes one graph. The root
owns overrides; transitive packages do not copy downstream option tables.

## D004 — Preserve one-command UX

Accepted 2026-07-29.

The checked-in `./build` launcher remains the only required user command. It
may print bootstrap, Conan, CMake, build, and test phases, but users do not
invoke those phases separately.

## D005 — Prove local CPM projects before remote acquisition

Accepted 2026-07-29.

The first slice uses a local source path with the `cpm` provider. This proves
graph semantics deterministically. Git URLs, tags, source caches, and local
override precedence will be added only after the basic contract passes.

## D006 — Keep packaging until replacement gates pass

Accepted 2026-07-29.

Existing Conan recipes and package tests remain during the redesign. Removal
or simplification happens only after the source-superbuild path covers the
real project chain.

## D007 — Catalog owned projects; do not Conan-export them

Accepted 2026-07-29.

`tula_cmake` publishes acquisition coordinates and expected CMake targets for
TolTEC-owned projects in a typed catalog. Each source repository owns its
direct dependency manifest. Catalog entries use immutable revisions, support
CPM-compatible local overrides, and are added only after their source-build
gate passes.

In this design, “exporting Tula through `tula_cmake`” means adding Tula to this
source-project catalog. It never means requiring `conan export`.

## D008 — Keep explicit Conan materialization behind the launcher

Accepted 2026-07-29.

The checked-in launcher retains one-command UX, but `tula_cmake` performs
Conan installation explicitly before the final configure. Conan's
configure-time CMake dependency provider is not the foundation because Conan
documents that path as exceptional and less stable than its generated
toolchain/preset workflow.

## D009 — Prepare Git sources before CMake, then compose with CPM

Accepted 2026-07-29.

Python checks out each catalog project at an exact commit before it recursively
loads manifests. CMake then receives those prepared paths through
`CPMAddPackage(SOURCE_DIR ...)`. This uses CPM's normal target/deduplication
semantics without delaying transitive feature discovery until configure time.

## D010 — Catalog metadata and dependency policy have different owners

Accepted 2026-07-29.

`projects.yaml` owns Git coordinates, immutable revision, version, source
subdirectory, and expected CMake target. Each project's `tula-project.yaml`
owns only direct project names and external feature defaults. The catalog does
not duplicate transitive policy.

## D011 — Example projects have no Conan recipes

Accepted 2026-07-29.

`tula_boilerplate` and `tula_downstream` demonstrate the ordinary
source-superbuild and therefore contain no alternate packaged workflow.
Installed-package validation remains in the production repositories.
