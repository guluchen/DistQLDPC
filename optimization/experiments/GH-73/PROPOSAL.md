# GH-73 preregistration: interleaved CSS split with global bound search

Owner/session `mac-cssinterleave-20261009` (same Mac-host agent, round 6). Hub #15. Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`; a fresh implementation, NOT stacked on #71's candidate (re-gated against the baseline, compared to #71 informationally). Hypothesis IDs GH-73-A/B/C. Host: Apple M6 Mac (user-authorised, sole runner); diagnostic, not controlled. Formulation change covered by the PI approval recorded in #71 ("可以改", 2026-10-09).

## Basis
#71 (sequential CSS halves) passed Tier1 (OFF 0.452 / MTO 0.439) and Tier2 (LP340 5.7x / 2.7x) but its independent review found: (MAJOR) timed-out runs lose the lower bound (136/138 Tier0 timeouts emit no d_lb); asymmetric codes regress (TN_200, dX=14, dZ=10: 10.6 s -> 58 s, X solved first); no early stop; function-local `static` solver state leaks between the two solver instances; infeasible half -> UNKNOWN.

## Three proposals (ranked)
**A (SELECTED) — interleaved CSS split with a global bound search.** One concept: compute d = min(dX, dZ) by a single global search over d that uses per-half oracles, instead of two independent full solves.
1. Doubling phase m = 1, 2, 4, ...: for each half, a capped feasibility test "is there a half solution of weight <= m?" (solver stops at its first solution). Both infeasible => global LB = m+1 is emitted (anytime LB restored). Any feasible => global UB = best weight found.
2. The half with the smaller incumbent is solved to optimality, starting from its already-proven LB (no re-proof of lower levels), with bounds emitted as min(LB_half, LB_other) / min(UB, global UB).
3. The other half is then only asked "is there a solution of weight < d1?", starting from its proven LB; it stops as soon as that is refuted (early stop), else it is solved to optimum under the cap.
Engine support (directly serving the concept): `stopAtFirstSolution`, a known-LB start (`initLB`), separate LB/UB caps for bound forwarding, and converting the 14 function-local `static` heuristic variables (search/lookahead/addCardinalityConstraints) into per-instance members (search-identical for single-instance runs; `-joint` must stay byte-identical to baseline). An infeasible half is treated as "no logical of this type".
**B (unselected, needs PI decision) — solve the two halves in two parallel processes** and cap the slower one by the faster one's value; wall time ~max instead of sum, but doubles CPU per solve, which changes benchmark resource methodology.
**C (unselected, PI-approved, later) — code-automorphism symmetry breaking** (Satsuma, SAT 2024).

## Validation (preregistered in PROPOSAL.md)
Tier0: build/smoke; `-joint` byte-identical to baseline `-v` traces (Tier1 cases); 50 codes x 4 modes science sweep at 60 s (named distances, bound soundness) PLUS a preregistered anytime-LB check: for every run that times out in both versions, the candidate must emit a d_lb (report the distribution of candidate LB vs baseline LB, no pass/fail threshold beyond presence); TN_200 all 4 modes reported explicitly; hosted CI + cross-repo (dispatched on a baseline-parented branch). Tier1/Tier2 exactly as #71 (bound-soundness runner, unchanged GH16 judge). No Tier3.

## Exact parameters
Frozen binaries outside build trees; GH-60 harness (tier0_science.py, tier1_mac_dist.py) copied unchanged; an added post-processing script reports the anytime-LB comparison from science.json without changing pass/fail rules.
