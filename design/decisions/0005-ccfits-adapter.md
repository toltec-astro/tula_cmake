---
status: "accepted"
date: 2026-08-01
decision-makers: user [cpp 2026-08-01 00:06], [cpp 2026-08-01 02:33]
---

# One CCfits adapter includes CFITSIO

## Context and Problem Statement

Citlali uses the CCfits C++ API. CCfits needs the CFITSIO C library, and both
come from the same provider policy (system or Spack). The first adapter was
named after CFITSIO.

## Considered Options

* Two adapters, one per library
* One adapter named after CFITSIO (`tula_deps::cfitsio`)
* One adapter named after CCfits (`tula_deps::ccfits`)

## Decision Outcome

Chosen option: "One adapter named after CCfits". The user: "cfitsio and
ccfits goes together and they should become yet another meta package like
logging" [cpp 2026-08-01 00:06]; "cfitsio is a c lib and ccfits is a c++
lib. citlali actually uses ccfits api. we might call it ccfits rather than
cfitsio" [cpp 2026-08-01 02:33].

### Consequences

* Good, because Citlali links one target named after the API it calls.
* Good, because the provider matrix switches both libraries together.
