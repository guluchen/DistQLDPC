# GH-94 PROPOSAL — triple stack: GH-89 (incremental halves x per-half symmetry breaking) + GH-87 dual-half elimination

Issue: https://github.com/guluchen/DistQLDPC/issues/94 (interaction experiment). Hub: #15.
Agent: Mac merge/Tier0 agent (correctness only; Tier1/Tier2 timing by the coordinator under the
timing lock). Branch: `experiment/gh-94-triple-stack` from GH-89 candidate source `09d8bc2`
(= 72d1fe1 + GH-76 persistent half solver + GH-85 per-half orbit clauses). Written before any
code change.

## Status: preregistered interaction experiment

* GH-89 (GH-85 x GH-76): Tier1 vs 72d1fe1 OFF 0.105 / MTO 0.096; largest gains on BB_108 (0.40x
  vs GH-85) and LP codes (0.55-0.77x vs GH-85).
* GH-92 (GH-85 x GH-87, dual-half elimination with A1): Tier1 vs 72d1fe1 OFF 0.101 / MTO 0.089;
  largest gains on dual-map codes GB_144 (0.33-0.42x vs GH-85) and BB_90 (0.55-0.61x).
The two stacks change disjoint mechanisms (how a half is probed vs which halves are solved), so
the protocol requires a separate interaction experiment for the triple combination.

## Hypothesis

Adding GH-87 dual-half elimination to GH-89 combines both gains: on codes with a verified XZ-dual
map (all BB codes, GB_144_12_8, GB_144_12_12, TN_36_8_4) the triple stack solves only the X half,
with GH-76's persistent solver and GH-85's orbit clauses, so it should approach GH-92's gain on
BB/GB while keeping GH-89's incremental gain; on codes without a dual map (LP, PK, xu, other TN)
it equals GH-89 (detection only, milliseconds).

## Comparisons (for the coordinator's Tier1/Tier2)

* **Primary:** triple vs GH-89 (`09d8bc2`, frozen `frozen89/cand/distqldpc`, sha256 fb6846d0...).
* **Secondary:** triple vs GH-92 (`e226951` source, `frozen92/cand/distqldpc`, sha256 49e37dee...)
  and vs corrected baseline 72d1fe1 (`frozen73n/base/distqldpc`).
Same harness and gates as GH-89/GH-92 Tier1 (BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6;
no-card and card-mto) and Tier2.

## Mechanism

1. Port GH-92's dual-half delta `git diff cc7e5ea e226951 -- src` (src/core/distqldpc.cc only)
   onto `09d8bc2`: shared `candidate_family(n, with_identity)` (GH-92 dedup; GH-85's list
   unchanged), `DualMapInfo`/`find_dual_maps`, `g_dualskip`, `-no-dualskip`, `-dualskip-report`,
   driver order "dual-map detection first; if verified, the Z half is eliminated
   (`hs[1].exists = false`); then per-half symmetry detection on every half still present".
2. When the Z half is eliminated only the X half is solved, with GH-76's persistent half solver
   (`css_half_build` / `run_css_half` / `incProbe`, unchanged) and GH-85's orbit clauses on that
   half (part of the instance from construction, as in GH-89). Otherwise the code path is GH-89's
   exactly (no dual map: one extra `c dualskip:` line under `-v`).
3. Flags kept: `-joint` (= 72d1fe1), `-no-symbreak`, `-symbreak-report`, `-no-dualskip`
   (= GH-89 exactly), `-dualskip-report` (= GH-92).

### Care point: GH-87 A1 under the GH-76 incremental contract

GH-76's `incProbe` contract: once a half instance is feasible (has found a solution), its UB may
only *fall* (at level 0, keeping all state); a request that would *raise* it above the ceiling of
the previous probe returns `INC_REBUILD`, and GH-76's `run_css_half` then rebuilds the instance
(with the proven LB, and in GH-89 with the identical orbit clauses).

