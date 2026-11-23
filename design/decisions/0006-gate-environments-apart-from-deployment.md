---
status: "accepted"
date: 2026-11-22
decision-makers: user [cpp 2026-08-06 00:42], [cpp 2026-08-06 00:45], [claude 2026-11-21], [claude 2026-11-22]
---

# Gate environments stay apart from deployment profiles

## Context and Problem Statement

TulaCMake has Spack environments for its gates, and `tolteca_deploy` has
Spack profiles for deployment locations. The user asked: "there is
environments and packages in tula_cmake, and there is the tolteca_deploy spack
stuff. what are their roles?" [cpp 2026-08-06 00:42]. A later gate compared
TulaCMake's environments with the deployment profiles, and TulaCMake also had
a Tlaloc gate.

## Considered Options

* TulaCMake environments are also deployment inputs
* Separate sets, with a TulaCMake gate that checks them against the deployment
  profiles
* Separate sets; each repository tests its own

## Decision Outcome

Chosen option: "Separate sets; each repository tests its own". The user
approved the separation [cpp 2026-08-06 00:45], the removal of the
consistency gate ("Yes, fix them" [claude 2026-11-21]), and the removal of
the Tlaloc gate ("Yes, as recommended", P3 [claude 2026-11-22]).

### Consequences

* Good, because gate environments can use sibling checkouts and test-only
  composition without affecting deployments.
* Good, because a change in one repository's environments does not break the
  other repository's tests.
* Bad, because the same graph is described twice, and nothing checks that
  the two agree.
