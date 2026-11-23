# TulaCMake agent guide

TulaCMake is the shared CMake package of the TolTEC C++ projects:
target-scoped CMake functions, dependency adapters for third-party
libraries, their Spack recipes, and the acceptance gates for the installed
package chain. Zhiyuan Ma <zhiyuanma@umass.edu> is the maintainer.

## Read first

1. `design/spec.md`: the contract. Its domains are the guides in `docs/`, in
   the same order.
2. `design/decisions/`: the decision records. Only records with
   `status: "accepted"` are binding.
3. `design/architecture.md`: the mechanisms that realize the contract.
4. `docs/`: the user guides.

## Ownership

- TulaCMake owns the CMake functions, the `tula_deps::` adapters and their
  recipes, the `netcdf-cxx4` recipe override, and the gate environments.
- Spack owns dependency resolution, variants, sources and the concrete
  graph. Tula owns the `tula::` components. Tula, Kidscpp, Citlali and Tlaloc
  each own their recipes and behavior tests.
- `tolteca_deploy` owns deployment locations, profiles, host library policy,
  release locks and the deployment identity. TulaCMake does not read its
  profiles, and it does not read TulaCMake's gate environments.

## Development

- `just unit`: configure, build and test the installed CMake fixture; also
  checks the Spack manifest includes. Needs CMake and Ninja only.
- The Spack gates (`just --list`) run in the development container with the
  sibling checkouts; `docs/acceptance-gates.md` lists them with the spec
  section each one verifies.
- Follow the `tolteca-coding-guideline` skill for names, terms and
  docstrings, and the `design-records` skill for `design/`. The skills are in
  [`tolteca_agent`](https://github.com/toltec-astro/tolteca_helpdesk/tree/main/src/tolteca_agent/data/skills).
  In the TolTECA development workspace, also follow its workspace rules. Do
  not copy their text here.
