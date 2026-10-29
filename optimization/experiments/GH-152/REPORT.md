# GH-152 report: Tanner-graph automorphism candidates for the CC orbit seeds and the XZ-dual map (`-cc-aut=on`)

Issue: https://github.com/guluchen/DistQLDPC/issues/152 (hub #15).
- Baseline: main `e52d15b` (CC rules `excl,pack,orbf,parity,leaf,overlap`, `-ub-search` with the Stern finder).
- Official timing basis: main `12b3e05` tables. Every comparison below runs old and new arms concurrently in the same
  yfclab2 session, on cores 64-123 only, one process per pinned core, 4 GB cap.
- Candidate: branch `experiment/gh-152-tanner-aut`; evaluated binary `dfd0717`. The S0 node counts used `f3d8244`,
  which yields the same orbits and dual maps on all 51 codes.
- Clean room: written from McKay's published description of individualisation-refinement. No nauty, bliss, Traces
  or other third-party code was read. No external solver was used.

## Summary

| Item | Result |
|---|---|
| What | `-cc-aut=on` (default off). New code in `src/cc/cc_aut.{h,cc}` proposes automorphisms of the coloured Tanner graph (qubits, Hx rows, Hz rows) and one map exchanging the Hx and Hz rows. The automorphisms are added as candidates to `find_half_symmetry`. The swap map is offered to the dual-map check only when the GH-75 family finds no dual map. **Every candidate passes the existing GF(2) checks before use.** The search code, the driver and the MaxSAT path are unchanged. |
| Default path | Byte-identical to main `e52d15b` on the tier0+1 `-v` logs of both engines in the deterministic configurations (90/90: MaxSAT `-ub-pre=off` x 2 modes, CC `-ub-search=off` with and without `-cc-stats`). In the finder-on configurations, 73/75 are identical. The other 2 differ only in a finder progress line, and a second run of the base binary differs from the first in the same way. |
| Symmetry found | Orbits on five open TN codes that had none: TN_288/324/432/540/576 get 36 orbits of size 8-16. A verified dual map on TN_496 and on every LP code. Orbits on TN_200 and TN_250. Nothing new on BB_756/864/1080, TN_648_10/14 or the other open TN codes. Detection takes at most 11 ms. |
| S0 (same level, nodes new/old) | TN_576 0.070, TN_540 0.074, TN_432 0.094, TN_324 0.128, TN_288 0.147, TN_496 0.44, LP_1428 0.29. BB_360, BB_756 and TN_360 stay at 1.000. |
| Tier 0 | PASS: tests, mutants 13/14 detected, flags 346/346, answers 161/161, identity |
| Tier 1 | Panel 1.089, at the process floor. A preregistered repeat (25 interleaved runs per arm on one core) gives **0.999**. PASS, but neutral. |
| Tier 2 / 3 / 4 | **0.914 / 0.807 / 0.536**, max cell 1.123 (TN_144, which runs an identical search). PASS |
| Tier 5 | 54/54 runs clean. **New certified CC lower bounds (PLAUSIBLE) on 6 open codes: TN_288 20->22, TN_324 20->22, TN_432 21->23, TN_496 22->23, TN_540 21->23, TN_576 22->24.** Time to the old final lb is 0.08-0.16x on the five orbit codes and 0.51x on TN_496. Solved LP cells take 0.11-0.47x. All other cells are unchanged (node counts identical, time 0.94-1.05x). |

Scientific semantics changed: no (proof in `MODIFICATIONS.md`, GH-152). PI action required: yes (section 7).

## 1. Proposals and selection

Before writing proposals I took one measurement (`pre/autprobe.py`, `pre/stabprobe.py`, a few seconds per code). For
each code I computed the automorphism group of the coloured Tanner graph, with exhaustive non-orbit proofs.
- The CC engine's GH-75 index-map family misses all symmetry on 5 open TN codes.
- It also misses the XZ duality on TN_496 and on every LP code.
- All point stabilisers are trivial on the open codes. So second-level canonicalisation (Rank 6b in the literature
  note) gains nothing, and I dropped it.

