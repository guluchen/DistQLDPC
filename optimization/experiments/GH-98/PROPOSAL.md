# GH-98 PROPOSAL: native XOR constraints in the MaxCDCL engine (S1)

Issue: https://github.com/guluchen/DistQLDPC/issues/98 (hub #15).
Agent/session: Mac engine-optimization agent, 2026-10-10. Scope: implementation, Tier0 correctness and
informational work counts. Tier1+ wall-time comparisons are run by the coordinator.
Base: GH-95 restructured engine (`ae95b17`, search-identical to main `7eadd54`) plus the GH-98 profile evidence
commit `3ecd4c0`. Branch: `experiment/gh-98-native-xor`.
Written before any engine code was changed.

## Evidence and target

- GH-98 PROFILE.md (main 7eadd54): lookahead takes 82-85% of runtime on Tier3-size cases; `propagateForLK` alone
  63-74%.
- GH-99 (rejected): skipping base-satisfied watchers cut watcher visits (to 17% on GB_144) but not time. Lesson:
  the cost is in **clause inspections** (random loads of clause memory), not in watcher visits.
- In the main-profile instrumentation, original XOR clauses are 61-77% of inspected clauses in `propagateForLK`:
  GB_144_12_12 learnt 0.31e9 / size-3 0.19e9 / size-4 0.28e9; LP_544_80_12 0.14e9 / 0.19e9 / 0.29e9. Size 3 are
  surviving xor2 Tseitin gates (4 clauses each), size 4 are 3-input XORs that SatELite (`S.eliminate(true)` in
  `build_css_half`) makes by eliminating xor2 auxiliaries (8 clauses each).

Target: replace the inspections of these clauses by one compact XOR record per parity constraint, with a 2-watched
**variable** scheme. For a 4-variable XOR, an assignment of one of its variables triggers on average 2 clause
watchers in the CNF form (each of the 8 clauses watches 2 of its 4 literals; a literal occurs in 4 of them), and
each such visit whose blocker is not true reads a different clause. In native form the same assignment triggers
the XOR only if the variable is one of the 2 watched ones (probability 1/2), and then reads one small contiguous
record.

## Design

### D1. Where XORs come from: engine-side detection at solve start
- Detection runs inside `Solver::solve_()` after `simplifyOriginalClauses()` (original-clause vivification) and
  before `findConflictSoftLits()`. By then SatELite elimination, `addHardClausesForSoftClauses()` and the
  vivification of original clauses are done, so detection sees exactly the clause set the search uses. All later
  propagation, including the preprocessing passes `findConflictSoftLits` (simplePropagate) and
  `detectInitConflicts` (simplepropagateForLK), uses the XOR propagator.
- No encoder change. The engine handles whatever elimination produced, and `maxcdcl` gets the same detection on
  arbitrary WCNF input.

### D2. Detection algorithm
- Candidates: clauses in `clauses` (original, non-learnt) with size `3 <= k <= xorMaxK` (default 6, option),
  pairwise distinct variables, and no literal assigned at detection time (level 0).
- A clause over variables `u_1..u_k` excludes exactly one assignment: `u_i = sign(lit_i)`. Its excluded parity is
  `q = XOR_i sign(lit_i)`.
- Records `(k, sorted vars, q, pattern, cref)` are sorted and grouped by `(k, vars, q)`. The pattern index is the
  excluded values of the canonical (sorted) variables `cv_0..cv_{k-2}` as bits (the last value is fixed by `q`).
  A group whose distinct patterns cover all `2^(k-1)` indices is the full CNF expansion of
  `XOR(cv) = 1 - q`, and is registered as one XOR with parity `b = 1 - q`.
- Duplicates (two clauses with the same pattern): the first one is used; the others stay normal watched clauses.
- If both parities of a variable set are complete, both XORs are registered; propagation then derives the conflict
  as the CNF would.
- Only full groups are taken. Partial groups (some clauses strengthened or missing) stay as clauses.

### D3. Clause-DB integration: XOR clauses stay real clauses
- Each XOR clause gets a header flag `xorc` (one bit taken from `lbd`, which goes from 24 to 23 bits; the header
  size and layout of all other fields are unchanged). `ClauseAllocator::reloc` copies the flag.
