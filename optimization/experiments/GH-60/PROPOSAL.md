# GH-60 preregistration: keep the conflict-independent lookahead prefix

Issue https://github.com/guluchen/DistQLDPC/issues/60 (copied below, then exact test parameters).

Owner/session `mac-lkprefix-20261009` (same Mac-host agent as #34, fresh round after #34 ended INCONCLUSIVE; the user asked me to continue rounds without waiting). Hub #15. Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`; NOT stacked on #34. Hypothesis IDs GH-60-A/B/C. Host: Apple M6 Mac mini, user-authorised, sole runner, same guards as #34 (diagnostic, not controlled).

## Evidence before proposing (baseline counters, scratch-only instrumentation, no timing)
Main `Solver::lookahead()` on the 4 Tier1 cases x OFF/MTO:
- ~92% of all lookahead enqueues are undone by `lookbackResetTrail`, which after every non-final iset conflict unassigns the whole lookahead trail back to `trailRecord` (e.g. BB108 OFF: 377k resets, 39.4M of 42.8M enqueues undone, ~105 literals per reset).
- 39–44% of lookahead enqueues re-derive a literal already derived earlier in the same lookahead call.
- Of the undone literals, 7–14% lie below the earliest trail position the conflict depends on (reason-closure walk), i.e. are independent of the conflict and would be re-derived from scratch.
- Lookaheads that prune use 54–64% of enqueue work; work after success becomes impossible is negligible (so early termination is not promising).
- Prior learning (#34, #40, #50): cheaper per-watcher work buys <=1% or regresses through layout; fewer visits is the lever.

## Three proposals (ranked)
**A (SELECTED) — keep the conflict-independent lookahead prefix.** In the main `lookahead()` only, on a non-final iset conflict (both the hard-conflict and soft-falsification branches, only when another iset is still needed), stop `lookbackResetTrail`'s downward unassign loop at the point where its existing conflict analysis completes (pathC reaches 0 outside the UIP shortcut). Everything below is provably independent of the conflict: it stays assigned and propagated, `qhead`/trail end at that point. Lock bookkeeping: `setConflict` still restores all unlock decrements and registers the iset exactly as before; afterwards the decrements of still-assigned literals are re-applied in original order (what re-deriving them would do). Final conflicts, the UIP/unit-iset path, `lookaheadForRestart` and simple* lookahead keep the original full reset. Search CHANGES (pick order/state), so LB soundness is argued, not inherited: kept literals are UP consequences of probed soft literals not in any registered iset, exactly the state baseline reaches by re-probing them first. Upper bound on saving ~12% of lookahead enqueues (~8% of runtime); could also change LB strength either way. Engineering/algorithmic origin; related to trail saving (B), not copied from it.
**B (unselected) — trail saving/replay in lookahead**, adapted from R. Hickey, F. Bacchus, "Trail Saving on Backtrack", SAT 2020, LNCS 12178, pp. 46–61, DOI 10.1007/978-3-030-51825-7_4 (Sect. 4, Theorem 1, Sect. 4.2 read via PMC7326469). Save undone implications with reasons and replay them when a probe is re-picked. Larger reach (39–44% re-derivations) but replayed literals must still be propagated (paper Sect. 4, Example 2) and plain trail saving showed no significant effect in CaDiCaL (Sect. 5); multi-day, lock interplay harder. Outside the 2-year window.
**C (unselected) — code-layout sensitivity control.** Fixed function/loop alignment for both versions to test whether the +-1–5% swings seen in #34/#40 are layout artifacts. Methodology value, small optimization potential; compiler-flag family already heavily explored.

## Scope / exclusions
Only `Solver::lookahead()`'s two non-final conflict sites, a `partial` option of `lookbackResetTrail`, a lock re-apply helper and a full-undo fallback. No change to propagation, heuristics, iset registration logic, hardening, encoding, flags, timeouts, outputs. Not combined with #34 or any other candidate.

## Validation (preregistered in PROPOSAL.md before implementation)
Tier0 (search changes, so no trace identity): (1) build/smoke; (2) distances = named and = baseline for every bundled code/mode finishing within 60 s, all emitted LB/UB sound vs named distance for the rest (50 codes x 4 modes); (3) randomized exhaustive oracle: small unit-weight partial MaxSAT WCNFs solved by `bin/maxcdcl` baseline and candidate vs brute force (baseline crashes, cf. #58, recorded separately; any candidate wrong optimum = STOP/REJECT); (4) check build asserting kept-prefix invariants (no seen literal below the cut, prefix propagated, lock counters equal a from-scratch recomputation); (5) LP340 timeout semantics; (6) hosted CI + QDistSAT cross-repo.
Tier1/Tier2: identical protocol and unchanged GH16 judge as #34 (3+3 AB/BA/AB, 180/195 s; LP340 only via gate or the recorded standing exploratory instruction). No Tier3.
Disposition: any wrong distance/bound, crash, or assertion = REJECT and stop.

## Exact Tier0 parameters (fixed before implementation)
- Build both with `make CXX="c++ -Wno-reserved-user-defined-literal"` from clean trees.
- Bundled-code science: all 50 codes x {default, no-card, card-mto, card-sinz}, `-cpu-lim=60`,
  4 in parallel, both binaries. Completed runs: rc 0 and `o N` equal to the named distance
  (xu_*/PK_* names carry no distance: must equal the baseline's completed value when both
  complete). Every run, completed or not: every emitted `c d_lb: x` <= named distance <= every
  emitted `c d_ub: y`. A completed candidate value differing from a completed baseline value =
  STOP/REJECT.
- Exhaustive oracle: 3000 random unit-weight partial MaxSAT WCNFs (seeded generator committed
  with the record; 8–20 variables, random 2–4-literal hard clauses, 6–20 unit and binary soft
  clauses), brute-force optimum in C, both `bin/maxcdcl` binaries with a 20 s limit. Candidate
  wrong optimum or UNSAT/SAT mismatch = STOP/REJECT. Baseline-only crashes are recorded (#58);
  a candidate crash where the baseline succeeds = STOP/REJECT.
- Check build (`-DLKPREFIX_CHECK`, never in production): after each partial reset assert
  (i) no `seen` literal remains at or above the cut, (ii) every kept literal's reason clause is
  unit-implying under the kept assignment, (iii) qhead == trail.size(), (iv) after lock re-apply,
  every iset lock equals a from-scratch recount; run on the 4 Tier1 cases + LP_34/LP_136 OFF/MTO.
- Timeout outputs for LP_340 at 1 s and 5 s keep the original format.
- Hosted CI and QDistSAT cross-repo check on the draft PR.
Tier1/Tier2 exactly as in GH-34 TIER1_RUN.md (runner `tier1_mac.py` copied unchanged).