The three proposals:
1. **Selected: Tanner-graph automorphism discovery feeding the orbit seeds and the dual map.**
   - Expected 2.5-5x at the same level on the five TN codes, and 2x on TN_496 and the LP codes.
   - Risk: low. Soundness rests on the existing GF(2) verifiers.
2. Per-logical (lambda-odd) pseudo-check for the k = 2 TN codes.
   - Expected 1-3x, but needs k searches.
   - Risk: medium.
3. Overlap-aware fractional packing bound.
   - Expected 1.2-2x fewer nodes, but each node costs 2-5x more.
   - Risk: medium.

Justification: proposal 1 is the only one whose potential was measured beforehand. It multiplies with every existing
rule, has the lowest correctness risk, and is cheap to test against brute force using hidden symmetries. It cannot
help BB_756/864/1080, TN_648_10/14, or the 7 TN codes that already had orbits.

## 2. Implementation

- `src/cc/cc_aut.{h,cc}`:
  - Builds the coarsest equitable refinement of the type partition (Hopcroft splitter queue; cells are named by their
    start index).
  - Decides the orbit of v0 (the first vertex of the smallest qubit cell) with tests v0 -> w. The source refinement
    is recorded once as a per-splitter hash trace; each target replays it and aborts at the first mismatch. A
    discrete partition gives a vertex map, which is edge-checked. A non-discrete one is resolved by lockstep
    backtracking, to depth at most 64.
  - Propagates refutations along the orbits already found.
  - Reports the group as complete when v0's point stabiliser is trivial and every test was decided.
  - Searches for one class-exchanging (swap) map.
  - Uses deterministic work limits.
- `src/core/distqldpc.cc`:
  - `find_half_symmetry(H, G, extra, trust_extra)`: extra candidates go through the same two GF(2) checks.
  - `verify_dual_perm`: the `find_dual_maps` check for one map. It reuses that function's ranks and bases through the
    new `DualCache`.
  - The `-cc-aut` wrapper logic and the `c cc aut:` lines printed under `-v`.
  - Flag parsing, and test mutants 13 and 14.
- `src/cc/cc_driver.h`: `DriverOptions::aut`.
- Tests:
  - `tests/test_cc_engine.cc`, Parts G and H plus the mutant expectations.
  - `tests/test_cc_flags.sh`, section 5a.
- Documentation: `MODIFICATIONS.md` (rows plus the GH-152 proof) and `README.md`.
- Development history:
  - `f3d8244`: the first version.
  - `b24a2c3`: replay, refutation propagation and pooled partitions. The swap search now runs only without a family
    dual map. This took detection on LP_442 from 106 tests / 5 ms to 10 tests / about 1 ms.
  - `dfd0717`: CSR graph construction.
  - All three give the same orbits and dual maps on all 51 codes.
  - An uncommitted intermediate build had a dangling reference into a reallocating pool. `make test-cc` Part G caught
    it, and it was fixed before `b24a2c3`.

## 3. Symmetry found (`-v`, all 51 codes)

| Codes | GH-75 family | with `-cc-aut=on` |
|---|---|---|
| TN_288 / 324 / 432 / 540 / 576 | none (index seeds) | 36 orbits of 8 / 9 / 12 / 15 / 16 |
| TN_496 | 16 orbits, both halves | same orbits plus a verified swap map (X half only) |
| LP codes (tiers 0-5) | 34 (58) orbits, both halves | same orbits plus a verified swap map; LP_1054 goes to 8 orbits |
| TN_200, TN_250 | none | 100 / 126 orbits |
| BB_288, BB_360 | 2 orbits + dual map | 1 orbit + dual map |
| GB_144 (both) | 2 orbits from rowspace maps | unchanged (the family generators are kept) |
| everything else | - | unchanged |

Independent audit: a separate pure-Python implementation (`S1/orbit_audit_python.txt`) finds the same orbit
partitions on the six codes with new bounds.

