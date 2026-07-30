# TulaCMake Spack architecture

These documents are the source of truth for the `v3.x_spack` design.

| Document | Purpose |
| --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Responsibilities, package boundaries, graphs, and code structure |
| [WORKFLOW.md](WORKFLOW.md) | Fresh-machine, user, developer, and release workflows |
| [TESTING.md](TESTING.md) | Unit fixtures, Spack matrix, evidence, and expansion rules |
| [DECISIONS.md](DECISIONS.md) | Accepted architectural decisions and their consequences |
| [MIGRATION.md](MIGRATION.md) | Baseline preservation and production-repository migration order |
| [tula-spack-system.html](tula-spack-system.html) | Technical review deck generated from the implemented system |

## Documentation policy

- Markdown records the complete design. The HTML deck summarizes it.
- Statements are marked implemented, measured, or planned.
- A package is marked implemented only after its installed package boundary
  has been exercised.
- `refs/` and `archive/` are evidence, never build inputs.
- When implementation changes, update the relevant Markdown documents and
  deck in the same commit.
