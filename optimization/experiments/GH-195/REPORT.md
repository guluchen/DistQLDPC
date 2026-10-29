# GH-195: CC rule `erasure` (erasure bound), opt-in

Issue #195 (hub #15). Branch `experiment/gh-195-cc-erasure`, stacked on PR #180 (GH-162 `tiebreak`, head 3475ff5a, base main
6083e662). Measured binary: af2a56a (frozen `frozen/server-gh195-af2a56a` on yfclab2). All runs on yfclab2 cores 44-59, one
pinned process per core, 4 GB cap (`taskset -c N prlimit --as=4294967296`).

## Rule

`-cc-rules=...,erasure` (needs `pack`; default off). At a node S whose packing scan found disjoint odd rows j_1..j_p with
free candidate sets R_i, let R = union R_i, E = free qubits outside R, extra = (w - |S|) - p. If extra <= 2 and |R| <= 128,
the node is cut unless some y subset of R and z subset of E with |z| <= extra give H(S + y + z) = 0 and G(S + y + z) != 0.
Decision: peeling + dense elimination of the region columns with labels, exact back-substitution for phi (phi H_R = 0,
64 random lanes) and F (F H_R = G_R), then singles/pairs z through hash tables (pair table built lazily, n <= 2048).
Tests start at the level after the first level of the half with >= `-cc-erasure-start=N` nodes (default 16384).

Soundness (full proof: MODIFICATIONS.md, GH-195): every other rule keeps a fixed weight-w target e* with S in e* and e*
disjoint from the forbidden set (GH-124/133/138; with tiebreak the lex-least e* of GH-162 Lemmas A-C). Each packed row
is odd in syn(S) and even in syn(e*), so it holds a free qubit of e* \ S in its own R_i: at most extra qubits of e* \ S lie
outside R. So e* is a solution of the relaxation; the rule cuts only when the relaxation has none (fingerprint collisions
can only stop a cut; labels are exact). Gates are cost-only.

Credit: the erasure bound idea is from Qubitserf 04b9349 (S. Cercelescu, MIT); clean-room implementation.

## Tier 0

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

## Pre-panel exploration (`pre/explore_table.md`)

The Qubitserf size gate (2|S| + 2 <= w) is slower than no size gate on every Tier 2-5 code tried (BB_360 61.5 s vs 46.3 s,
TN_250 25.7 vs 15.4 s); a minimum remaining budget gate gave nothing. Two panel iterations were rejected on Tier 1 (process
floor LP codes, 25 ms runs): the eager pair table (6d2689e, LP_442 1.44x) and the lazy table without a start level (dfa26ed,
Tier 1 geomean 1.08 / 1.02); tables in `S1/`.

## Tiers 1-4 (5 seeds, medians; `S1/panel_table.md`)

Arms: main = main 6083e66 CC default; er = +erasure; tb = +tiebreak (= PR #180); tber = +tiebreak,erasure (all with
-cc-stats, seeds 0-4). Verdict: PASS for both baselines in every tier (geomean < 1, no cell > 1.25). Tier 1 (LP_340, LP_442)
never reaches the start level (0 erasure tests; ratios are noise around 1). Where the rule runs, nodes fall 4-50x and wall
time 1.2-5x: BB_144_14_14 0.21, TN_144 0.26-0.28, TN_108 0.32, TN_250 0.41-0.42 (tier 4), BB_288 0.67-0.70, LP_714 0.78-0.81.

### (a) main default -> +erasure

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

### (b) main default + tiebreak -> + tiebreak + erasure

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


## Tier 5 (6 h, default seed; `S2/`)

TIER5_PLACEHOLDER