## 4. Correctness (Tier 0)

| Check | Result |
|---|---|
| Identity vs `e52d15b`: tier0+1, `-v`, 7 configurations x 15 codes (`S0/identity_tier01.txt`) | All deterministic configurations identical, 90/90. Two timing-only differences, reproduced by base-vs-base runs. |
| `make test-cc`, default parameters (`S0/test_cc_default.txt`) | PASS. Part A: 115 200 ladders. Part B: 2 800 driver runs. Part G: 115 200 ladders on 300 relabelled halves with hidden symmetry. Part H: 1 500 driver runs on 150 relabelled codes (100 hypergraph products with a hidden transpose duality). 0 bad. Mutants 1-14 all detected. |
| Large GH-152 run, `test_cc_engine 0 0 1500 600` (`S0/test_cc_GH_parts_1500_600.txt`) | Part G: 576 000 ladders. Part H: 6 000 driver runs. 0 bad. No generator or swap map violated its row classes. On the 875 halves with a complete group, the planted automorphism was never missed. |
| Mutant 13: Tanner candidates plus the cyclic shift, used without the GF(2) checks | Wrong on 1 408/19 200 and 8 320/96 000 half-level ladders. Driver runs: 182/300 and 752/1 200 wrong or stopped. |
| Mutant 14: swap map (or the identity) used as the dual map without the check | 49/150 and 197/600 driver runs wrong or stopped |
| `make test-cc-flags` | 346/346 |
| Tier 0-3 codes x 7 `-cc-aut=on` variants (`S0/answers_tier0123.jsonl`) | 161/161 answers match the stem |
| Panel, S0, Tier 5 and cross-check runs vs stems | 0 science problems |

## 3b. S0: CC node counts per level

Settings: cores 77-96, `-ub-search=off`, 3600 s, default seed. Table: `S0/s0_table.md`.

| Code | old | new | last level done by both arms: nodes old -> new (ratio), seconds |
|---|---|---|---|
| BB_360_12_24 | d=24 @ 170 s | d=24 @ 170 s | 22: 1.000 |
| BB_756_16_30to34 | lb 28 | lb 28 | 26: 1.000 |
| LP_1428_184_24 | d=24 @ 441 s | d=24 @ 115 s | 22 (X+Z -> X): 0.292 |
| TN_288_2_9to24 | lb 19 | lb 20 | 18: 6804M -> 998M (0.147), 2070 -> 303 s |
| TN_324_4_9to25 | lb 19 | lb 20 | 18: 0.128 |
| TN_360_4_17to24 | lb 21 | lb 21 | 20: 1.000 (control) |
| TN_432_8_9to29 | lb 19 | lb 21 | 18: 0.094 |
| TN_496_2_17to30 | lb 21 | lb 21 | 20 (X+Z -> X): 0.441 |
| TN_540_4_9to34 | lb 19 | lb 22 | 18: 0.074 |
| TN_576_2_9to37 | lb 20 | lb 22 | 19: 0.070 |

The node reduction (7-14x) roughly equals the orbit size, well above the issue's estimate of 2.5-5x.

## 5. Tier 1-4 panel: `-engine=cc` old vs `-cc-aut=on`

Settings: 5 seeds; tiers 1-3 limited to 1800 s, tier 4 to 5000 s. Table: `S1/panel_table.md`; raw data:
`S1/panel_results.jsonl`.

