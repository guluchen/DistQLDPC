# GH-195: CC rule `erasure` (erasure bound), opt-in

Issue #195 (hub #15), PR #219. Branch `experiment/gh-195-cc-erasure`, merged with main 02879a93 (charge default, tiebreak,
roworder bfs/auto, sparse rules, stem renames). Measured binary: 8667bc0 (`frozen/server-gh195-8667bc0` on yfclab2);
baseline: frozen main 02879a9. Runs since 2026-11-04 on yfclab2 logical CPUs 120-127 only, one pinned process per CPU,
4 GB cap (`taskset -c N prlimit --as=4294967296`).

## Rule

`-cc-rules=...,erasure` (needs `pack`; default off) and `-cc-erasure-start=N` (default 16384). At a node S whose packing
scan found disjoint odd rows (rows of H, or GH-181 redundant rows) with free candidate sets R_i, let R = union R_i,
E = free qubits outside R, extra = (w - |S|) - p. If extra <= 2 and |R| <= 128, the node is cut unless some y subset of R
and z subset of E with |z| <= extra give H(S + y + z) = 0 and G(S + y + z) != 0. Decision: peeling + dense elimination of
the region columns with labels, exact back-substitution for phi (phi H_R = 0, 64 random lanes) and F (F H_R = G_R), then
singles/pairs z through hash tables (pair table built lazily, n <= 2048). The tests start at the level after the first
level of the half with >= N nodes. With `-cc-roworder=auto` the probe runs the other configuration with the current
erasure state.

Soundness (full proof: MODIFICATIONS.md, GH-195): every other rule keeps a fixed weight-w target e* with S in e* and e*
disjoint from the forbidden set (GH-124/133/138; tiebreak Lemmas A-C of GH-162; xorunit forbids only qubits outside every
such e*). Each packed row is odd in syn(S) and even in syn(e*), so it holds a free qubit of e* \ S in its own R_i; at most
extra qubits of e* \ S lie outside R, so e* solves the relaxation, and the rule cuts only when the relaxation has none
(fingerprint collisions can only stop a cut; labels are exact). The gates are cost-only.

Credit: the erasure bound idea is from Qubitserf 04b9349 (S. Cercelescu, MIT); clean-room implementation.

## Tier 0 (main02879/S0)

- `make test-cc` (8667bc0): PASS. Part U (argv[8]; own RNG stream, the shared stream is saved and restored): 300 random
  halves, 259 200 ladders (128 rule subsets with pack,erasure x 3 seeds x {production gate with phi/F verification, size
  gate 2|S| + 2 <= w}; charge and the bfs order mixed in; 28 800 ladders with GH-181 tokens, 6 278 of them with erasure
  prunes while redundant rows were packed), 0 bad; 122M erasure prunes, 14 376 give-ups. Mutant 25 (bound weakened by one:
  extra - 1 outside qubits) 1370/9600 ladders wrong; mutant 26 (fixed support S ignored) 2204/9600 wrong. Parts B and H
  gained erasure driver configurations, including `-cc-roworder=auto` (forced switch and by time): 0 bad.
- `make test-cc-flags` (8667bc0): PASS, 566 checks.
- Answers (a5be349, before the probe fix; the fix only changes which order the auto probe keeps): 23 tier0-3 codes x 11
  erasure variants (rule subsets, seeds 0-6, dual off, aut off, index seeds, mrv+bfs, auto, finder off, GH-181 tokens,
  default and zero start) = 253 runs, every answer = the stem, max 26 s, 20.6M erasure prunes. Independent GF(2) witness
  check: 145 witnesses ok, 0 bad.
- Byte identity with the token off (tier0+tier1, masked times): vs main 02879a9 all CC and MaxSAT configurations identical
  (one MaxSAT ub-pre timing difference, reproduced base-vs-base); with `tiebreak -cc-roworder=auto` all CC configurations
  identical.

## Tiers 1-4 (5 seeds, medians; main02879/S1/panel_table.md)

Arms: def = main 02879a9 CC default; defer = +erasure; tbra = +tiebreak, -cc-roworder=auto; tbraer = tbra + erasure.

- (a) def -> defer: PASS in every tier (Tier 1 0.996, Tier 2 0.558, Tier 3 0.486, Tier 4 0.432; max cell 1.040).
- (b) tbra -> tbraer: Tiers 2-4 PASS (0.607, 0.600, 0.483; max cell 0.978). Tier 1 geomean exactly 1.000: the rule never
  reaches its start level on LP_340 / LP_442 (0 tests, identical nodes), so the cells are process-floor noise; strictly the
  "geomean < 1" test is not met.

