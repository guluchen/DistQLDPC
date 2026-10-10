# DistQLDPC modifications to upstream code

This document lists changes made for the DistQLDPC project relative to
the embedded MaxCDCL MaxSAT engine (`src/solver/`, and `src/engine/`, which holds the
engine implementation restructured from MaxCDCL `Solver.cc`). Upstream MaxCDCL is
MIT-licensed (see `src/solver/LICENSE`).

**Modifier:** Yu-Fang Chen <yfc@iis.sinica.edu.tw> (2025–2026)  
**Purpose:** QLDPC / CSS code minimum-distance computation via MaxSAT

---

## Application layer (`src/core/`)

New code, not derived from MaxCDCL.

### `src/core/distqldpc.cc`

| Area | Description |
|------|-------------|
| QLDPC encoding | MaxSAT formulation for stabilizer distance (Hx/Hz/Gx/Gz matrices) |
| Fork + pipe | Child runs solver; parent enforces wall-clock timeout (`-cpu-lim`) via `SIGKILL` |
| Bounds sync | Parent reads `TRY` / `LB` / `UB` / `RESULT` lines from pipe |
| Progress output | Default mode prints `c trying d:`, `c d_lb:`, `c d_ub:`, `c d:`, `o` |
| Quiet / debug | Default `verb=0`; child stdout to `/dev/null`; `-v` / `-debug` for solver log |
| CLI flags | `-no-card`, `-card-sinz`, `-card-mto`, `-card-both-force`, `-cpu-lim`, `-q` |
| Interleaved CSS split (GH-73, PI-approved 2026-10-09, experimental) | Default MaxCDCL path computes d = min(dX, dZ) by a global bound search over the X-type and Z-type halves (doubling feasibility probes, tie-break probes, ordered capped optimisation); only global bounds are forwarded; `-joint` keeps the original encoding |
| Per-half symmetry breaking (GH-85, interaction GH-73 x GH-75, experimental) | Split path only: candidate qubit permutations (GH-75 family) are kept for a CSS half only if GF(2) row-space checks prove they preserve rs(Hpar) and rs([Hpar;Glog]) of that half (plain maps only, no XZ-dual maps); optimum-preserving orbit clauses over the half variables (unit clause for transitive groups, orbit chain otherwise) in every oracle instance of that half. `-no-symbreak` = GH-73 split; `-symbreak-report` prints per-half generators/orbits; `-joint`, dumps and RoundingSat unchanged. See `optimization/experiments/GH-85/`. |

---

## MaxCDCL engine patches (`src/solver/`, `src/engine/`)

These are modifications to upstream MIT code. Original copyright headers
in each file are unchanged (and copied verbatim into every file that received
moved code).

### Engine restructuring (GH-95, stage 1): `Solver.cc` -> `src/engine/`

The MaxCDCL implementation file `src/solver/Solver.cc` was restructured into
DistQLDPC engine modules. Code was moved verbatim as whole top-level definitions
(with their comments); no function was split and no heuristic, constant, data
structure, ordering or floating-point expression changed, so the search is
identical (Tier0: byte-identical `-v` traces vs 7eadd54; every function's machine
code unchanged, only placement inside `__text` differs). See
`optimization/experiments/GH-95/`.

| File | Contents |
|------|----------|
| `Engine.cc` | unity translation unit: upstream header and MaxCDCL version lineage, former `Solver.cc` prologue, `#include` of the modules below in a fixed order (the engine is still ONE translation unit, built as `build/Engine.o`) |
| `EngineInternal.h` | file-scope helpers shared by several modules (`reduceTIER2_lt`, `reduceDB_lt`, `lbdLimitForOriCls`, `splitClauseSize`, `limitOfNbClausesToSplit`) |
| `State.cc` | option table, `Solver` constructor/destructor |
| `Inprocessing.cc` | learnt-clause vivification (Maple_LCM / Maple_CM), failed literals, original-clause minimisation |
| `ClauseDB.cc` | variables, clause addition, watcher attach/detach/removal, relocation, garbage collection |
| `Propagation.cc` | trail, backtracking, `uncheckedEnqueue`, `propagate`, `lPropagate` |
| `Heuristics.cc` | `pickBranchLit`, order heaps, progress estimate, Luby sequence |
| `Analysis.cc` | hard-conflict analysis, learnt-clause minimisation, `analyzeFinal`, UIP helpers |
| `SoftConflict.cc` | soft and quasi-soft conflict analysis |
| `ClauseReduction.cc` | learnt-clause DB reduction, removal of satisfied clauses, `simplify`, clause splitting |
| `Hardening.cc` | bound-driven hardening |
| `Lookahead.cc` | lower-bound lookahead (LK propagation, lookback, inconsistent sets) |
| `Search.cc` | `search()` and `solve_()` |
| `Objective.cc` | bounds pipe, cost bounds, incumbent tracking/printing, `checkSolution` (DistQLDPC hooks) |
| `Preprocessing.cc` | soft-literal partition, conflicting soft literals, initial conflict detection |
| `Cardinality.cc` | dynamic auxiliary variables, Sinz and MTO cardinality encodings |
| `Export.cc` | DIMACS / WCNF / OPB writers |