| Tier | Code | old median s | new median s | ratio | nodes new/old |
|---:|---|---:|---:|---:|---:|
| 1 | LP_340_56_8 | 0.038 | 0.043 | 1.132 | 0.501 |
| 1 | LP_442_68_10 | 0.041 | 0.043 | 1.049 | 0.503 |
| 2 | BB_144_14_14 | 1.247 | 1.252 | 1.004 | 1.000 |
| 2 | BB_288_12_18 | 0.336 | 0.336 | 1.000 | 0.999 |
| 2 | GB_144_12_12 | 0.110 | 0.105 | 0.955 | 1.000 |
| 2 | LP_544_80_12 | 0.075 | 0.078 | 1.040 | 0.488 |
| 2 | TN_108_2_12 | 2.226 | 2.239 | 1.006 | 1.000 |
| 2 | TN_200_10_10 | 0.345 | 0.200 | 0.580 | 0.521 |
| 3 | LP_714_100_16 | 0.818 | 0.474 | 0.579 | 0.504 |
| 3 | TN_144_2_13 | 6.018 | 6.760 | 1.123 | 1.000 |
| 4 | TN_250_10_15 | 112.8 | 60.4 | 0.536 | 0.520 |

Geomean of the cell ratios per tier: 1.089 / 0.914 / 0.807 / 0.536. No cell exceeds 1.25.

**Tier 1 repeat (preregistered).** The tier-1 cells sit at the process floor: about 18 ms, of which the search takes
under 4 ms. In this same panel the identical-search cell TN_144 (node ratio 1.000) measured 1.123. So I fixed one
repeat as the basis for the decision: 5 seeds x 5 repetitions, old and new run back to back on one pinned core with
alternating order, median of 25 runs per arm (`S1/runner/tier1_repeat.py`). Result: LP_340 0.993, LP_442 1.005,
geomean **0.999**. A further development measurement (`pre/floor4.py`, 40 interleaved runs) gave 0.993 / 0.996.

Gate decisions:
- Tier 1: PASS (neutral at the process floor).
- Tier 2: PASS (0.914).
- Tier 3: PASS (0.807). TN_144 at 1.123 is on the watch list, although its search is identical.
- Tier 4: PASS (0.536).

## 6. Tier 5

Settings: yfclab2, 6 h, default seed, old and new arms of all 27 codes running concurrently on 54 cores. Data:
`S1/tier5_results.jsonl`, `S1/tier5_logs.tar.gz`; analysis: `S1/runner/analyze_tier5.py`. All 54 runs finished:
none missing, none killed, 0 science problems, every answer equal to its stem.