A1 (single-half phase 2b caps at U-1 when the X half holds the incumbent) asks for a *lower* cap
after a solution, i.e. a fall, which the contract allows. Analysis of `incProbe` (Solver.cc):
after Phase 1's FOUND at weight U, `inc_sup = inc_ceil = U - offs` (search units). GH-89's phase 2b
probe (cap U, optimise) computes target = min(capU + 1, inc_sup) = inc_sup; A1's probe (cap U-1)
computes target = min(U - offs, inc_sup) = inc_sup. Both run the identical search for cost
< inc_sup (weight <= U-1) from the identical state, and target <= inc_ceil, so no rebuild is ever
requested. They differ only in the reported label: no improvement -> GH-89 returns OPT U, A1
returns NONE (driver sets lb = U, d = U with the Phase-1 witness); improvement -> both OPT v < U.

**Choice: keep A1, expressed through the existing probe API** (option 1 of the issue). It respects
the contract (cap fall only; no later probe on that half), needs no rebuild, and keeps the GH-92
semantics. Should a future change make the A1 cap exceed the instance ceiling, `incProbe` would
return `INC_REBUILD` and GH-76's existing rebuild path in `run_css_half` would handle it soundly.
This is documented in a code comment.

## Soundness argument

* Dual elimination is exact (GH-87): a verified pi with pi(rs Hz) = rs Hx and
  pi(rs[Hz;Gx]) = rs[Hx;Gz] is a weight-preserving bijection F_X -> F_Z, so dX = dZ = d and every
  bound proven on the X half alone is global.
* Orbit clauses preserve each half's existence-at-weight answers (GH-85): for every w, the X half
  has a solution of weight <= w iff it has one satisfying the clauses (built only from verified
  plain automorphisms of that half, never from the XZ-dual map).
* GH-76 probes are exact for a fixed formula: on the fixed formula F_X u S, `incProbe` performs
  only MaxCDCL's own bound transitions; a forbidden raise yields `INC_REBUILD` and a fresh,
  identical formula with the proven LB. The A1 probe is a cap fall (see above).
Hence every X-half answer (FOUND/NONE/OPT under any cap, including U-1) is exact for F_X, and its
optimum and proven bounds are global. Witnesses are re-checked by GH-76's driver witness check.

## Tier0 validation (preregistered; this agent; no timing)

1. Mac build `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"`, no new warnings in
   `distqldpc.cc`; freeze at `frozen94/cand/distqldpc` (read-only) with sha256.
2. `scripts/smoke_test.sh`; `python3 -B scripts/test_partition_soft_literals.py`;
   `tests/test_partition_soft_literals.cc` oracle (`GH58_PARTITION_ORACLE_PASS cases=80`).
3. GH-76 `tests/test_incremental_probes.cc` and GH-89 `tests/test_incremental_symbreak.cc`
   unchanged, 20000 instances each on the Mac, 0 failures. If feasible, extend the GH-89 oracle
   with a dual-map path test: random small CSS instances whose X and Z halves are related by a
   known permutation, the production driver's answer must equal brute-force min(dX, dZ).
4. Trace identities (`-v`, `-cpu-lim=120` on both sides) on BB_90_8_10, GB_144_12_8, BB_108_8_10,
   LP_238_44_6, LP_34_20_2, BB_72_12_6, TN_36_8_4 x {no-card, card-mto, default}:
   `-no-dualskip` == frozen89 byte-identical; `-joint` == 72d1fe1; on LP codes default == frozen89
   except the single `c dualskip: no dual map` line.
5. Checkers: GH-85 `verify_half_autos.py` and GH-87 `check_dual_maps.py` ALL_PASS on the 50 codes;
   `-symbreak-report` / `-dualskip-report` outputs identical to GH-92.
6. Science sweep on the Mac under the timing lock: `tier0_science.py` (50 codes x 4 modes, 60 s,
   `--jobs 4`) vs 72d1fe1; completed values equal name/baseline; every emitted
   d_lb <= d <= d_ub; zero unsound. TN_648_10_71's name is known wrong: reported, not blamed.
7. QDistSAT cross-repo benchmark on one-commit branch `ci/xrepo-gh94` (candidate tree, parent
   72d1fe1); scientific match must be YES.
Any unsound answer or identity failure that cannot be fixed soundly = FAIL, recorded honestly.
