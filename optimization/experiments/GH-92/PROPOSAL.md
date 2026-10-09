# GH-92 PROPOSAL — stack GH-87 dual-half elimination on GH-85 per-half symmetry breaking

Issue: https://github.com/guluchen/DistQLDPC/issues/92 (interaction experiment GH-85 x GH-87).
Agent: Mac merge/Tier0 agent (correctness only; Tier1/Tier2 timing by the coordinator under the
timing lock). Branch: `experiment/gh-92-symbreak-dualhalf` from GH-85 `cc7e5ea`
(= 72d1fe1 + GH-73 cherry-pick `cad2c70` + GH-85). Written before any code change.

## Status: preregistered interaction experiment

GH-85 (CSS split + per-half orbit symmetry breaking; Tier1 OFF 0.159 / MTO 0.145 vs 72d1fe1)
and GH-87 (CSS split + dual-half elimination with A1 single-half cap U-1; Tier1 OFF 0.285 /
MTO 0.320, Tier2 PASS) change different parts of the GH-73 split: GH-85 adds orbit clauses
inside each half instance, GH-87 removes the Z half when a verified XZ-dual permutation proves
dX = dZ. The protocol requires a separate interaction experiment for a combination.

## Hypothesis

* Codes with a verified dual map (all 10 BB codes, GB_144_12_8, GB_144_12_12, TN_36_8_4):
  complementary — the stack solves only the X half *with* its orbit clauses, so it should beat
  GH-85 alone (which solves both symmetric halves).
* Codes without a dual map (LP, PK, xu, other TN): the stack equals GH-85 (detection only,
  milliseconds), up to noise.

## Comparisons (for the coordinator's Tier1/Tier2)

* **Primary:** stack vs GH-85 alone (`cc7e5ea`, frozen `frozen85/cand`, sha256 1c6f028a...).
* **Secondary:** stack vs corrected baseline 72d1fe1 (`frozen73n/base`, sha256 3f2fbc42...).
* Informational: vs GH-87 alone (`frozen87/cand`, 167dd0ce...).
Same harness and gates as GH-85/GH-87 Tier1 (BB_90_8_10, GB_144_12_8, BB_108_8_10,
LP_238_44_6; no-card and card-mto) and Tier2.

## Mechanism

1. Cherry-pick GH-87 `4766d31` (dual-half elimination) and the `src/core/distqldpc.cc` part of
   `783527a` (A1: when the Z half is eliminated, single-half phase 2b caps at U-1 if the X half
   holds the incumbent) onto `cc7e5ea`. Credit GH-87 (idea GH-78-B), GH-85, GH-75, GH-73.
2. Deduplicate the shared GF(2)/candidate helpers (Gf2Basis, RowSupports, append_supports,
   basis_of, permuted_rows_in, SymCandidate, add_candidate, the GH-75 generic candidate family)
   into one copy. GH-85's family (identity excluded) and GH-87's (identity first) are kept
   exactly, in the same order, so both reports and both detections are unchanged.
3. Driver order in `min_distance_css_interleaved`: dual-map detection first (GH-87); if a map
   is verified the Z half is eliminated; then per-half symmetry detection (GH-85) on every
   half still present, i.e. on the X half only when Z was eliminated, on both otherwise. The
   solved half keeps its orbit clauses in every oracle instance.
4. Flags kept: `-no-symbreak`, `-symbreak-report`, `-no-dualskip`, `-dualskip-report`, `-joint`.
   By construction `-no-dualskip` = GH-85 and `-no-symbreak` = GH-87; `-joint` = baseline.

## Soundness argument

Dual elimination (GH-87): a verified pi with pi(rs Hz) = rs Hx and pi(rs[Hz;Gx]) = rs[Hx;Gz]
gives a weight-preserving bijection F_X -> F_Z, so dX = dZ = d and every bound proven on the
X half alone is global. Per-half orbit clauses (GH-85): every verified plain half automorphism
maps F_X onto F_X preserving weight, so for every w the existence of an X-half solution of
weight <= w is unchanged by the clauses; hence every oracle answer (FOUND/NONE/OPT under any
cap, including A1's U-1 cap) of the X half is unchanged in truth value. The X half's optimum,
LB and UB are therefore those of the unconstrained X half, which equal d. The combination is
exact. The XZ-dual map itself is never used as a half automorphism (it is not one).

## Tier0 validation (preregistered; this agent; no timing)

1. Mac build `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"`, no new warnings
   in `distqldpc.cc`; freeze binary at `frozen92/cand/distqldpc` with sha256.
2. `scripts/smoke_test.sh`; `python3 scripts/test_partition_soft_literals.py`;
   `tests/test_partition_soft_literals.cc` oracle (`GH58_PARTITION_ORACLE_PASS cases=80`).
3. Flag equivalence (`-v` traces, byte-identical, cpu limit applied identically on both sides
   when a run is long): `-no-dualskip` vs GH-85 frozen binary and `-no-symbreak` vs GH-87 frozen
   binary on BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6 x {no-card, card-mto};
   default vs GH-85 on LP_238_44_6 and LP_340_56_8 (no dual map): identical apart from the
   single `c dualskip:` line; `-joint -v` vs baseline 72d1fe1 (GH-85/87 cases).
4. Independent checkers: GH-85 `verify_half_autos.py` and GH-87 `check_dual_maps.py` on all 50
   codes (reports from the stacked binary). Any failure = REJECT.
5. Science sweep on the Mac (under the timing lock): GH-60 `tier0_science.py` (unmodified),
   50 codes x {default, no-card, card-mto, card-sinz}, 60 s, vs frozen 72d1fe1; completed
   values equal named/baseline values; every emitted d_lb <= d <= every emitted d_ub; plus the
   post-hoc check that every candidate timeout emits a d_lb. Any unsound result = REJECT.
   TN_648_10_71's named 71 is known wrong (PI escalation): reported, not blamed.
6. QDistSAT cross-repo benchmark on one-commit branch `ci/xrepo-gh92` (candidate tree, parent
   72d1fe1); scientific match must be YES.
