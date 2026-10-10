# GH-95 PROPOSAL — engine refactor stage 1: MaxCDCL engine restructured into DistQLDPC modules (search-identical)

Issue: https://github.com/guluchen/DistQLDPC/issues/95 (hub #15).
Agent/session: Mac engineering agent, 2026-10-10 (Tier0 correctness only, no timing).
Baseline: main `7eadd54` (CSS split + per-half symmetry breaking default).
Branch: `refactor/gh-95-engine-modules` (from 7eadd54).
Written before any implementation.

## Goal

The PI goal is an engine that is DistQLDPC's own and clearly differentiated from stock
MaxCDCL. Stage 1 is the foundation only: the 7.2k-line `src/solver/Solver.cc` is split into
DistQLDPC-owned modules under `src/engine/`, with module boundaries chosen so that the
planned later stages (native GF(2)/XOR propagation, symmetry-aware learning,
domain-specific bounding) each have an obvious home. **No search change of any kind.**

## Hard rules for this stage

1. Code is moved verbatim (whole top-level definitions, with their comments). No function
   is split, no heuristic, constant, data-structure, ordering or floating-point expression
   is touched. The `Solver` class declaration (`src/solver/Solver.h`) keeps its exact member
   order (object layout unchanged); only comments are added there.
2. Codegen-preserving build: `src/engine/Engine.cc` is a unity translation unit that holds
   the former `Solver.cc` prologue (includes, `using namespace`, DRUP statics) and then
   `#include`s the module files in a fixed order. The modules are never compiled alone (each
   has an `#error` guard). Compiler and flags are unchanged; only the object name changes
   (`build/Solver.o` -> `build/Engine.o`). `SimpSolver.cc`, `Options.cc`, `System.cc`
   stay separate translation units exactly as before, so cross-TU inlining is unchanged.
3. Module order inside the unity TU follows the first appearance of each module's code in
   the original `Solver.cc`, and inside each module the original relative order is kept.
   This keeps the emitted function order as close to 7eadd54 as a logical grouping allows.
   Every function's machine code is expected to be unchanged; only the placement of some
   functions inside `__text` moves. Evidence: `__text` size and a per-function
   disassembly comparison (address operands normalised) vs 7eadd54.
4. File-scope helpers shared by several modules (the clause-ordering comparators
   `reduceTIER2_lt`, `reduceDB_lt` and the macros `lbdLimitForOriCls`, `splitClauseSize`,
   `limitOfNbClausesToSplit`) move to `src/engine/EngineInternal.h`, included once by the
   unity file before the modules. Helpers used by a single module stay in that module.
5. Licensing: every file holding code moved from `Solver.cc` carries the full upstream
   header block of `Solver.cc` (MiniSat, Chanseok Oh, Maple_LCM, Maple_CM, Chu-Min Li 2021)
   with its MIT permission notice verbatim, followed by a DistQLDPC modification notice
   (Copyright (C) 2025-2026 Yu-Fang Chen, part of DistQLDPC, GPL-3.0-or-later when
   distributed as this project). The MaxCDCL version-lineage comments ("Based on ...")
   stay at the top of `Engine.cc`. `src/solver/LICENSE` is kept; NOTICE sections 2/3 and
   MODIFICATIONS.md describe the new layout and say it was restructured from MaxCDCL.

## Target module layout (`src/engine/`, unity order)

| # | File | Contents (all `Solver::` members unless noted) | Future stage hook |
|---|------|-----------------------------------------------|-------------------|
| 0 | `Engine.cc` | unity TU: upstream header + lineage, includes, DRUP statics, `#include` list | build entry point |
| - | `EngineInternal.h` | shared comparators and macros (see rule 4) | shared internals |
| 1 | `State.cc` | option table (`opt_*`), constructor, destructor | new parameters |
| 2 | `Inprocessing.cc` | learnt-clause vivification (Maple_LCM/Maple_CM: `simplePropagate`, `simpleAnalyze*`, `simplifyLearnt*`, `simplifyAll`), failed literals, original-clause minimisation | GF(2)-aware inprocessing |
| 3 | `ClauseDB.cc` | `newVar`, `addClause_`, attach/detach/remove, `satisfied`, `relocAll`, `garbageCollect` | XOR constraint store |
| 4 | `Propagation.cc` | `cancelUntil`, `cancelUntilBeginning`, `uncheckedEnqueue`, `propagate`, `lPropagate` | native GF(2)/XOR propagator hooked into propagate |
| 5 | `Heuristics.cc` | `pickBranchLit`, `rebuildOrderHeap`, `progressEstimate`, `luby` (static), `avgAct` | decision/restart policies |
| 6 | `Analysis.cc` | `analyze`, `binResMinimize`, `litRedundant`, `analyzeFinal`, on-the-fly `reduceClause`, `updateClauseUse`, `redundantLit`, `getAllUIP`, `collectFirstUIP` | XOR-reason explanation, symmetry-aware learning |
| 7 | `SoftConflict.cc` | MaxSAT soft-conflict analysis: `analyzeSoftConflict`, `simplifyConflictClause`, quasi-conflict analysis | domain-specific bound explanations |
| 8 | `ClauseReduction.cc` | `reduceDB`, `reduceDB_Tier2`, `reduceDB_core`, removal of satisfied clauses, `simplify`, clause splitting, `removeLearntClauses` | learnt-DB policy |
| 9 | `Hardening.cc` | `harden`, `reduceHardens`, `moreHarden`, `hardenForRestart`, `hardenFromQuasiSoftConflict` | bound-driven fixing |
| 10 | `Lookahead.cc` | lower-bound lookahead (LK propagation, lookback, inconsistent-set bookkeeping, auxiliary-variable heap), `lookahead`, `lookaheadForRestart`, `fixByLookahead` | separable LB component, domain-specific bounding |
| 11 | `Search.cc` | `search`, `solve_` (CDCL+BnB loop, UB/LB iteration, multi-instance controls) | search driver |
| 12 | `Objective.cc` | DistQLDPC hooks: bounds pipe (`TRY/LB/UB`), `getCostLB/UB`, incumbent tracking/printing, `checkSolution` | objective/bound management |
| 13 | `Preprocessing.cc` | soft-literal preprocessing: conflicting soft literals, `partition`, initial disjoint inconsistent sets (`detectInitConflicts` + its simple LK helpers), `addHardClausesForSoftClauses` | partition/symmetry preprocessing |
| 14 | `Cardinality.cc` | dynamic auxiliary variables, Sinz and MTO cardinality encodings | encodings |
| 15 | `Export.cc` | `toDimacs`, `toWcnf`, `toOpb`, `mapVar` (static) | dumps |