### (a) main default -> +erasure

| Tier | Code | def wall median (range) s | defer wall median (range) s | wall ratio | nodes ratio (median) | search-time ratio (median) | defer erasure calls / prunes (median) | answers |
|---:|---|---|---|---:|---:|---:|---|---|
| 1 | LP_340_56_8 | 0.022 (0.021-0.022) | 0.021 (0.020-0.022) | 0.955 | 1.000 | 0.996 | 0 / 0 | 8 |
| 1 | LP_442_68_10 | 0.025 (0.024-0.033) | 0.026 (0.024-0.033) | 1.040 | 1.000 | 1.020 | 0 / 0 | 10 |
| 2 | BB_144_14_14 | 0.748 (0.728-0.913) | 0.255 (0.254-0.316) | 0.341 | 0.085 | 0.320 | 30075 / 30068 | 14 |
| 2 | BB_288_12_18 | 0.469 (0.449-0.489) | 0.267 (0.256-0.278) | 0.569 | 0.162 | 0.537 | 31943 / 31943 | 18 |
| 2 | GB_144_12_12 | 0.085 (0.075-0.093) | 0.053 (0.042-0.086) | 0.624 | 0.268 | 0.448 | 2181 / 2181 | 12 |
| 2 | LP_544_80_12 | 0.047 (0.045-0.058) | 0.046 (0.043-0.059) | 0.979 | 1.000 | 1.016 | 0 / 0 | 12 |
| 2 | TN_108_2_12 | 2.048 (0.918-2.682) | 0.749 (0.405-0.869) | 0.366 | 0.071 | 0.353 | 130018 / 129744 | 12 |
| 2 | TN_200_10_10 | 0.193 (0.145-0.214) | 0.134 (0.104-0.134) | 0.694 | 0.363 | 0.604 | 10464 / 10463 | 10 |
| 3 | LP_714_100_16 | 0.462 (0.304-0.504) | 0.343 (0.240-0.391) | 0.742 | 0.065 | 0.732 | 34151 / 34137 | 16 |
| 3 | TN_144_2_13 | 5.564 (1.900-7.133) | 1.770 (0.870-2.398) | 0.318 | 0.056 | 0.334 | 251582 / 251580 | 13 |
| 4 | TN_250_10_15 | 65.453 (35.272-66.635) | 28.286 (18.284-28.487) | 0.432 | 0.047 | 0.432 | 4317073 / 4317069 | 15 |

| Tier | cells | geomean wall ratio | max cell | cells > 1.25 | verdict |
|---:|---:|---:|---:|---:|---|
| 1 | 2 | 0.996 | 1.040 | 0 | PASS |
| 2 | 6 | 0.558 | 0.979 | 0 | PASS |
| 3 | 2 | 0.486 | 0.742 | 0 | PASS |
| 4 | 1 | 0.432 | 0.432 | 0 | PASS |

### (b) main default + tiebreak + roworder auto -> + erasure

