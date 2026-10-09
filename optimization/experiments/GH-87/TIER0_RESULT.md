# GH-87 Tier0 result — PASS (correctness only; no timing by this agent)

Registered extension of GH-73 (issue #87, PROPOSAL.md before code, Amendment A1 before any
science result). Baseline 72d1fe1 (corrected). Candidate source `783527a` = 72d1fe1 +
cherry-pick of GH-73 `a1585b4` (`3a60013`, src identical) + GH-87 delta (`4766d31`
dual-half elimination, `783527a` A1 single-half cap U-1; `src/core/distqldpc.cc` only,
+~240 lines; MODIFICATIONS/NOTICE notes). Later commits are records/checkers only.
Superseded `4766d31` evidence is kept (ATTEMPTS.md, `raw/mac-4766d31-superseded/`, hosted record).

| Check | Mac (Apple clang, shim) | yfclab2 (Linux GCC 13.3) |
|---|---|---|
| Build, no new warnings in distqldpc.cc | 32 = GH-73 32 (full build); 0 in distqldpc.cc | 2 in distqldpc.cc, pre-existing `write` unused-result (baseline l.162, GH-73 `pipe_bound`) |
| `scripts/smoke_test.sh` | PASS (`raw/mac/smoke.txt`) | PASS (`raw/linux/regress-linux/`) |
| `scripts/test_partition_soft_literals.py` | PASS (11 adjacent oracles) | PASS |
| `tests/test_partition_soft_literals.cc` (ci.yml compile line) | `GH58_PARTITION_ORACLE_PASS cases=80` | same |
| `-joint -v` vs baseline 72d1fe1 `-v` (LP_34_20_2, BB_72_12_6, TN_36_8_4 x default/no-card) | 6/6 byte-identical | 6/6 byte-identical |
| `-no-dualskip -v` vs GH-73 a1585b4 `-v` (same cases) | 6/6 byte-identical | 6/6 byte-identical |
| default vs GH-73 on a code without dual map (LP_34_20_2) | identical modulo the `c dualskip:` line | same |
| Dual-map reports, independent Python GF(2) checker (`check_dual_maps.py`), 50 codes | ALL_PASS (`raw/mac/dualmaps/`) | ALL_PASS (`raw/linux/dualmaps-linux/`); reports identical to Mac modulo detect_cpu |

## Per-code dual-map findings (all 50 codes; `raw/linux/dualmaps-linux/dual_maps.json`)

Checker: each reported map rebuilt from its description (separate code path), verified as a
permutation with rank(pi Hz) = rank(Hx) = rank([pi Hz; Hx]) and the same for [Hz;Gx] vs
[Hx;Gz]; the whole candidate family re-enumerated independently and the accepted list (in
order) equal to the reported list; ranks equal to the reported ranks. Detection CPU
<= 0.005 s (Mac) / 0.023 s (Linux), largest codes.

**Dual map found (13 codes, Z half eliminated):**
* BB (all 10): `halfswap-inverse Z_l x Z_m` (the half swap with group inverse; BB_72 Z_6xZ_6,
  BB_90 Z_3xZ_15, BB_108 Z_6xZ_9, BB_144_12_12 Z_6xZ_12, BB_144_14_14 Z_12xZ_6, BB_288 Z_12xZ_12,
  BB_360 Z_6xZ_30, BB_756 Z_18xZ_21, BB_864 Z_12xZ_36, BB_1080 Z_18xZ_30) — one map each.
* GB_144_12_8, GB_144_12_12: `halfswap-inverse Z_h` (cyclic group of order 72).
* TN_36_8_4: 4 maps, first `blockshift L=2` (used).

**No dual map (37 codes, behaviour = GH-73):** LP_34/136/238/340/442/544/714/1768, PK_31,
xu_30, xu_42, TN_36_8_3, TN_54_11_4 (ranks differ: Hz 21 vs Hx 22), TN_72_14_4, TN_72_8_8,
TN_108/144/180/200 (ranks differ: 96 vs 94)/216/250/252/288/324/360/396/432/468/496/504/540/
576x2/612/648x2/684. (Ranks of Hz and Hx are equal for all codes except TN_54_11_4 and
TN_200_10_10, so no map exists there at all; for the others the generic family has none.)

