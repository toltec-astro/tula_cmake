# TulaDownstream

TulaDownstream is the minimal executable consuming the installed
TulaBoilerplate package.

```text
tula-downstream
├── tula-boilerplate
│   ├── tula-lib-a
│   ├── tula-logging
│   └── tula-perflibs
└── tula-lib-b
```

The downstream recipe declares only its direct dependency edges. A root Spack
spec can still constrain libA and perflibs through the complete reachable
graph. TulaBoilerplate does not forward or duplicate those options.

The downstream executable prints all three observable selections:

```text
tula_downstream libA=vanilla perflibs.openmp=enabled libB=fast
```

Run both supported fixture graphs:

```console
cd ../..
just spack-matrix
```