| Tier | Code | tbra wall median (range) s | tbraer wall median (range) s | wall ratio | nodes ratio (median) | search-time ratio (median) | tbraer erasure calls / prunes (median) | answers |
|---:|---|---|---|---:|---:|---:|---|---|
| 1 | LP_340_56_8 | 0.021 (0.021-0.022) | 0.021 (0.021-0.022) | 1.000 | 1.000 | 1.043 | 0 / 0 | 8 |
| 1 | LP_442_68_10 | 0.033 (0.025-0.034) | 0.033 (0.032-0.034) | 1.000 | 1.000 | 1.067 | 0 / 0 | 10 |
| 2 | BB_144_14_14 | 0.628 (0.618-0.772) | 0.255 (0.244-0.296) | 0.406 | 0.127 | 0.435 | 28492 / 28485 | 14 |
| 2 | BB_288_12_18 | 0.348 (0.328-0.367) | 0.208 (0.197-0.227) | 0.598 | 0.184 | 0.553 | 24237 / 24237 | 18 |
| 2 | GB_144_12_12 | 0.090 (0.084-0.093) | 0.054 (0.053-0.084) | 0.600 | 0.272 | 0.461 | 2097 / 2097 | 12 |
| 2 | LP_544_80_12 | 0.046 (0.045-0.048) | 0.045 (0.045-0.056) | 0.978 | 1.000 | 0.979 | 0 / 0 | 12 |
| 2 | TN_108_2_12 | 1.494 (1.059-1.555) | 0.758 (0.417-0.879) | 0.507 | 0.125 | 0.601 | 130018 / 129744 | 12 |
| 2 | TN_200_10_10 | 0.195 (0.142-0.213) | 0.135 (0.101-0.136) | 0.692 | 0.367 | 0.612 | 10245 / 10244 | 10 |
| 3 | LP_714_100_16 | 0.461 (0.311-0.512) | 0.350 (0.251-0.391) | 0.759 | 0.164 | 0.727 | 29869 / 29855 | 16 |
| 3 | TN_144_2_13 | 3.370 (2.292-3.753) | 1.599 (0.991-1.842) | 0.474 | 0.084 | 0.458 | 167253 / 167244 | 13 |
| 4 | TN_250_10_15 | 28.708 (21.378-30.514) | 13.879 (10.434-16.071) | 0.483 | 0.037 | 0.507 | 2061766 / 2061755 | 15 |

| Tier | cells | geomean wall ratio | max cell | cells > 1.25 | verdict |
|---:|---:|---:|---:|---:|---|
| 1 | 2 | 1.000 | 1.000 | 0 | FAIL |
| 2 | 6 | 0.607 | 0.978 | 0 | PASS |
| 3 | 2 | 0.600 | 0.759 | 0 | PASS |
| 4 | 1 | 0.483 | 0.483 | 0 | PASS |

220 runs, science problems: []
OVERALL FAIL


An earlier panel on a5be349 (auto probe compared A with erasure against B without it) is kept as
`main02879/S1/panel_table_a5be349_probe_without_erasure_state.md`.

## Tier 5 (6 h, default seed; main02879/S2)

Scope (8 CPUs): all four arms on the solved codes BB_360, TN_180, TN_216, TN_252; tbra vs tbraer on BB_756, BB_1080,
TN_288, TN_496; def vs defer on TN_360. Same session, 6 h each. Verdict: PASS (no solved code slower; every solved code
0.44-0.83x). On the unsolved codes the time to the baseline's final lb is 0.61-0.67x on the TN codes and 1.03-1.04x on
BB_756 / BB_1080 (the bfs+mrv order chosen by the auto probe already shrinks the BB trees; erasure cuts nodes 13x there but
the tests cost as much as they save). Final lbs: TN_496 25 (tbra 24) and TN_360 23 (def 22); both are at or below the
current stems (TN_496_2_27to30, TN_360_4_23to24), so no new lower bound. The first tbraer runs on a5be349 (probe without
the erasure state: BB_360 47.9 s vs tbra 31.9 s) are kept as `tier5_results_cand_a5be349_superseded.jsonl`.

### def -> defer

| Code | def | defer | time to the def final value s (ratio) | largest level done by both: nodes (ratio), level s (ratio) |
|---|---|---|---|---|
| BB_360_12_24 | d=24 @ 190 s | d=24 @ 110 s | 190 -> 110 (0.581) | 22 (X -> X): 633.1M -> 24.5M (0.039), 170 -> 98 (0.576) |
| TN_180_2_17 | d=17 @ 156 s | d=17 @ 69 s | 156 -> 69 (0.442) | 16 (X+Z -> X+Z): 188.6M -> 10.3M (0.054), 107 -> 49 (0.454) |
| TN_216_4_18 | d=18 @ 470 s | d=18 @ 236 s | 470 -> 236 (0.501) | 17 (X+Z -> X+Z): 585.0M -> 34.7M (0.059), 330 -> 164 (0.499) |
| TN_252_2_21 | d=21 @ 8568 s | d=21 @ 4514 s | 8568 -> 4514 (0.527) | 20 (X+Z -> X+Z): 9076.2M -> 497.8M (0.055), 6181 -> 3243 (0.525) |
| TN_360_4_23to24 | TIMEOUT lb 22 | TIMEOUT lb 23 | 7521 -> 5016 (0.667) | 22 (X -> X+Z): 11413.2M -> 1518.3M (0.133), 8096 -> 11030 (1.362) |

geomean time to the baseline final value 0.538 (5 codes)

### tbra -> tbraer