- XOR clauses **stay in `clauses`** (so `checkSolution`, the WCNF/DIMACS writers, `relocAll` and statistics still see
  the complete formula) but are **removed from the watch lists** (one filtering sweep over `watches` at detection).
  `clauses_literals` is not changed, so `simpDB_props` and the `-v` statistics keep their meaning.
- `relocAll`: after the `clauses` loop, every pattern CRef of every XOR is remapped (`ca.reloc` returns the
  forwarding address of the already relocated clause).
- `removeSatisfied(clauses)` (top-level `simplify`): XOR clauses are kept (they are unwatched, so a satisfied one
  costs nothing, and the XOR stays valid with fixed variables).
- `reduceClause` / `simplereduceClause` (on-the-fly strengthening of a reason clause during analysis): no-op for an
  XOR clause. It is a pure optimisation; applying it would detach an unwatched clause and break the pattern table.
- `reduceDB*` never touches originals; `simplifyOriginalClauses` runs only before detection; `splitClauses` /
  `identifyClausesToSplit` only see learnt lists; hardening, cardinality and iset clauses are new clauses.
- Dynamic variables (cardinality, splitting, hardening auxiliaries) are created after detection and are never in an
  XOR. The XOR watch lists are grown in `newVar` and in `newAuxiVar`; recycled dynamic variables have empty lists
  (asserted in the self-check build).
- **Solve-local state.** On every exit path of `solve_()` the XOR clauses are re-attached (literals reordered: true
  first, then unassigned, then false, which is a valid watch state at level 0 after a propagation fixpoint) and the
  XOR store is freed. Between two `solve_` calls the solver is in the clause-only state, so SimpSolver, `addClause`
  and a later detection see ordinary clauses.

### D4. XOR store
- One flat `vec<uint32_t>` arena. Record at offset `o`:
  `[o] = k | (parity << 8)`, `[o+1 .. o+k]` = watch-order variables `w_0..w_{k-1}` (`w_0`, `w_1` watched),
  `[o+1+k .. o+2k]` = canonical variables `cv_0..cv_{k-1}`, `[o+1+2k ..]` = `2^(k-1)` pattern CRefs.
  A watcher visit reads only `[o .. o+k]` (5 words for k = 4, contiguous).
- `xorWatches[v]`: per-variable list of record offsets (a variable is watched regardless of polarity).

### D5. XOR propagation (all four routines)
In `propagate`, `propagateForLK`, `simplePropagate`, `simplepropagateForLK`, for each dequeued literal `p`:
binary watches first (unchanged), **then the XOR watches of `var(p)`**, then the long-clause watches. XORs come
before long clauses because a visit is cheap (no clause memory) and an XOR conflict found first saves long-clause
inspections; binary-first is kept.

For each record watching `x = var(p)`:
1. Make `w_1 = x` (swap with `w_0` if needed).
2. Look for an unassigned `w_j`, `j >= 2`. If found: swap `w_1, w_j`, move the watcher to `xorWatches[w_1]`, done.
3. Otherwise all of `w_1..w_{k-1}` are assigned. Let `s = parity XOR (XOR of their values)`.
   - `w_0` unassigned: implied `w_0 = s`. Reason = the pattern clause that excludes the current assignment with
     `w_0 = 1 - s`. The implied literal is swapped to position 0 of that clause (it is unwatched, so its literal
     order is free), then the routine's own enqueue is called (`uncheckedEnqueue`, `uncheckedEnqueueForLK` with its
     `false -> falseVar` convention, `simpleUncheckEnqueue`, `simpleuncheckedEnqueueForLK` plus its soft-variable
     test).
   - `w_0` assigned to `s`: satisfied, keep watching.
   - `w_0` assigned to `1 - s`: conflict. The conflict clause is the pattern clause falsified by the current
     assignment. The routine's own conflict convention is followed (`propagate` / `propagateForLK` /
     `simplepropagateForLK`: `qhead = trail.size()`, copy the remaining XOR watchers, skip the long-clause loop of
     this literal; `simplePropagate` likewise).
- Backtracking needs nothing: as with 2-watched literals, the invariant (a watched variable is assigned only if all
  non-watched variables are assigned at a level not above it, or the XOR has been propagated) survives undoing any
  suffix of the trail. This covers `cancelUntil`, `cancelUntilBeginning`, the lookahead resets and
  `cancelUntilTrailRecord*`.

