# GH-106 v2 proposal: conflict-budgeted persistent probes (`-inc-policy=budgettot`), written before committing code

Follow-up to `TIMING_RESULT.md` (coordinator): postsol passes everywhere except TN_144_2_13 no-card (1.74x main), the
post-solution chain of at-cap solutions of DIAGNOSIS F2. Experimental; Tier0 by this agent, timing by the coordinator.

## Screen (diagnostic counter build of the v2 driver, total conflicts / main 7eadd54)
All runs serial, one solver process, 2 GB cap, `-cpu-lim=300`, all complete with the named distance. The counter
build is the candidate source plus `gh106Dump` (diag `counter_build_*`); `-inc-policy=postsol` and `gh89` there are
search-identical to the previous counter builds (checked on LP_340/LP_442 no-card).

Large cells:
| cell | gh89/main | postsol/main | atcap/main | atcapfeas/main | budget2/main | budget4/main | budget8/main | budget4f50k/main | btot1/main | btot2/main |
|---|---|---|---|---|---|---|---|---|---|---|
| TN_144_2_13.no-card | 2.42 | 1.50 | 0.81 | 0.81 | 0.86 | 0.91 | 1.00 | 0.91 | 0.83 | 0.85 |
| TN_144_2_13.card-mto | 0.75 | 0.53 | 1.21 | 1.07 | 0.53 | 0.53 | 0.53 | 0.53 | 0.53 | 0.53 |
| LP_442_68_10.no-card | 0.46 | 0.35 | 0.36 | 0.35 | 0.35 | 0.35 | 0.35 | 0.35 | 0.35 | 0.35 |
| LP_442_68_10.card-mto | 1.52 | 0.95 | 0.93 | 0.93 | 0.95 | 0.95 | 0.95 | 0.95 | 0.95 | 0.95 |
| GB_144_12_12.no-card | 0.82 | 0.45 | 1.00 | 0.68 | 0.75 | 0.80 | 0.45 | 0.80 | 0.87 | 0.45 |
| GB_144_12_12.card-mto | 0.52 | 0.52 | 0.52 | 0.52 | 0.52 | 0.52 | 0.52 | 0.52 | 0.52 | 0.52 |
| BB_144_14_14.no-card | 1.09 | 0.82 | 1.03 | 1.03 | 1.09 | 0.93 | 1.05 | 0.93 | 0.87 | 0.91 |
| BB_144_12_12.no-card | 1.04 | 0.95 | 0.99 | 0.95 | 0.95 | 0.95 | 0.95 | 0.95 | 0.95 | 0.95 |
| LP_340_56_8.no-card | 0.63 | 0.81 | 1.00 | 1.00 | 1.32 | 1.32 | 0.81 | 0.81 | 0.81 | 0.81 |
| LP_340_56_8.card-mto | 0.58 | 0.68 | 1.00 | 1.00 | 0.93 | 1.02 | 0.68 | 0.68 | 0.68 | 0.68 |
| geomean | 0.86 | 0.70 | 0.84 | 0.79 | 0.77 | 0.78 | 0.69 | 0.71 | 0.71 | 0.67 |

Tier1 cells:
| cell | gh89/main | postsol/main | atcap/main | atcapfeas/main | budget2/main | budget4/main | budget8/main | budget4f50k/main | btot1/main | btot2/main |
|---|---|---|---|---|---|---|---|---|---|---|
| BB_90_8_10.no-card | 0.76 | 0.88 | 0.88 | 0.88 | 0.88 | 0.88 | 0.88 | 0.88 | 0.88 | 0.88 |
| BB_90_8_10.card-mto | 0.89 | 0.86 | 0.86 | 0.86 | 1.15 | 0.86 | 0.86 | 0.86 | 0.86 | 0.86 |
| GB_144_12_8.no-card | 1.01 | 0.79 | 1.00 | 1.00 | 0.79 | 0.79 | 0.79 | 0.79 | 0.79 | 0.79 |
| GB_144_12_8.card-mto | 0.78 | 0.66 | 1.00 | 1.00 | 0.66 | 0.66 | 0.66 | 0.66 | 0.66 | 0.66 |
| BB_108_8_10.no-card | 0.52 | 0.44 | 0.44 | 0.44 | 0.44 | 0.44 | 0.44 | 0.44 | 0.44 | 0.44 |
| BB_108_8_10.card-mto | 0.50 | 0.48 | 0.48 | 0.48 | 1.04 | 0.48 | 0.48 | 0.48 | 0.48 | 0.48 |
| LP_238_44_6.no-card | 0.75 | 0.72 | 0.87 | 0.87 | 0.72 | 0.72 | 0.72 | 0.72 | 0.72 | 0.72 |
| LP_238_44_6.card-mto | 0.65 | 0.78 | 0.92 | 0.92 | 0.78 | 0.78 | 0.78 | 0.78 | 0.78 | 0.78 |
| geomean | 0.72 | 0.68 | 0.77 | 0.77 | 0.78 | 0.68 | 0.68 | 0.68 | 0.68 | 0.68 |

