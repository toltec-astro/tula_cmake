# Tula superbuild design

This directory is the authoritative design record for `tula_cmake`.

The Sphinx pages under `docs/` explain the released implementation to users.
Files here record architectural intent, decisions, boundaries, acceptance
criteria, and the staged implementation plan. When implementation and design
disagree, the discrepancy is a defect to resolve rather than an undocumented
compatibility behavior.

## Current documents

- [ARCHITECTURE.md](ARCHITECTURE.md) defines the recursive source-superbuild
  architecture and its package/provider boundaries.
- [VERTICAL_SLICE.md](VERTICAL_SLICE.md) defines the first executable
  acceptance slice using `tula_boilerplate` and `tula_downstream`.
- [DECISIONS.md](DECISIONS.md) records the decisions that must remain stable
  while the slice is implemented.
- [RESEARCH.md](RESEARCH.md) records the upstream mechanisms and terminology
  used for owned source projects.

The historical design deck remains in the separate `tula/design/` directory
until the architecture is proven and the deck can be rewritten from validated
results. It is not the authority for this redesign.
