# GH-89 PROPOSAL — incremental half solver with per-half symmetry breaking (GH-85 x GH-76 interaction)

Issue: https://github.com/guluchen/DistQLDPC/issues/89 (three proposals, selection A).
Agent/session: `mac-split-symbreak-inc-20261009` (Mac host; Tier0 correctness only, no timing).
Baseline: corrected source `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (#62).
Branch: `experiment/gh-89-mac-symbreak-inc` (from 72d1fe1). Written before any implementation.

## Status: preregistered interaction experiment

Parents (both on #73's interleaved split `a1585b4`, both Tier1+Tier2 PASS on 72d1fe1, Mac):
* GH-85 = #73 + per-half orbit symmetry breaking (`cad2c70` + `cc7e5ea`): Tier1 OFF 0.159 / MTO 0.145, LP340 56x/37x.
* GH-76 = #73 with a persistent per-half solver (`b3d6b5d`): Tier1 OFF 0.396 / MTO 0.415, LP340 0.030/0.047.
Gate comparison vs 72d1fe1; GH-85/GH-76 comparisons are informational (attribution). PI approval of
formulation changes: 2026-10-09 (#71).

## Mechanism (GH-89-A)

1. Apply GH-76's source delta `a1585b4..b3d6b5d` on top of #73 `a1585b4` (as committed in `b3d6b5d`, which is
   based directly on 72d1fe1), i.e. start from the tree of `b3d6b5d` for `src/` and `tests/`.
2. Apply GH-85's delta `cad2c70..cc7e5ea` (distqldpc.cc only): GF(2) basis, candidate family, verified per-half
   automorphisms and orbits, `add_half_orbit_clauses`, `build_css_half(..., sb_orbit)`, detection once per half
   in `min_distance_css_interleaved`, flags `-no-symbreak` / `-symbreak-report`.
3. Conflict resolution (expected in `CssHalf`, `run_css_half`, the `hs[]` initialiser, the driver signature):
   * `CssHalf` keeps both GH-76's `S/n/builds` and GH-85's `sb_orbit`.
   * GH-76's `css_half_build` (the only place a half's persistent solver is constructed: first probe and every
     `INC_REBUILD`) passes `h.sb_orbit` to `build_css_half`, so the orbit clauses are part of the instance from
     construction and identical in every rebuild. `run_css_half` (GH-76 version) never builds per probe and adds
     nothing per probe.
   * Detection (GH-85) runs before Phase 1, before any half solver exists.
4. Flags: default = symmetry breaking on; `-no-symbreak` = GH-76 exactly; `-joint` = baseline exactly;
   `-symbreak-report` as GH-85. GH-76 has no non-incremental switch (it removed #73's per-probe engine hooks),
   so GH-85 behaviour is not reproducible by a flag of this candidate; GH-85's own frozen binary serves that
   attribution (GH-89-B, unselected, would add one).

## Soundness argument

Let F be a half instance and S the GH-85 orbit clauses (with prefix aux vars). GH-85 (reviewed): S is built
from verified automorphisms of F that preserve |v|; for every w, F has a solution of weight <= w iff F u S
has one, and the v-projection of every solution of F u S solves F (the aux vars are defined by v).
GH-76: on one fixed formula, `incProbe` performs only MaxCDCL's own bound transitions, so every probe answer
(NONE / FOUND / OPT and the per-probe refuted bound) is exact for that formula; a forbidden raise yields
`INC_REBUILD` and a fresh instance of the same formula with the proven LB.
Here the fixed formula is F u S, constructed once (and identically on rebuild). Hence every answer is exact for
F u S and, by GH-85's every-w equivalence, exact for F: NONE at cap c proves no F-solution of weight <= c; the
proven LB fed back as `knownLB` (also into a rebuild) is valid for both F and F u S; FOUND/OPT witnesses are
F-solutions (re-checked by GH-76's driver witness check on Hpar/Glog/weight); OPT equals F's optimum. Since S is
optimum- and feasibility-preserving at every weight, no probe order, cap, or rebuild can make it unsound.
Engine detail to verify: a transitive half adds the unit clause v_{r1}; the soft literal ~v_{r1} is then fixed
false at preprocessing (fixedCost 1 inside `incPrepare`, `incOffset()` > 0); GH-76's offset arithmetic and the
witness check must handle it (the oracle in Tier0.3 targets exactly this).

## Tier0 validation (preregistered; this agent)

1. Mac build `make -j2 CXX="c++ -Wno-reserved-user-defined-literal"` (no new warnings vs the parents);
   yfclab2 GCC 13.3 `make -j8`; `scripts/smoke_test.sh` both hosts.
2. Mandatory regressions (both hosts): `python3 -B scripts/test_partition_soft_literals.py`;
   `tests/test_partition_soft_literals.cc` oracle (compile line from `.github/workflows/ci.yml`).
3. Oracles: GH-76's `tests/test_incremental_probes.cc` unchanged (engine unchanged); new
   `tests/test_incremental_symbreak.cc` that includes the production `src/core/distqldpc.cc` (its `main`
   renamed at compile time) and drives the production `find_half_symmetry` -> `css_half_build` ->
   `run_css_half` on random small half instances whose row spaces are invariant under block/strided cyclic
   shifts (so the verified group and orbit clauses are non-trivial, including transitive -> unit clause), with
   GH-76-style probe schedules incl. forced raise-after-solution rebuilds; every answer checked against
   exhaustive enumeration of the half WITHOUT symmetry clauses (NONE => opt > cap; FOUND/OPT witness solves
   F with reported weight; OPT == opt). Same schedules with symmetry off as control. Any failure = REJECT.
4. Identities by `-v` traces (both parents deterministic per run): `-joint -v` vs fresh 72d1fe1 build and
   `-no-symbreak -v` vs fresh GH-76 `b3d6b5d` build, LP_34_20_2 / BB_72_12_6 / TN_36_8_4 x {default, no-card}
   (+ BB_90_8_10/GB_144_12_8 for `-joint`). Must be byte-identical. Default traces recorded for inspection
   (orbit report + probe log + solver build counts).
5. Science sweep on yfclab2 (correctness only, <= 8 solver processes, idle > 60 %), GH-60 `tier0_science.py`,
   50 codes x {default, no-card, card-mto, card-sinz}, 60 s, vs `~/mac-agent-20261009/frozen/gh73n/base/distqldpc`
   (72d1fe1): completed candidate values equal named and baseline completed values; every emitted
   d_lb <= d <= every emitted d_ub; every candidate timeout emits at least one d_lb. TN_648_10_71's name is known
   wrong (true d <= 52): reported, not fixed, not blamed on the candidate when the baseline agrees.
   Any other violation = REJECT and escalate.
6. QDistSAT cross-repo benchmark on one-commit branch `ci/xrepo-gh89` (candidate tree, parent 72d1fe1);
   scientific match must be YES.
7. Freeze the Mac candidate binary read-only outside build trees with SHA256 for the coordinator's Tier1/Tier2.
   No timing by this agent.