| Code | tbra | tbraer | time to the tbra final value s (ratio) | largest level done by both: nodes (ratio), level s (ratio) |
|---|---|---|---|---|
| BB_360_12_24 | d=24 @ 32 s | d=24 @ 26 s | 32 -> 26 (0.827) | 22 (X -> X): 83.4M -> 5.3M (0.063), 27 -> 22 (0.834) |
| BB_756_16_32to34 | TIMEOUT lb 32 | TIMEOUT lb 32 | 12616 -> 12979 (1.029) | 30 (X -> X): 25055.6M -> 1853.8M (0.074), 10478 -> 10760 (1.027) |
| BB_1080_4_32to48 | TIMEOUT lb 32 | TIMEOUT lb 32 | 8499 -> 8833 (1.039) | 30 (X -> X): 16674.8M -> 1297.4M (0.078), 6986 -> 7270 (1.041) |
| TN_180_2_17 | d=17 @ 151 s | d=17 @ 69 s | 151 -> 69 (0.461) | 16 (X+Z -> X+Z): 188.6M -> 10.3M (0.054), 108 -> 49 (0.450) |
| TN_216_4_18 | d=18 @ 395 s | d=18 @ 210 s | 395 -> 210 (0.532) | 17 (X+Z -> X+Z): 437.0M -> 27.5M (0.063), 273 -> 145 (0.530) |
| TN_252_2_21 | d=21 @ 8587 s | d=21 @ 4520 s | 8587 -> 4520 (0.526) | 20 (X+Z -> X+Z): 9076.2M -> 497.8M (0.055), 6193 -> 3237 (0.523) |
| TN_288_2_22to24 | TIMEOUT lb 22 | TIMEOUT lb 22 | 16183 -> 9795 (0.605) | 21 (X+Z -> X+Z): 16726.9M -> 998.1M (0.060), 11354 -> 6918 (0.609) |
| TN_496_2_27to30 | TIMEOUT lb 24 | TIMEOUT lb 25 | 10481 -> 6942 (0.662) | 23 (X -> X): 17317.6M -> 667.4M (0.039), 6912 -> 4512 (0.653) |

geomean time to the baseline final value 0.680 (8 codes)

### Bound events (lb value@seconds, from 18)

| Code | def | defer | tbra | tbraer |
|---|---|---|---|---|
| BB_360_12_24 | 18@0 20@2 22@20 24@190 | 18@0 20@1 22@13 24@110 | 18@0 20@1 22@5 24@32 | 18@0 20@1 22@4 24@26 |
| BB_756_16_32to34 | - | - | 18@0 20@1 22@3 24@12 26@65 28@366 30@2138 32@12616 32@21600 | 18@0 20@1 22@3 24@13 26@71 28@389 30@2219 32@12979 32@21600 |
| BB_1080_4_32to48 | - | - | 18@0 20@1 22@3 24@10 26@49 28@270 30@1512 32@8499 32@21600 | 18@0 20@1 22@2 24@10 26@53 28@281 30@1564 32@8833 32@21600 |
| TN_180_2_17 |  |  |  |  |
| TN_216_4_18 | 18@470 | 18@236 | 18@395 | 18@210 |
| TN_252_2_21 | 18@192 19@676 20@2387 21@8568 | 18@110 19@374 20@1271 21@4514 | 18@194 19@674 20@2394 21@8587 | 18@110 19@375 20@1283 21@4520 |
| TN_288_2_22to24 | - | - | 18@127 19@420 20@1420 21@4829 22@16183 22@21600 | 18@83 19@263 20@863 21@2877 22@9795 22@21600 |
| TN_360_4_23to24 | 18@69 19@216 20@695 21@2269 22@7521 22@21600 | 18@51 19@154 20@485 21@1548 22@5016 23@16046 23@21600 | - | - |
| TN_496_2_27to30 | - | - | 18@17 19@48 20@138 21@403 22@1221 23@3569 24@10481 24@21600 | 18@13 19@37 20@101 21@287 22@852 23@2430 24@6942 25@20291 25@21600 |

science problems: []
TIER5 PASS (no solved code more than 1.2x slower)


## Records on the old base (PR #180 head 3475ff5a, binaries 6d2689e .. af2a56a, cores 44-59)

### Tier 0