## Science sweep (`raw/linux/tier0-science-01/`, yfclab2, correctness only)

Unmodified GH-60 harness copy (`tier0_science.py`, sha256 41ee9dfc...), 50 codes x {default,
no-card, card-mto, card-sinz}, 60 s, `--jobs 4`, 2026-10-09 19:23-20:37 +0800 (re-pinned to
NUMA node 0 mid-run, see ATTEMPTS.md). Baseline `frozen/gh73n/base/distqldpc` (72d1fe1,
b943c2c9...), candidate `frozen/gh87/cand/distqldpc` (783527a, 5a4acda0...).

* **200/200 OK, ALL_OK, 0 problems**: 52 completed by both with identical named distances;
  11 only by the candidate (LP_340_56_8 x4 d=8, TN_108_2_12 x3 d=12, TN_200_10_10 x3 d=10,
  BB_144_12_12 sinz d=12), all equal to named distances; 1 only by the baseline
  (TN_200_10_10 no-card; no dual map there -> GH-73 behaviour, as in GH-85's sweep).
  Every emitted d_lb <= d <= every emitted d_ub.
* All 13 dual-map codes: completed ones (BB_72/90/108, BB_144_12_12, GB_144_12_8, TN_36_8_4,
  all modes) give the named distance, equal to baseline; timeouts have sound bounds
  (e.g. BB_144_14_14 lb 9 / ub 14, GB_144_12_12 lb 9 / ub 15).
* `-v` runs of the amended single-half phase 2b (`raw/linux/dual-v-linux/`): both A1 branches
  exercised — `OPT` below the incumbent (BB_108_8_10: cap 15 -> OPT 10; BB_144_12_12: cap 15 ->
  OPT 12) and `NONE` proving lb = U (BB_90_8_10 cap 9 -> NONE, d=10; GB_144_12_8 cap 7 -> NONE,
  d=8); GB_144_12_12 not finished within 120 s (no result line).
* Post-hoc (`posthoc_science.py`, from GH-85): **137/137 candidate timeouts emitted a d_lb**
  (POSTHOC_PASS), all TIMEOUT / `s UNKNOWN`. Of 136 runs timing out in both, candidate final
  d_lb higher in 131, lower in 5 (all card-sinz on codes WITHOUT a dual map: LP_544, TN_496,
  TN_648_14_50, xu_30, xu_42 — GH-73 split behaviour, not this delta; diagnostic only).
* TN_648_10_71 (named 71 is known-wrong, true d <= 52, PI escalation): no d_ub emitted by either
  version within 60 s (candidate d_lb 9, baseline 4); nothing further to report, name unchanged.
Server walls are not timing evidence.

## Hosted

CI and QDistSAT cross-repo on `ci/xrepo-gh87-a1` (8ab1c09, parent 72d1fe1, candidate tree
783527a): SUCCESS, **scientific match YES** (LP_136_32_4 d=4, BB_108_8_10 d=10, no-card and
card-mto; `raw/hosted/`). The earlier `ci/xrepo-gh87` (6af0176, superseded tree 24b11ee) also
passed; kept as a record (a new branch was used instead of a force push).
Shared-runner times informational only.

## Frozen binaries for the coordinator

`frozen-binaries.sha256`. Mac candidate: `scratch-2026-10-08-ce0ddb/frozen87/cand/distqldpc`
(read-only, sha256 167dd0ce...). Gate vs 72d1fe1 (`frozen73n/base`); GH-73 (`frozen73n/cand`)
and `-no-dualskip` informational for attribution.

Decision: **Tier0 PASS**. State TIER0_PASS / WAITING_FOR_HOST (Tier1/Tier2 by the coordinator).
Risk notes: the delta only acts on the 13 dual-map codes (Tier1: BB_90, GB_144_12_8, BB_108 are
dual; LP_238 is not -> identical to GH-73 there); the eliminated half was a duplicate of the
X half's work only up to search noise, so the gain over GH-73 is bounded by ~2x on those codes
and can be smaller where GH-73's Z half happened to find the incumbent faster; with A1 the
single-half optimisation starts at U-1 (one solver) instead of GH-73's tie-break probe chain.