### D6. Analysis, lookahead lookback and soft-conflict analysis are unchanged
They only see `CRef`s of real clauses. The convention "a reason clause has its implied literal at index 0" (used by
`analyze`, `simpleAnalyze`, `simplelookback`, `lookbackResetTrail`, the soft-conflict analyses, `locked()`) holds by
the swap in D5. Conflicts may come in any literal order, as for clauses.

### D7. Switches
- `distqldpc -no-xor`, `maxcdcl -no-xor` (MiniSat BoolOption `xor`, default on), `-xor-maxk=N` (3..6).
- With `-no-xor` no detection runs and every XOR code path is guarded by `xorCount == 0`; `-v` traces must be
  byte-identical to frozen95 (GH-95 comparison rule).
- Default: XOR on (this is the candidate).
- Debug builds: `-DXOR_SELFCHECK`, `-DXOR_STATS` (below).

## Soundness argument

1. **Same unit-propagation closure.** Let `X` be an XOR over `k` variables with parity `b`, and `C(X)` its
   `2^(k-1)` clauses, each excluding one wrong-parity assignment. A clause of `C(X)` is unit or false only when at
   least `k-1` of its literals are false, so at least `k-1` variables of `X` are assigned. If exactly `k-1` are
   assigned, the two completions have different parities; the wrong one is excluded by exactly one clause of `C(X)`,
   which is unit and implies the right value. This is exactly step 3 of D5. If all `k` are assigned with the wrong
   parity, exactly one clause of `C(X)` is false (the conflict of D5); with the right parity none is. Fewer than
   `k-1` assigned: neither propagator acts. So, at a fixpoint, the XOR propagator plus clause propagation on the rest
   yields the same assignment closure and the same conflict existence as clause propagation on the full CNF. Only
   the order of implications differs.
2. **Reasons and conflicts are real original clauses**, unchanged and present in the clause DB, with the implied
   literal at index 0 and all other literals false. Every learnt clause, iset clause, lookahead lower-bound
   explanation and soft-conflict explanation is therefore derived by resolution from clauses of the formula, exactly
   as before. No new clause type exists for the analyses.
3. **Formula unchanged.** No clause is added or removed by detection. `checkSolution` and the writers still see
   every clause. Skipping `reduceClause` on XOR clauses and keeping satisfied XOR clauses only forgo optional
   strengthening/cleanup.
4. Consequence: bounds proven with XOR propagation are sound for the same reasons as with clause propagation. The
   search path changes (implication order, conflict choice), so Tier0 uses the science sweep and the fuzz oracle
   rather than trace identity, plus trace identity for `-no-xor`.

## Debug self-check (`-DXOR_SELFCHECK`)
- After every propagation fixpoint (no conflict, no `falseVar`) in each of the four routines: scan all XORs and
  abort with `XOR_SELFCHECK_FAIL` if one has exactly one unassigned variable (an implication the XOR propagator
  missed, i.e. a unit clause of its CNF) or is fully assigned with the wrong parity (a false clause of its CNF).
- At each XOR implication: the reason clause has the implied literal at index 0, it is true, all other literals are
  false. At each XOR conflict: all literals of the conflict clause are false.
- Watch invariant: each record is in exactly the watch lists of `w_0` and `w_1` (checked at detection and
  periodically).
- Recycled dynamic variables are not in any XOR.

## Work counters (`-DXOR_STATS`)
In `propagateForLK`: long-watcher visits, clause inspections (visits that read clause memory), XOR watcher visits,
XOR implications and conflicts; plus `LOOKAHEAD` calls. Printed cumulatively (`c XOR_STATS ...`) every 5 s of CPU
time and at the end of each `solve_`. Since the search changes, the informational metric is progress per second
(lookahead calls per second) and inspections per lookahead call.

## Tier0 plan
Smoke, partition oracle tests; self-check build 0 failures on 50 codes x 4 modes (20 s); `-no-xor -v` identity vs
frozen95; science sweep vs main 7eadd54 (50 x 4, 60 s, 4 jobs); maxcdcl fuzz (300+ instances, some with planted
XOR families) vs GH-95 maxcdcl; XOR detection report; work counts (4 cases, 30 s); cross-repo workflow.
Batches longer than 10 minutes run under the coordinator timing lock.