| Code | old (-engine=cc) | new (-cc-aut=on) | time to old final value: old -> new s (ratio) | largest level done by both: nodes old -> new (ratio), s old -> new (ratio) |
|---|---|---|---|---|
| BB_360_12_24 | d=24 @ 193 s | d=24 @ 194 s | 193 -> 194 (1.005) | 22 (X -> X): 633.1M -> 633.1M (1.000), 171 -> 171 (1.000) |
| BB_756_16_30to34 | TIMEOUT lb 30 | TIMEOUT lb 30 | 18736 -> 18533 (0.989) | 28 (X -> X): 49069.4M -> 49069.4M (1.000), 15785 -> 15897 (1.007) |
| BB_864_4_30to40 | TIMEOUT lb 30 | TIMEOUT lb 30 | 13315 -> 13486 (1.013) | 28 (X -> X): 34698.7M -> 34698.7M (1.000), 11390 -> 11586 (1.017) |
| BB_1080_4_30to48 | TIMEOUT lb 30 | TIMEOUT lb 30 | 16301 -> 16275 (0.998) | 28 (X -> X): 39764.8M -> 39764.8M (1.000), 13786 -> 13609 (0.987) |
| LP_1020_136_16 | d=16 @ 0 s | d=16 @ 0 s | 0 -> 0 (0.548) | - |
| LP_1054_140_20 | d=20 @ 18 s | d=20 @ 2 s | 18 -> 2 (0.107) | 18 (X+Z -> X): 63.8M -> 6.3M (0.099), 16 -> 2 (0.104) |
| LP_1122_148_20 | d=20 @ 16 s | d=20 @ 5 s | 16 -> 5 (0.329) | 18 (X+Z -> X): 53.3M -> 18.2M (0.342), 14 -> 4 (0.324) |
| LP_1428_184_24 | d=24 @ 551 s | d=24 @ 138 s | 551 -> 138 (0.251) | 22 (X+Z -> X): 1543.9M -> 450.9M (0.292), 484 -> 119 (0.245) |
| LP_1768_224_22 | d=22 @ 63 s | d=22 @ 18 s | 63 -> 18 (0.294) | 20 (X+Z -> X): 170.6M -> 43.4M (0.254), 54 -> 13 (0.233) |
| LP_2610_744_16 | d=16 @ 7 s | d=16 @ 3 s | 7 -> 3 (0.468) | 14 (X+Z -> X): 23.1M -> 10.6M (0.457), 6 -> 3 (0.420) |
| TN_180_2_17 | d=17 @ 191 s | d=17 @ 189 s | 191 -> 189 (0.988) | 16 (X+Z -> X+Z): 442.5M -> 442.5M (1.000), 139 -> 136 (0.985) |
| TN_216_4_18 | d=18 @ 583 s | d=18 @ 582 s | 583 -> 582 (0.997) | 17 (X+Z -> X+Z): 1287.0M -> 1287.0M (1.000), 412 -> 411 (0.998) |
| TN_252_2_21 | d=21 @ 11204 s | d=21 @ 11413 s | 11204 -> 11413 (1.019) | 20 (X+Z -> X+Z): 22378.6M -> 22378.6M (1.000), 7839 -> 8236 (1.051) |
| TN_288_2_9to24 | TIMEOUT lb 20 | TIMEOUT lb 22 | 11808 -> 1868 (0.158) | 19 (X+Z -> X+Z): 22725.0M -> 3398.0M (0.150), 8016 -> 1364 (0.170) |
| TN_324_4_9to25 | TIMEOUT lb 20 | TIMEOUT lb 22 | 10323 -> 1480 (0.143) | 20 (Z -> X+Z): 22185.5M -> 8572.7M (0.386), 7689 -> 3208 (0.417) |
| TN_360_4_17to24 | TIMEOUT lb 22 | TIMEOUT lb 22 | 9709 -> 9520 (0.981) | 22 (X -> X): 27621.6M -> 27621.6M (1.000), 11123 -> 10803 (0.971) |
| TN_396_4_17to26 | TIMEOUT lb 22 | TIMEOUT lb 22 | 9544 -> 9651 (1.011) | 22 (Z -> Z): 14138.1M -> 14138.1M (1.000), 5127 -> 5156 (1.006) |
| TN_432_8_9to29 | TIMEOUT lb 21 | TIMEOUT lb 23 | 16517 -> 1843 (0.112) | 20 (X+Z -> X+Z): 27932.1M -> 2710.3M (0.097), 10924 -> 1286 (0.118) |
| TN_468_4_17to29 | TIMEOUT lb 23 | TIMEOUT lb 23 | 21275 -> 20771 (0.976) | 22 (X+Z -> X+Z): 36582.8M -> 36582.8M (1.000), 14432 -> 13843 (0.959) |
| TN_496_2_17to30 | TIMEOUT lb 22 | TIMEOUT lb 23 | 11517 -> 5827 (0.506) | 22 (X -> X): 26543.9M -> 26543.9M (1.000), 9396 -> 10992 (1.170) |
| TN_504_2_17to34 | TIMEOUT lb 23 | TIMEOUT lb 23 | 9674 -> 9684 (1.001) | 23 (Z -> Z): 22560.4M -> 22560.4M (1.000), 9615 -> 9632 (1.002) |
| TN_540_4_9to34 | TIMEOUT lb 21 | TIMEOUT lb 23 | 14250 -> 1176 (0.083) | 20 (X+Z -> X+Z): 23414.5M -> 1794.9M (0.077), 9253 -> 836 (0.090) |
| TN_576_2_9to37 | TIMEOUT lb 22 | TIMEOUT lb 24 | 20839 -> 1633 (0.078) | 21 (X+Z -> X+Z): 33346.2M -> 2417.0M (0.072), 13403 -> 1131 (0.084) |
| TN_612_2_17to40 | TIMEOUT lb 24 | TIMEOUT lb 24 | 18122 -> 17416 (0.961) | 23 (X+Z -> X+Z): 27020.4M -> 27020.4M (1.000), 11965 -> 11458 (0.958) |
| TN_648_10_9to32 | TIMEOUT lb 21 | TIMEOUT lb 21 | 9106 -> 9077 (0.997) | 21 (Z -> Z): 15342.0M -> 15342.0M (1.000), 6317 -> 6300 (0.997) |
| TN_648_14_9to28 | TIMEOUT lb 21 | TIMEOUT lb 21 | 10576 -> 9942 (0.940) | 21 (Z -> Z): 18684.8M -> 18684.8M (1.000), 7425 -> 7676 (1.034) |
| TN_684_2_9to29 | TIMEOUT lb 22 | TIMEOUT lb 22 | 13344 -> 13479 (1.010) | 21 (X+Z -> X+Z): 24401.1M -> 24401.1M (1.000), 8802 -> 8781 (0.998) |

