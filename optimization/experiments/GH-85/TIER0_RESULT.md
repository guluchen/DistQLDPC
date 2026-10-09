# GH-85 Tier0 result — PASS (correctness only; no timing performed by this agent)

Preregistered interaction experiment GH-73 x GH-75 (issue #85, PROPOSAL.md written before code).
Baseline 72d1fe1 (corrected). Candidate source `cc7e5ea` = 72d1fe1 + cherry-pick of GH-73
`a1585b4` (`cad2c70`, src identical to a1585b4) + GH-85 delta (`src/core/distqldpc.cc` +319/-4,
MODIFICATIONS/NOTICE notes). Later commits are records/checkers only.

| Check | Mac (Apple clang, shim) | yfclab2 (Linux GCC 13.3) |
|---|---|---|
| Build, no new warnings in distqldpc.cc | 34 warnings = baseline 34 | 159; the 2 in distqldpc.cc are pre-existing `write` unused-result (baseline line 162, GH-73 `pipe_bound`) |
| `scripts/smoke_test.sh` | PASS (`raw/mac/smoke.txt`) | PASS (`raw/regress-linux/`) |
| `scripts/test_partition_soft_literals.py` | PASS (11 adjacent oracles) | PASS |
| `tests/test_partition_soft_literals.cc` (ci.yml compile line) | `GH58_PARTITION_ORACLE_PASS cases=80` | same |
| `-joint -v` vs baseline 72d1fe1 `-v` (LP_34_20_2, BB_72_12_6, TN_36_8_4 x default/no-card) | 6/6 byte-identical | 6/6 byte-identical |
| `-no-symbreak -v` vs GH-73 a1585b4 `-v` (same cases) | 6/6 byte-identical | 6/6 byte-identical |
| default vs `-no-symbreak` on codes with no orbit clause (LP_34, TN_36_8_4) | identical modulo `c symbreak` lines | same |
| Per-half automorphisms, independent Python GF(2) checker, 50 codes x 2 halves | ALL_PASS (`raw/mac/automorphisms/`) | ALL_PASS (`raw/automorphisms-linux/`); reports identical to Mac (modulo detect_cpu) |

Mac first attempt had an unquoted-path bug in the helper script (ATTEMPTS.md); rerun clean.

## Per-half orbit structure (all 50 codes; `raw/automorphisms-linux/half_automorphisms.json`)

Checker: every reported generator rebuilt from its description, verified as a permutation with
pi(rs Hpar) = rs Hpar and pi(rs[Hpar;Glog]) = rs[Hpar;Glog]; the whole candidate family
independently re-enumerated and the accepted set compared (equal for every half); orbit
count, representatives and sizes recomputed (equal). Detection <= 0.03 s CPU (LP_1768/xu_42).

* X and Z halves have identical verified generator sets for all 50 codes.
* Half generator sets equal GH-75's *plain* joint generator sets for all 50 codes (`raw/automorphisms-linux/compare_with_gh75.txt`):
  the weaker per-half condition admitted no extra map from the candidate family.
* BB (10 codes), GB_144_12_8, GB_144_12_12: 2 orbits per half (the two l*m blocks), orbit chain.
  GH-75 had a unit clause here only thanks to the XZ-dual "half swap + group inverse", which is
  not a half automorphism and is (correctly) not used.
* LP_136/238/340/442/544/714/1768, PK_31, xu_30, xu_42: 34 orbits per half (block-cyclic), as GH-75.
* TN_108/144/180/216/252/360/396/468/504/612/684, TN_72_8_8: 36 orbits; TN_496_2_32: 16 orbits; as GH-75.
* TN_36_8_4: no half symmetry (GH-75's transitive group came from XZ-dual maps only) -> no clause.
* None found (no clause, encoding identical to GH-73): LP_34_20_2, TN_36_8_3, TN_36_8_4, TN_54_11_4,
  TN_72_14_4, TN_200, TN_250, TN_288, TN_324, TN_432, TN_540, TN_576 x2, TN_648 x2.

## Science sweep (`raw/tier0-science-01/`, yfclab2, correctness only)

Unmodified GH-60 harness copy (`tier0_science.py`, sha256 41ee9dfc...), 50 codes x {default,
no-card, card-mto, card-sinz}, 60 s, `--jobs 6` (<= 6 solver processes, host idle ~75-78%),
2026-10-09 18:17-19:07 +0800. Baseline `frozen/gh73n/base/distqldpc` (72d1fe1, b943c2c9...),
candidate `frozen/gh85/cand/distqldpc` (cc7e5ea, e10e55d2...).

* **200/200 OK, ALL_OK, 0 problems**: 52 completed by both with identical named distances; 17 only
  by the candidate (LP_340_56_8 x4 d=8, LP_442_68_10 x4 d=10, TN_108_2_12 x3 d=12, TN_200_10_10
  x3 d=10, GB_144_12_12 default/mto d=12, BB_144_12_12 sinz d=12), all equal to named distances;
  1 only by the baseline (TN_200_10_10 no-card: no half symmetry there, so this is GH-73's known
  asymmetric-code behaviour, not the clause). Every emitted d_lb <= d <= every emitted d_ub.
* Post-hoc (`posthoc_science.py`, preregistered): **131/131 candidate timeouts emitted a d_lb**
  (POSTHOC_PASS); all TIMEOUT / `s UNKNOWN`. Of 130 runs timing out in both, candidate final d_lb
  is higher in 130, never lower (diagnostic; mostly the split's anytime LB, not attributable here).
* TN_648_10_71 (PI escalation on its named distance): no d_ub emitted by either version within 60 s;
  nothing to report.
Server walls are not timing evidence.

## Hosted

CI and QDistSAT cross-repo on `ci/xrepo-gh85` (6f724e9, parent 72d1fe1, candidate tree d6fcb7d):
SUCCESS, **scientific match YES** (LP_136_32_4 d=4, BB_108_8_10 d=10, no-card and card-mto;
`raw/hosted/`). Shared-runner times informational only.

## Frozen binaries for the coordinator

`frozen-binaries.sha256`. Mac candidate: `scratch-2026-10-08-ce0ddb/frozen85/cand/distqldpc`
(read-only, sha256 1c6f028a...). Gate vs 72d1fe1 (`frozen73n/base`); GH-73 `frozen73n/cand` and
`-no-symbreak` informational for attribution.

Decision: **Tier0 PASS**. State TIER0_PASS / WAITING_FOR_HOST (Tier1/Tier2 by the coordinator).
Risk notes: for BB/GB the per-half clause is a 2-orbit chain (weaker than GH-75's joint unit clause);
the gain over GH-73 must therefore come from LP/PK/xu/TN orbit chains and the BB/GB 2-orbit chain;
the clause perturbs search (#60/#69 swings); 16 codes get no clause (behaviour = GH-73).