The `Solver` class declaration stays in `src/solver/Solver.h` with unchanged
member order (only a module-map comment was added). The DistQLDPC patches below
now live in the module files named in each heading.

### `Solver.h` / former `Solver.cc` (now `src/engine/`)

#### Retired soft literals after preprocessing partition (GH58) — `src/engine/Preprocessing.cc`

After partition replaces a conflicting soft set with its existing aggregate
representative, remove inactive entries from both unit and non-unit soft-literal
lists. Previously only the unit list was compacted, allowing initial lookahead
to enqueue `lit_Undef` from a retired auxiliary member. Preserve the existing
representative clauses, derived-cost accounting and surviving order; rebuild
heaps when either list loses members. This is a downstream correctness repair,
not a change to MaxSAT costs or quantum-code distance semantics. See
`optimization/investigations/GH58/` for the original failure and validation.

#### Bounds pipe (search progress → parent process) — `src/engine/Objective.cc`

- `setBoundsPipe(int write_fd)` — attach write end of pipe
- `emitTryUpdate(uint64_t)` — write `TRY <n>\n` at start of each outer UB iteration
- `emitBoundsUpdate()` — write `LB <n>\n` / `UB <n>\n` on bound changes
- `getCostLB()` / `getCostUB()` — accessors for current bounds
- `hasCostLB()` / `hasCostUB()` — whether bounds are known
- Member: `bounds_pipe_w`

#### Best solution on timeout / interrupt — `src/engine/Objective.cc`

- `noteBestSolution(uint64_t unsatSoft)` — track improving incumbent
- `printBestSolution()` — print best MaxSAT assignment found so far
- `getLastOptimalCost()` — last proven optimal cost when search completes
- Members: `bestSolutionFound`, `bestSup`, `lastOptimalCost`

#### Cardinality encoding modes — `src/engine/Cardinality.cc`

- Enum `CardinalityEncMode`: `OFF`, `BOTH`, `SINZ`, `MTO`, `BOTH_FORCE`
- Member: `cardinalityEncMode` (default `BOTH`)
- `addCardinalityConstraints()` respects mode:
  - `OFF` — soft-conflict only, no Sinz/MTO CNF
  - `SINZ` / `MTO` — single encoding
  - `BOTH` — Sinz if active soft lits ≤ 100, always MTO
  - `BOTH_FORCE` — Sinz + MTO regardless of problem size

#### Solve loop hooks — `src/engine/Search.cc`

- Call `emitTryUpdate(UB)` when testing a new upper-bound candidate
- Call `emitBoundsUpdate()` after LB/UB updates
- Call `noteBestSolution()` when a better incumbent is found

#### Multi-instance search controls (GH-73)

- `initLB`, `strictUB`, `startAtCap`, `stopAtFirstSolution`: a known lower bound, a hard cap, starting
  at the cap, and feasibility-only runs, used by the interleaved CSS split
- `boundsLbCap`, `boundsUbCap`, `boundsHideLB`: emitted bounds are capped/suppressed to stay global
- Former function-local `static` heuristic state in `search()`, `lookahead()` and
  `addCardinalityConstraints()` is now per-instance (identical behaviour for a single instance)

---

## Files not modified for DistQLDPC integration

The following are included from upstream with headers intact but without
DistQLDPC-specific functional changes (as of this document):

- `SimpSolver.h`, `SimpSolver.cc`
- `SolverTypes.h`, `Dimacs.h`
- `mtl/*`, `utils/*`
- Legacy entry points: `Main.cc`, `glucose_Main.cc` (not built by root Makefile)

If you add further patches, extend this file and mention them in `NOTICE`.

---

## Contributing patches back to upstream

DistQLDPC-specific integration code (fork, QLDPC encoding, CLI) belongs
in `src/core/` under GPL.

Generic solver improvements that could benefit MaxCDCL users may be
offered to upstream under MIT, consistent with `src/solver/LICENSE`.