geomean over codes of the largest level done by both (levels > 1 s): nodes 0.517, time 0.527 (26 codes)

Bound events (lb value@seconds, from 18) where the final value changed:

| Code | old | new |
|---|---|---|
| TN_288_2_9to24 | 18@1171 19@3791 20@11808 20@21600 | 18@154 19@504 20@1868 21@6116 22@20888 22@21600 |
| TN_324_4_9to25 | 18@1090 19@3372 20@10323 20@21600 | 18@127 19@402 20@1480 21@4688 22@15034 22@21600 |
| TN_432_8_9to29 | 18@552 19@1840 20@5592 21@16517 21@21600 | 18@67 19@211 20@556 21@1843 22@5874 23@17206 23@21600 |
| TN_496_2_17to30 | 18@142 19@427 20@1482 21@4149 22@11517 22@21600 | 18@74 19@216 20@653 21@2010 22@5827 23@16819 23@21600 |
| TN_540_4_9to34 | 18@529 19@1764 20@4997 21@14250 21@21600 | 18@37 19@111 20@340 21@1176 22@3474 23@10757 23@21600 |
| TN_576_2_9to37 | 18@293 19@890 20@2593 21@7436 22@20839 22@21600 | 18@20 19@58 20@170 21@502 22@1633 23@4878 24@14303 24@21600 |

54 runs, science problems: []

Cross-checks (relabelled seeds, new arm):

| run | result | lb events |
|---|---|---|
| x5.TN_540_4_9to34.new.s1 | TIMEOUT lb 21 | 18@267 19@953 20@3169 21@10541 21@21600 |
| x5.TN_432_8_9to29.new.s1 | TIMEOUT lb 21 | 18@364 19@1427 20@4902 21@17437 21@21600 |
| x5.TN_576_2_9to37.new.s1 | TIMEOUT lb 22 | 18@135 19@482 20@1921 21@6093 22@18808 22@21600 |
| x5.TN_324_4_9to25.new.s1 | TIMEOUT lb 20 | 18@771 19@2978 20@10696 20@21600 |
| x5.TN_288_2_9to24.new.s1 | TIMEOUT lb 20 | 18@1057 19@3694 20@13260 20@21600 |
| x5.TN_496_2_17to30.new.s1 | TIMEOUT lb 21 | 18@378 19@1609 20@5425 21@17503 21@21600 |


### 6.1 Cross-checks of the new lower bounds

- Relabelled seed 1, new arm, 6 h, run concurrently on cores 120-123, 72 and 74. Results: `S1/xcheck_results.jsonl`,
  listed at the end of the table above. These runs did **not** reach the new bounds. They stopped at TN_288 20,
  TN_324 20, TN_432 21, TN_496 21, TN_540 21 and TN_576 22. Every level they finished was EMPTY, which is consistent
  with the default-seed run (no contradiction).
- Short control, to find out why: old vs new arm, both at seed 1, `-ub-search=off`, 1800 s, cores 64-75.
  Results: `S1/seed1short_table.md`.

