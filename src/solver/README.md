MaxSAT engine (MaxCDCL / `SimpSolver`, `Solver`).

The `Solver` implementation (formerly `Solver.cc`) lives in `src/engine/` as DistQLDPC
engine modules compiled as one unity translation unit (`src/engine/Engine.cc`); the class
declaration stays in `Solver.h` here.

Built as a static library together with `src/core/distqldpc.cc`. Not installed as a standalone CLI.

Legacy glucose entry points (not built by root `Makefile`):

- `glucose_Main.cc` — former `sources/simp/Main.cc`
- `Main.cc` — former `sources/core/Main.cc`