`src/solver/` keeps the upstream headers (`Solver.h`, `SolverTypes.h`, `SimpSolver.*`,
`Dimacs.h`, `Main.cc`, `mtl/`, `utils/`, `LICENSE`); `Solver.cc` disappears (moved).
Splitting the `Solver` class declaration itself is deferred: changing member order would
change object layout and codegen, which stage 1 forbids.

## Deliberately not done in stage 1

- No splitting of giant functions (`search`, `solve_`, `lookahead`, `partition`, ...):
  extracting a helper is a codegen change (inlining decision), so it waits for a stage
  that is allowed to move performance.
- No hook calls / virtual interfaces for future propagators (would add code to the hot path).
- No renaming of the `Minisat::Solver` class or its members (public API used by
  `src/core/distqldpc.cc`, `SimpSolver`, `Main.cc`, tests).

## Commit plan (each commit builds and passes a quick trace check)

1. This proposal.
2. Scaffold: `git mv src/solver/Solver.cc src/engine/Engine.cc`, `EngineInternal.h`, Makefile
   and CI object name.
3. One commit per module extraction (Export, Objective, Cardinality, Preprocessing, Hardening,
   Lookahead, SoftConflict, Analysis, Heuristics, Search, Propagation, ClauseReduction,
   ClauseDB, Inprocessing, State); after the last one `Engine.cc` is prologue + include list.
4. Docs: NOTICE, MODIFICATIONS.md, README, `Solver.h` module-map comment.
5. Tier0 record.

Quick trace check per commit: build, then byte-compare the normalised `-v` traces of a fixed
small set (LP_34_20_2, LP_136_32_4, BB_72_12_6, TN_36_8_4, GB_144_12_8, PK_31) in default and
`-no-card` modes, plus `-joint -no-card` on LP_136_32_4, against 7eadd54.

## Tier0 gate

- smoke; `python3 -B scripts/test_partition_soft_literals.py`;
  `tests/test_partition_soft_literals.cc` oracle (`GH58_PARTITION_ORACLE_PASS cases=80`).
- Byte-identical `-v` traces vs 7eadd54 on all 50 bundled codes x {default, -no-card,
  -card-sinz, -card-mto} with `-cpu-lim=20`, plus `-joint -v -no-card` on the 50 codes.
  Comparison rule (fixed before running): the only timing-dependent token in `-v` output is
  `detect_cpu=<x>s` (normalised). Runs completed by both binaries must be byte-identical
  (stdout+stderr) with equal exit status. For runs that hit the limit, the child-search
  portion (everything before the parent's final summary block) of the 7eadd54 run, minus its
  last (possibly truncated, buffered) line, must be a prefix of the candidate's; the parent
  summary header lines must match; the bound lines printed after `c status: TIMEOUT` are not
  compared (they only reflect how far each child got before the kill). If the candidate got
  less far under the same limit, that case is rerun with `-cpu-lim=30` for the candidate.
- maxcdcl: identical output (and `optimal:` statistic) vs 7eadd54's maxcdcl on the bundled
  `clq-*` instances and a few `distqldpc -dump-wcnf` dumps.
- Cross-repo QDistSAT workflow on a one-commit branch `ci/xrepo-gh95` (parent 7eadd54).
- `__text` size of `bin/distqldpc` vs 7eadd54, plus per-function code comparison.
- Freeze the final Mac binary at `frozen95/cand/distqldpc`.

Tier1 timing is run by the coordinator, not by this agent.