- `make test-cc`: PASS (`S0/test_cc.txt`). New Part R (own RNG stream; the shared stream is saved and restored): 300 random
  halves, 230 400 ladders (128 rule subsets with pack,erasure x 3 seeds x {production gate with phi/F verification, size gate
  2|S| + 2 <= w}), 0 bad; 10.4M erasure prunes (211 instances pruned), 3 760 give-ups. Mutant 22 (bound weakened by one:
  extra - 1 outside qubits) 912/9600 ladders wrong; mutant 23 (fixed support S ignored) 1622/9600 wrong. Parts B and H gained
  erasure driver configurations (0 bad).
- `make test-cc-flags`: PASS (439 checks; token values, `-cc-erasure-start`, `-v`/`-cc-stats` lines, mutants 22/23
  accepted, 21/24 rejected, no erasure line without the token).
- Answers: 23 tier0-3 codes x 10 erasure variants (rule subsets, seeds 0-5, dual off, aut off, index seeds, mrv, finder off,
  default and zero start) = 230 runs, every answer = the stem, max 27 s; 20.6M erasure prunes. GF(2) witness check
  (independent script, x in ker H_other, not in rowspan H_same, weight = level): 133 witnesses ok, 0 bad (`S0/`).
- Byte identity with the token off (tier0+tier1, masked times; `S0/identity_*`): vs main 6083e66 all CC and MaxSAT
  configurations identical except one ub-pre timing difference; vs PR #180 (97c8629) with `tiebreak` all identical except one
  ub-search timing difference (both reproduced base-vs-base).

### Pre-panel exploration (`pre/explore_table.md`)

The Qubitserf size gate (2|S| + 2 <= w) is slower than no size gate on every Tier 2-5 code tried (BB_360 61.5 s vs 46.3 s,
TN_250 25.7 vs 15.4 s); a minimum remaining budget gate gave nothing. Two panel iterations were rejected on Tier 1 (process
floor LP codes, 25 ms runs): the eager pair table (6d2689e, LP_442 1.44x) and the lazy table without a start level (dfa26ed,
Tier 1 geomean 1.08 / 1.02); tables in `S1/`.

### Tiers 1-4 (5 seeds, medians; `S1/panel_table.md`)

Arms: main = main 6083e66 CC default; er = +erasure; tb = +tiebreak (= PR #180); tber = +tiebreak,erasure (all with
-cc-stats, seeds 0-4). Verdict: PASS for both baselines in every tier (geomean < 1, no cell > 1.25). Tier 1 (LP_340, LP_442)
never reaches the start level (0 erasure tests; ratios are noise around 1). Where the rule runs, nodes fall 4-50x and wall
time 1.2-5x: BB_144_14_14 0.21, TN_144 0.26-0.28, TN_108 0.32, TN_250 0.41-0.42 (tier 4), BB_288 0.67-0.70, LP_714 0.78-0.81.

#### (a) main default -> +erasure

| Tier | Code | main wall median (range) s | er wall median (range) s | wall ratio | nodes ratio (median) | search-time ratio (median) | er erasure calls / prunes (median) | answers |
|---:|---|---|---|---:|---:|---:|---|---|
| 1 | LP_340_56_8 | 0.023 (0.022-0.023) | 0.022 (0.021-0.023) | 0.957 | 1.000 | 0.849 | 0 / 0 | 8 |
| 1 | LP_442_68_10 | 0.024 (0.023-0.025) | 0.024 (0.023-0.034) | 1.000 | 1.000 | 1.021 | 0 / 0 | 10 |
| 2 | BB_144_14_14 | 1.051 (1.020-1.121) | 0.216 (0.207-0.225) | 0.206 | 0.020 | 0.188 | 35534 / 35501 | 14 |
| 2 | BB_288_12_18 | 0.276 (0.265-0.289) | 0.185 (0.175-0.194) | 0.670 | 0.152 | 0.637 | 32363 / 32363 | 18 |
| 2 | GB_144_12_12 | 0.075 (0.073-0.084) | 0.043 (0.041-0.065) | 0.573 | 0.238 | 0.405 | 2355 / 2355 | 12 |
| 2 | LP_544_80_12 | 0.037 (0.036-0.045) | 0.037 (0.035-0.046) | 1.000 | 1.000 | 0.991 | 0 / 0 | 12 |
| 2 | TN_108_2_12 | 1.967 (0.838-2.704) | 0.638 (0.344-0.748) | 0.324 | 0.039 | 0.315 | 140114 / 139834 | 12 |
| 2 | TN_200_10_10 | 0.152 (0.113-0.175) | 0.094 (0.085-0.104) | 0.618 | 0.134 | 0.549 | 14461 / 14460 | 10 |
| 3 | LP_714_100_16 | 0.369 (0.272-0.421) | 0.300 (0.209-0.341) | 0.813 | 0.054 | 0.763 | 35226 / 35211 | 16 |
| 3 | TN_144_2_13 | 5.828 (1.918-6.615) | 1.505 (0.729-1.776) | 0.258 | 0.021 | 0.266 | 281646 / 281644 | 13 |
| 4 | TN_250_10_15 | 57.639 (32.068-59.580) | 23.603 (15.510-24.366) | 0.409 | 0.028 | 0.413 | 4441793 / 4441789 | 15 |

