# GH-76 preregistration: persistent per-half solver with resumable capped probes

Owner/session `mac-incremental-20261009` (Mac-host independent agent). Issue #76, hub #15.
Source baseline: corrected `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (#62). Hypothesis IDs GH-76-A/B/C
(full text in #76). Formulation: CSS split d = min(dX, dZ), PI-approved 2026-10-09 (recorded in #71).

## Relation to earlier work
GH-73 (#73/#74, not adopted) computes d with an interleaved global bound search over the two CSS halves,
answering every probe with a fresh `SimpSolver`. Its design log reports that refutations from scratch cost
several times more than the same refutation reached by descending inside one MaxCDCL run. This experiment
re-implements GH-73's split driver (copied with credit: build_css_half, the phase structure of
min_distance_css_interleaved, per-instance former statics, emitted-bound caps, stop-at-first in `search()`)
and changes only how probes are executed. Being a fresh branch on 72d1fe1, the candidate delta against the
baseline is "CSS split + interleaved schedule + persistent probes"; the conceptual delta against GH-73 is the
persistent probe execution only.

## Hypothesis (GH-76-A, selected)
Keeping one solver per half across all probes, restricted to MaxCDCL's own sound bound transitions, removes
repeated preprocessing/initialisation and lets later probes of a half (tie-break, capped optimisation,
refutation) reuse clauses learnt by earlier ones, reducing total solve time of the split.

## Engine soundness argument (code references at 72d1fe1, src/solver/Solver.cc)
* `solve_()` loop, fail branch (`UB=... fails`): `cancelUntilBeginning(beginning)`, `removeLearntClauses()`
  (all learnt tiers, `hardens`, `cardinalityC`, `isetClauses`, dynVars) before raising UB. This is the only
  way UB rises; we use exactly this reset before any raise.
* `search()` on a new solution: `UB = falseLits.size(); cancelUntil(0)`; continuing with all clauses kept.
  External tightening between probes is done at level 0 the same way; `search()` then replaces
  `cardinalityC`/`hardens` (`prevUB > UB`).
* `reduceClause`/`simplereduceClause` shorten original clauses when `feasible`: after the first solution of
  an instance, UB must never rise above the UB in force since then. `incProbe` refuses such a raise; the
  driver then rebuilds that half's solver from scratch with its proven LB (guard; not expected under the
  GH-73 schedule, whose caps only fall after a half's first FOUND, and whose refutations after FOUND finish
  the half).
* Units, `fixedCostBySearch`, `beginning` are not re-based after a FOUND (unlike the l_True branch of
  `solve_()`), so cost accounting stays `offset + falseLits.size()` throughout.
* The 14 function-local `static` heuristic variables in `search()`/`lookahead()`/`addCardinalityConstraints()`
  become per-instance members (two solvers alive at once).

## Intended change
* Engine: `Solver::incPrepare()` (the `solve_()` prologue, run once), `Solver::incProbe(capTotal, firstOnly,
  knownLB)` (one bounded test from the current state, returning FOUND/OPT/NONE/needs-rebuild/interrupted),
  `stopAtFirstSolution` in `search()`, emitted-bound caps. `solve_()` itself is unchanged, so `-joint`
  (original joint encoding) must stay byte-identical.
* Driver: GH-73's schedule (phase-1 doubling feasibility probes on both halves with anytime global LB,
  tie-break probes while incumbents are equal, ordered capped optimisation) with persistent solvers.
  Every reported half weight is additionally checked against the witness model (parity checks and
  nontrivial logical test, weight equal to the reported cost); a mismatch yields UNKNOWN, never a value.
* `-joint` selects the original encoding.

## Expected effect / risk
Faster tie-break and second-half refutations (largest on cases with several post-FOUND probes); no effect on
phase-1 learning (cleared on every raise by design). Correctness risk: state carried across probes; mitigated by
engine-native transitions only, the rebuild guard and the witness check.

## Validation (Tier0, this agent; no timing comparisons)
build + `scripts/smoke_test.sh`; mandatory `scripts/test_partition_soft_literals.py` (fixture
`tests/fixtures/partition-retired-soft.wcnf`, optimum 5) and `tests/test_partition_soft_literals.cc`;
`-joint -v` traces byte-identical to a fresh 72d1fe1 build on the Tier1 cases (all four modes);
GH-60 `tier0_science.py --jobs 1` (copied unchanged from experiment/gh-60-mac-lkprefix) at 60 s for candidate
and baseline: distances equal named distances and baseline values, all emitted bounds sound;
distance agreement with GH-73's frozen binary (correctness only); QDistSAT cross-repo check on
`ci/xrepo-gh76` (candidate tree, parent 72d1fe1). Tier1/Tier2 are run by the coordinator.
