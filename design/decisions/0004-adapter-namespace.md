---
status: "accepted"
date: 2026-07-31
decision-makers: user [cpp 2026-07-31 02:14], [cpp 2026-07-31 02:16]
---

# Adapters use `tula_deps::` and the library's name

## Context and Problem Statement

The first adapters exported targets such as `tula::yaml` for yaml-cpp. That
name suggests a Tula API, but the adapter only normalizes discovery of one
library.

## Considered Options

* `tula::<concept>` for adapters (`tula::yaml`)
* `tula_cmake::<library>`
* `tula_deps::<library>` (`tula_deps::yaml_cpp`), with `tula::` kept for Tula
  components

## Decision Outcome

Chosen option: "`tula_deps::<library>`". The user: "normalized targets retain
the namings that are more close to the underlying deps. yaml_cpp is better
than yaml because at this level we don't provide any code to actually adapt
the difference between different yaml lib. tula::yaml sounds like a high
level lib" [cpp 2026-07-31 02:14]; "tula:: can be higher level … or
tula_deps?" [cpp 2026-07-31 02:16].

### Consequences

* Good, because a target name shows whether a consumer links a library or a
  Tula API.
* Bad, because changing the names removed the old targets with no aliases;
  all consumers moved at once.
