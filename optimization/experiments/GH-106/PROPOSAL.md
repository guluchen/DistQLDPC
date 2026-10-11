# GH-106 proposal: incremental half-solver policy (written before implementation)

Issue #106, hub #15. Base: GH-89 `09d8bc2`. Evidence: `DIAGNOSIS.md` (commit `fa06270`).
Experimental: Tier0 by this agent; Tier1/Tier3 timing is the coordinator's decision.

## Design: `-inc-policy=<p>`, driver-only (src/core/distqldpc.cc, `run_css_half`)

The engine (`src/solver/`) is not changed. A policy only decides, before a probe, whether the half's persistent
solver is kept or replaced by a freshly built one (`css_half_build`, the existing construction path used for the
first probe and for `INC_REBUILD`). Every probe is then answered by the unchanged `incProbe`.

| policy | fresh solver before a probe when ... | rationale |
|---|---|---|
| `gh89` | never (only on `INC_REBUILD`) | GH-89 byte-identical (same code path, no extra output) |
| **`postsol` (default)** | the half's solver has not found a solution yet (`!S->feasible`) | F1: before the first solution persistence carries only heuristic state (learnts are dropped on every raise), which caused TN_144's 635k-conflict first FOUND; after it, learnts pay off (F3) |
| `feasfresh` | `!S->feasible`, or the probe is a feasibility (stop-at-first) probe | also removes F2 (post-solution feasibility probes stop at the cap); optimisation probes continue the solver of the half's latest probe |
| `fresh` | always | one fresh solver per probe = main 7eadd54's per-probe search (counter-identical, DIAGNOSIS F4); reference/fallback |

Choice of default: in the diagnostic screen (DIAGNOSIS section 4) `postsol` has the best large-cell geomean
(0.76 of main's conflicts; GH-89 0.88), removes the LP_442 card-mto (1.52 -> 0.95) and BB_144_14_14 (1.09 -> 0.82)
regressions, cuts TN_144 from 2.42 to 1.50, and keeps the small-code gains (Tier1 0.68 vs GH-89 0.72; LP_340
0.81/0.68 vs 0.63/0.58). Known residual: TN_144 no-card stays about 1.5x main in conflicts (F2). `feasfresh` has
the smallest worst case (TN 0.81, worst 1.03) but loses the small-code gains (Tier1 0.95, LP_340 1.00); it is
provided so that the coordinator's timing can arbitrate. Not proposed: per-probe heuristic reset (`heurreset`,
needs a new engine transition, new BB_144_14_14 regression 1.57), learnt purges (F3 shows they hurt), cap-distance
rebuild thresholds (all regressing probes are one cap step apart, so a threshold cannot separate them).

## Soundness

Each policy uses only two mechanisms that are already validated: (i) a fresh build of the half instance (with its
GH-85 orbit clauses), prepared by `incPrepare` and probed by `incProbe` with the proven half LB as `knownLB`
(exactly the GH-76 rebuild path); (ii) GH-76 persistent probes on an unchanged instance. A fresh instance is the
same formula, so every answer (NONE / FOUND / OPT and the proven LB fed back) stays exact (GH-76 / GH-89 arguments).
The witness check on every reported half weight is unchanged. Builds are counted in `h.builds` (reported by `-v`).

## Validation plan (Tier0, this agent; preregistered)

1. Build `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"`; `scripts/smoke_test.sh`.
2. `python3 -B scripts/test_partition_soft_literals.py`; GH58 oracle `tests/test_partition_soft_literals.cc`
   (cases=80).
3. Incremental oracles extended to the policies: `tests/test_incremental_probes.cc` (engine; the probe driver
   emulates each policy's rebuild rule) and `tests/test_incremental_symbreak.cc` (production `run_css_half` under
   each `g_inc_policy`), 20,000 instances each, 0 failures. GH-89 counts for the `gh89` policy must be unchanged.
4. Identity: `-inc-policy=gh89 -v` byte-identical to `frozen89/cand` on BB_90_8_10, GB_144_12_8, BB_108_8_10,
   LP_238_44_6, LP_34_20_2, BB_72_12_6, TN_36_8_4 x {no-card, card-mto, default}, `-cpu-lim=120`, serial;
   `-joint -v` byte-identical to `frozen89/cand -joint -v` on the same set.
5. Science sweep `tier0_science.py` (GH-102 copy, 2 GB capped), 50 codes x 4 modes, 60 s, `--jobs 4`, under the
   timing lock: completed values equal names and the baseline; every emitted bound sound.
6. QDistSAT cross-repo: one-commit branch `ci/xrepo-gh106` (candidate tree, parent 72d1fe1) and workflow dispatch.
7. Informational counters on the diagnosis cells (TN_144 no-card, LP_442 card-mto, GB_144_12_12 card-mto,
   LP_340): new default vs `gh89` vs main, from the candidate's own `-v` probe log plus the counter build.
8. Freeze `frozen106/cand/distqldpc` read-only with sha256.
