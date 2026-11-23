---
status: "accepted"
date: 2026-11-23
decision-makers: user [cpp 2026-07-30 08:11], [claude 2026-11-23]
---

# Markdown documentation, no Sphinx

## Context and Problem Statement

The Conan-era TulaCMake documented its Python API with Sphinx. After the move
to Spack (0001) TulaCMake has no Python package, so the Sphinx API reference
has nothing to document.

## Considered Options

* Sphinx, as the Python repositories use
* Another generator for HTML documentation
* Markdown files in the repository

## Decision Outcome

Chosen option: "Markdown files in the repository". The user: "there is no
python package, sphinx docs is not suitable? … maybe just a long proper readme
file is enough. (this also makes it llms frirendly)" [cpp 2026-07-30 08:11].
The guides are one Markdown file per specification domain in `docs/`, with a
short README [claude 2026-11-23].

### Consequences

* Good, because the guides render on GitHub and agents read them directly.
* Bad, because no build checks links or runs the examples; review does.
