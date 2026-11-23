---
status: "accepted"
date: 2026-07-30
decision-makers: user [cpp 2026-07-30 09:29], [cpp 2026-07-28 14:51]
---

# Two compiler lanes: GCC 14 and LLVM 20

## Context and Problem Statement

The matrix tested GCC 13 and GCC 14, and macOS builds ran with the native
AppleClang. Every lane multiplies the gate time.

## Considered Options

* GCC 13, GCC 14 and LLVM 20
* GCC 14 and LLVM 20, with AppleClang as the macOS compiler
* GCC 14 and LLVM 20; on macOS, Homebrew LLVM 20

## Decision Outcome

Chosen option: "GCC 14 and LLVM 20; on macOS, Homebrew LLVM 20". The user:
"have gcc14 for gcc, and llvm20 for llvm. remove gcc13 as it is duplicated
with gcc14" [cpp 2026-07-30 09:29]; "it should not run against native
appleclang! it should run again brew llvm!" [cpp 2026-07-28 14:51].

### Consequences

* Good, because each compiler family has one lane, and macOS uses the same
  LLVM major as Linux.
* Bad, because macOS needs Homebrew LLVM 20 and a Spack-built OpenMP runtime
  (the keg has none).