| Code | old | new | level: nodes old -> new (ratio), seconds old -> new (last three levels done by both arms) |
|---|---|---|---|
| TN_288_2_9to24 | TIMEOUT lb 17 | TIMEOUT lb 18 | 14 (X+Z->X+Z): 249.81M -> 34.21M (0.137), 69.9 -> 9.6 s; 15 (X+Z->X+Z): 886.36M -> 123.75M (0.140), 257.1 -> 36.0 s; 16 (X+Z->X+Z): 3198.83M -> 455.13M (0.142), 963.1 -> 136.9 s |
| TN_324_4_9to25 | TIMEOUT lb 17 | TIMEOUT lb 18 | 14 (X+Z->X+Z): 268.60M -> 35.01M (0.130), 74.1 -> 9.6 s; 15 (X+Z->X+Z): 917.37M -> 121.31M (0.132), 261.7 -> 34.6 s; 16 (X+Z->X+Z): 3187.01M -> 427.32M (0.134), 945.7 -> 125.9 s |
| TN_432_8_9to29 | TIMEOUT lb 17 | TIMEOUT lb 19 | 14 (X+Z->X+Z): 169.43M -> 17.11M (0.101), 49.4 -> 5.0 s; 15 (X+Z->X+Z): 561.85M -> 57.26M (0.102), 169.7 -> 17.5 s; 16 (X+Z->X+Z): 1897.84M -> 195.15M (0.103), 594.9 -> 61.6 s |
| TN_496_2_17to30 | TIMEOUT lb 18 | TIMEOUT lb 19 | 16 (X+Z->X): 453.40M -> 219.15M (0.483), 132.0 -> 63.8 s; 17 (X+Z->X): 1562.24M -> 751.81M (0.481), 467.9 -> 225.5 s; 18 (X->X): 2608.85M -> 2608.85M (1.000), 809.5 -> 806.8 s |
| TN_540_4_9to34 | TIMEOUT lb 17 | TIMEOUT lb 19 | 15 (X+Z->X+Z): 510.84M -> 40.71M (0.080), 157.1 -> 12.6 s; 16 (X+Z->X+Z): 1651.88M -> 133.11M (0.081), 524.8 -> 42.3 s; 17 (Z->X+Z): 2598.42M -> 442.14M (0.170), 864.8 -> 145.4 s |
| TN_576_2_9to37 | TIMEOUT lb 18 | TIMEOUT lb 20 | 15 (X+Z->X+Z): 338.17M -> 22.22M (0.066), 106.5 -> 7.0 s; 16 (X+Z->X+Z): 1061.86M -> 70.61M (0.066), 346.8 -> 23.2 s; 17 (X+Z->X+Z): 3390.59M -> 228.03M (0.067), 1156.9 -> 78.0 s |


Relabelling slows both arms by the same factor: the old arm reaches lb 17-18 in 30 min with seed 1, against 18-20
with seed 0 (the same level costs 5-7x more, e.g. TN_288 level 16: 185 s vs 963 s; TN_576 level 17: 163 s vs 1157 s). The new/old node ratio at equal levels stays 0.066-0.14, the same as with the default labelling. So the
seed-1 runs fall short of the new bounds because of the labelling (both arms are slower), not because of the
feature. The default labels give a much cheaper CC search on these codes for both arms.

**Status of the new bounds: PLAUSIBLE.**
- Each bound comes from one run (default seed). A run with a different labelling has not yet reproduced the deciding
  level. The deciding levels cost 1.1-3.0 h even with the new orbits (for example, TN_576 level 23: 4878 -> 14303 s).
- Each bound rests on the canonical CC search plus orbit seeds from generators that are GF(2)-verified. The orbit
  partitions are independently reproduced by the separate Python implementation.
- Stems are not renamed. The current stems (TN_288_2_9to24 and so on) still carry old lb fields that are lower than
  even the old CC records.