| Tier | cells | geomean wall ratio | max cell | cells > 1.25 | verdict |
|---:|---:|---:|---:|---:|---|
| 1 | 2 | 0.978 | 1.000 | 0 | PASS |
| 2 | 6 | 0.501 | 1.000 | 0 | PASS |
| 3 | 2 | 0.458 | 0.813 | 0 | PASS |
| 4 | 1 | 0.409 | 0.409 | 0 | PASS |

#### (b) main default + tiebreak -> + tiebreak + erasure

| Tier | Code | tb wall median (range) s | tber wall median (range) s | wall ratio | nodes ratio (median) | search-time ratio (median) | tber erasure calls / prunes (median) | answers |
|---:|---|---|---|---:|---:|---:|---|---|
| 1 | LP_340_56_8 | 0.021 (0.021-0.023) | 0.023 (0.022-0.023) | 1.095 | 1.000 | 0.994 | 0 / 0 | 8 |
| 1 | LP_442_68_10 | 0.031 (0.025-0.033) | 0.025 (0.024-0.032) | 0.806 | 1.000 | 1.019 | 0 / 0 | 10 |
| 2 | BB_144_14_14 | 0.980 (0.959-1.065) | 0.206 (0.205-0.216) | 0.210 | 0.021 | 0.190 | 33528 / 33495 | 14 |
| 2 | BB_288_12_18 | 0.205 (0.196-0.215) | 0.144 (0.142-0.154) | 0.702 | 0.174 | 0.675 | 24529 / 24529 | 18 |
| 2 | GB_144_12_12 | 0.074 (0.071-0.083) | 0.043 (0.043-0.064) | 0.581 | 0.243 | 0.417 | 2262 / 2262 | 12 |
| 2 | LP_544_80_12 | 0.037 (0.036-0.046) | 0.038 (0.037-0.045) | 1.027 | 1.000 | 1.017 | 0 / 0 | 12 |
| 2 | TN_108_2_12 | 1.952 (0.838-2.692) | 0.639 (0.346-0.748) | 0.327 | 0.039 | 0.316 | 140114 / 139834 | 12 |
| 2 | TN_200_10_10 | 0.155 (0.104-0.175) | 0.094 (0.084-0.097) | 0.606 | 0.137 | 0.553 | 14203 / 14202 | 10 |
| 3 | LP_714_100_16 | 0.369 (0.270-0.409) | 0.289 (0.210-0.339) | 0.783 | 0.055 | 0.767 | 34835 / 34820 | 16 |
| 3 | TN_144_2_13 | 5.464 (1.917-6.573) | 1.505 (0.728-1.777) | 0.275 | 0.021 | 0.272 | 281646 / 281644 | 13 |
| 4 | TN_250_10_15 | 53.530 (29.483-56.314) | 22.296 (14.429-23.091) | 0.417 | 0.030 | 0.421 | 4170603 / 4170600 | 15 |

| Tier | cells | geomean wall ratio | max cell | cells > 1.25 | verdict |
|---:|---:|---:|---:|---:|---|
| 1 | 2 | 0.940 | 1.095 | 0 | PASS |
| 2 | 6 | 0.510 | 1.027 | 0 | PASS |
| 3 | 2 | 0.464 | 0.783 | 0 | PASS |
| 4 | 1 | 0.417 | 0.417 | 0 | PASS |

220 runs, science problems: []
OVERALL PASS


### Tier 5 (6 h, default seed; `S2/`)

See `S2/tier5_table.md` (af2a56a, 21 codes, tber vs recorded main and tb runs).