Policies screened (all = postsol before the half's first solution):
* `atcap`: fresh solver for the probe after a FOUND exactly at its cap; `atcapfeas`: only if that probe is a
  feasibility probe. They fix TN no-card (0.81) but fire after nearly every first FOUND (phase-1 caps are powers of
  two and first solutions land on them), losing persistence where it pays: TN card-mto 1.21/1.07, LP_340 1.00.
* `budget` (K x the most conflicts of a fresh probe of the same half, floor F): the per-half fresh cost is a poor
  scale (TN's first FOUND took 16 conflicts, LP_340's 1.5k), so small K cuts good persistent probes (LP_340 1.32,
  BB_144_14 1.09, GB_144 no-card 0.75-0.80) and large K wastes too much before falling back (K=8: BB_144_14 1.05).
* **`budgettot`** (K x all conflicts spent so far by both halves in this run, floor F): the run's own cost so far is
  a scale that grows with instance difficulty. K=2, F=10000: worst cell 0.95 (LP_442 card-mto, BB_144_12_12 no-card,
  both = postsol), TN no-card **0.85** (X15 persistent probe stopped at 59k conflicts, fresh probe finds 13; the
  persistent Z12 refutation finishes inside its budget at 242k vs 254k fresh), every other cell equal to postsol
  (no fallback fired), large geomean 0.67, Tier1 0.68 (= postsol). K=1 cuts GB_144 no-card's good persistent probe (0.87).

## Design (selected default: `-inc-policy=budgettot -inc-budget=2 -inc-budget-floor=10000`)
* Before the half's first solution: fresh solver per probe (postsol).
* A post-solution feasibility (stop-at-first) probe on the kept solver runs with a conflict limit
  `conflicts_now + max(K * C, F)`, C = conflicts spent so far by all half probes of the run. Optimisation probes and
  probes on a freshly built solver have no limit.
* Limit reached (no solution found within it): the instance is discarded and the same probe is answered by a freshly
  built instance (no limit). The interrupted probe contributes no answer and no bound (refuted bounds are emitted only
  when a probe ends with l_False). Deterministic: the limit is in conflicts, checked between `search()` calls.
* Engine change (minimal): `Solver::inc_conflictLimit` (default UINT64_MAX), checked in `incProbe`'s phase loops next to
  `asynch_interrupt`; it returns the existing `INC_INTERRUPTED`. With the default limit the engine is unchanged in
  behaviour, so `-inc-policy=gh89` stays GH-89 byte-identical and `postsol` stays the frozen106 behaviour.
* Other policies kept for arbitration: gh89, postsol, feasfresh, fresh, atcap, atcapfeas, budget.

## Soundness
A discarded instance's partial work is never used: the probe's answer (NONE/FOUND/OPT, witness-checked) comes from a
complete `incProbe` on either the kept instance (GH-76 transitions) or a fresh instance of the same formula (GH-76
rebuild path). Hence every argument of PROPOSAL.md / GH-89 applies unchanged.

## Tier0 plan (as v1)
Build, smoke, partition oracles, GH58 (80); `test_incremental_probes` and `test_incremental_symbreak` 20,000 each for
gh89 / postsol / budgettot (default K, F) and budgettot with K=0, F=0 (every post-solution feasibility probe falls back:
exercises the interrupt-and-rebuild path) plus atcap/atcapfeas/budget, 0 failures; gh89 counts unchanged;
`-inc-policy=gh89 -v` and `-joint -v` byte-identical to frozen89 (21 + 21) and `-inc-policy=postsol -v` byte-identical
to frozen106 (21); science sweep in chunks under the lock (2 GB cap) vs main; cross-repo `ci/xrepo-gh106v2`; freeze
`frozen106/v2/distqldpc`.