| Code | CC lb before (GH-138/146 records, this run's old arm) | new CC lb (6 h) | verified ub (stem) |
|---|---:|---:|---:|
| TN_288_2_9to24 | 20 | **22** | 24 |
| TN_324_4_9to25 | 20 | **22** | 25 |
| TN_432_8_9to29 | 21 | **23** | 29 |
| TN_496_2_17to30 | 22 | **23** | 30 |
| TN_540_4_9to34 | 21 | **23** | 34 |
| TN_576_2_9to37 | 22 | **24** | 37 |

No other open cell changed. BB_756/864/1080 stay at 30 (node counts identical; level 30 is not reached). TN_360,
TN_396, TN_468, TN_504, TN_612, TN_648_10, TN_648_14 and TN_684 have identical searches.

## 7. Verdicts and PI decisions

| Gate | Verdict |
|---|---|
| Tier 0 | PASS |
| Tier 1 | PASS on the preregistered repeat (0.999; the first panel gave 1.089 at the process floor); neutral |
| Tier 2 | PASS (0.914) |
| Tier 3 | PASS (0.807) |
| Tier 4 | PASS (0.536) |
| Tier 5 | PASS. No cell lost a bound or got slower beyond noise (unchanged searches 0.94-1.05x; TN_496 at its common level 22 took 1.17x with identical nodes, which is load). Six open TN codes each gained 1-2 certified levels. LP cells solve 2-9x sooner. |

PI decisions needed:
1. Adopt `-cc-aut=on` as the CC default? (`-engine=cc` itself stays optional.) It is neutral where nothing new is
   found and gives 2-14x where it is. Alternatively, also use the generators in the MaxSAT path's GH-85 orbit clauses
   (not tested here).
2. Record the six new CC lower bounds (TN_288 >= 22, TN_324 >= 22, TN_432 >= 23, TN_496 >= 23, TN_540 >= 23,
   TN_576 >= 24) as PLAUSIBLE? Should a relabelled reproduction be run first? That needs about 6-12 h per code with
   the default labels' cost profile, or a certification track. The same question applies to renaming the stems.
3. The large labelling sensitivity of the CC search (seed 1 is 5-7x slower per level for both arms on these TN codes) suggests a
   cheap next lever: choosing a good qubit order.
4. Next round for the codes this does not help (BB_756/864/1080, TN_648_x, and the 7 TN codes that already had
   orbits): proposal 3 (a stronger packing bound), or the multi-core decision.

Scientific semantics changed: no. Escalation: the six new lower bounds are scientific claims; they are PLAUSIBLE and
await PI review.

## 8. Reproduction

- Build:
  - yfclab2: `make clean && make -j8`.
  - Mac: `make CXX="c++ -Wno-reserved-user-defined-literal"`.
- Tests:
  - `make test-cc`
  - `make test-cc-flags`
  - `./build/test_cc_engine 0 0 1500 600`
- Identity check: `python3 -I S0/ident.py MAIN CAND OUT CORE`.
- Jobs: `S1/runner/make_jobs.py panel|tier5|s0|answers|xcheck`.
- Runner: `S1/runner/queue.py --bin BIN --cpus LIST --jobs J --out D` (cores 64-123 only, `taskset` + `prlimit
  --as=4294967296`, stdin `/dev/null`).
- Tier 1 repeat: `S1/runner/tier1_repeat.py`.
- Tables: `S0/analyze_s0.py`, `S1/runner/analyze_panel.py`, `S1/runner/analyze_tier5.py`.
- Measurement scripts: `pre/autprobe.py`, `pre/stabprobe.py`, `pre/floor4.py`.
- Server (`~/mac-agent-20261009`):
  - Worktree: `gh152-dfd0717`.
  - Binaries: `frozen/server-gh152-dfd0717/distqldpc` (sha256 802729d7...) and `frozen/server-main-e52d15b/distqldpc`
    (92bc16bc...).
  - Raw runs: `gh152-runs/v3/` and `gh152-runs/s0/`.
