# GH-157 report: fractional-charge and edge-cover node lower bounds for the CC engine (`charge`, `ecover`)

Issue: https://github.com/guluchen/DistQLDPC/issues/157 (hub #15). PI approval of the round: 2026-10-29 (Candidate 1 of the
CC literature note, "fractional charge / matching / Gallai node lower bounds").
- Baseline: main `123011df` (its CC code is identical to `e52d15b`; CC rules `excl,pack,orbf,parity,leaf,overlap`,
  `-ub-search` with the Stern finder).
- Candidate: branch `experiment/gh-157-cc-charge`. Evaluated binaries: `c3c315d` (Tier 0 tests, panel 1, Tier 5) and
  `06026be` (final; adds only the `-cc-lb-auto` switch-off, so `06026be -cc-lb-auto=0` runs the same search as `c3c315d`).
  Candidate configuration: `-engine=cc -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge` (tuning defaults
  `-cc-lb-minr=3 -cc-lb-gap=0 -cc-lb-raise=on -cc-lb-auto=40`).
- The same source on top of GH-152 (`-cc-aut`, PR #155, not merged): branch `experiment/gh-157-cc-charge-aut` (`ea12971`,
  final `13f1253`), compared with the GH-152 binary `4a05225`, `-cc-aut=on` on both sides.
- All timing on yfclab2, cores 24-63 only, one process per pinned core, 4 GB cap (`taskset -c N prlimit --as=4294967296`),
  binaries frozen under `/home/yfc/mac-agent-20261009/frozen/`. Nothing was timed on the Mac. No external solver was used.
- Clean room: written from the published mathematics only (Banfi, Ferrari, Favano, Tarable, Barletta, arXiv:2610.28008;
  Okada and Kasai, `cpm-ldpc-distance` verification README; Gallai's theorem; Edmonds' blossom algorithm). No third-party
  code was read. Credits in NOTICE and MODIFICATIONS.md.

## Summary

| Item | Result |
|---|---|
| What | Two new CC rules, both **off by default**: `charge` (a feasible dual of the hitting-set LP: local-degree charge plus a greedy raise, exact integers) and `ecover` (Gallai edge cover on a greedy 2-packing of the odd rows, Edmonds matching). Evaluated only after the packing failed, at remaining budget >= 3, \|U\| > budget, and where the packing is exactly at the limit (gap gate); switched off per half when fewer than 40 % of the evaluations of a level (>= 100 000) prune. Recommended configuration: `-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge`. |
| Default path | Byte-identical to main `123011d` (deterministic tier0+1 `-v` logs 60/60, CC default 15/15, MaxSAT default 28/30 with 2 finder-timing lines) |
| Tier 0 | PASS: `make test-cc` (new Part I: bounds vs brute-force tau, Edmonds vs brute force, 345 600 ladders with the new rules, 0 bad), mutants 15/16 caught, flags 369/369, 135/135 witnesses independently GF(2)-verified |
| Node reduction (S0, same level) | TN family 2.2-2.8x fewer nodes (TN_144 0.44, TN_180 0.44, TN_216 0.46, TN_108 0.57), BB_144 0.29, GB_144_12_12 0.40, TN_250 0.61; BB_288 0.82, LP_714 0.78, TN_200 0.83 |
| Time (S0, serial) | TN_180 0.65, TN_144 0.78, TN_216 0.83, BB_144 0.59, GB 0.77, TN_250 0.97, TN_108 0.98, LP_714 0.99; BB_288 1.13, TN_200 1.17 |
| Tier 1 | floor repeat 1.000 / 1.012 (main pair / `-cc-aut` pair; panel 0.950 / 1.102): neutral at the process floor, strictly not < 1 |
| Tier 2 / 3 / 4 | **0.889 / 0.925 / 0.946** (`-cc-aut` pair 0.919 / 0.911 / 0.975), max cell 1.105 (BB_288) / 1.133 (TN_200, `-cc-aut`): PASS |
| Tier 5 | 39/39 clean. **New CC lower bounds (PLAUSIBLE, one run each): TN_360 22->23 (verified ub 24), TN_396 22->23, TN_504 23->24, TN_648_10 21->22.** TN_252 solved in 7 319 s (main control 10 214 s). Time to the old CC values on the TN codes 0.65-0.85x of GH-152's main arm (about 0.72-0.80x of this session's main controls); with `-cc-aut=on` 0.65-0.79x of GH-152's `-cc-aut` arm, no further level. BB and LP unchanged in value. |

Scientific semantics changed: no (proof in `MODIFICATIONS.md`, GH-157). PI action required: yes (section 8).

## 1. Proposals and selection

The issue lists three proposals:
1. **`charge`**: a feasible dual of the hitting-set LP at each node (local-degree charge y_u = 1 / max c_j, then a greedy
   raise), compared exactly in integers.
2. **`ecover`**: Gallai's edge cover on a greedy "2-packing" U' of the odd rows (every available qubit in at most 2 rows
   of U'); exact (= tau) when every available qubit touches at most 2 odd rows. Okada-Kasai's a + b - s is the special
   case of two check classes; the at-most-2 condition is checked per node instead of being asserted per code family.
3. Exact tau* by LP or Lagrangian: not selected (an LP per node; the Lagrangian converges more slowly than 1-2).

The literature note's "packing plus fractional fill" is always zero on top of a *maximal* greedy packing (every unpacked
odd row meets a packed row, whose qubits have no residual capacity), so the raise starts from the local-degree charge.
1 and 2 were implemented as independent rules; the optional per-class matching bound needs no separate code.

## 2. Implementation

- `src/cc/cc_half.{h,cc}`:
  - `lb_charge` / `lb_charge_counted`: local-degree charge with early exit once the sum exceeds the remaining budget r,
    then the raise (optional, `-cc-lb-raise`). Integers scaled by L = lcm(1..D), D = max c_j <= 32 (idle above).
  - `lb_ecover` and `max_matching` (Edmonds' blossom algorithm; stops once the matching reaches |U'| - r; the exits
    |U'| <= r and |U'| - floor(|U'|/2) > r decide without the matching).
  - In `dfs`, after the pack scan: the odd rows' candidate sets are copied once (c_j counted on the way) and passed to
    the tested functions above. Gates, each of which only skips a sound prune: r >= `-cc-lb-minr` (3), |U| > r,
    r - p <= `-cc-lb-gap` (0; p = the node's greedy packing), and the per-half switch-off `-cc-lb-auto=P` (40: after an
    EMPTY level with >= 100 000 evaluations of which fewer than P % pruned, the bounds stay off for the rest of the half).
  - Test mutants 15 (charge inflated by 1/D) and 16 (ecover without the at-most-2 condition); 13 and 14 are left to GH-152.
- `src/cc/cc_driver.{h,cc}`, `src/core/distqldpc.cc`: rule names `charge` and `ecover` in `-cc-rules` (off by default);
  flags `-cc-lb-minr`, `-cc-lb-gap`, `-cc-lb-raise`, `-cc-lb-auto`; `-cc-stats` lines `lb lbeval/chgprune/ecprune/ecexact/
  lbdead` and `lbprune-by-budget` per level (next to GH-124's `nodes-by-budget`), printed only when a new rule is on; `-v`
  lines for the configuration and for a switch-off.
- Tests: `tests/test_cc_engine.cc` Part I; `tests/test_cc_flags.sh` section 7b'.
- Documentation: `MODIFICATIONS.md` (GH-157 proof), `NOTICE`, `README.md`.

### Development history (evidence in `dev/` and `S0/`)

Per-node cost decided everything. Main spends 220-280 ns per CC node, and one evaluation of a bound costs several nodes'
worth, so most of the work went into evaluating less often and more cheaply. All versions gave identical answers.

| Version | Change | Measured effect (single runs, ratio to main) |
|---|---|---|
| `3a81c88` | CSR copy, charge with raise, two-phase ecover; evaluated at every node with r >= 3 and \|U\| > r | nodes / time: TN_144 0.35 / 0.90, TN_250 0.58 / 1.15, BB_144 0.18 / 0.56. Part I(a) then found ecover's cheap exit inverted (it never pruned without the matching) |
| `d5f62f7` | fixed; charge on the search state, counting fused into the pack scan | slower (TN_144 1.18): the counting also ran at nodes the packing then pruned |
| `7eda9c2` | c_j kept incrementally in `toggle` | slower (TN_250 1.47, TN_108 1.78): about 40 counter updates per toggle |
| `2ceeb6a` | ecover's U' selected inside the pack scan; charge on demand | ecover 1.4-1.9 (selection paid at every candidate node) |
| `4377b8d` | **gap gate** r - p <= G | `dev/gap_histogram.txt`: 76-99 % of all prunes occur at r = p, where 25-82 % of the evaluations prune, against 1-51 % at r = p + 1 |
| `ad29e03`, `c3c315d` | the search calls the tested `lb_charge` / `lb_ecover` on one copy of the sets, counting while copying | section 4 |
| `06026be` | `-cc-lb-auto=40` | BB and LP halves (prune rate 15-41 %) switch off; TN halves with >= 40 % keep the bounds |

## 3. Correctness (Tier 0)

| Check | Result |
|---|---|
| `make test-cc`, `c3c315d`, server (`S0/tier0_tests_c3c315d.txt`) | PASS. Part I(a): 20 000 random hitting-set instances against brute-force tau, 0 bad (charge = tau on 15 739, ecover = tau on 15 707; above pack on 4 780 / 3 957); Edmonds against brute-force matching on 20 000 random multigraphs, 0 bad. Part I(b): 345 600 half ladders (128 base rule subsets x {charge, ecover, both} x seeds 0-2 with minr 1/2/3, gap unlimited/0/1), 0 bad. Parts A-F unchanged and clean (Part A 115 200 ladders, Part B 3 600 driver runs including 4 new configurations). The final `06026be` (seed-1 ladders exercise the auto switch-off at 60 % after any level, seed-2 ladders run without the raise) passes the full suite on the server too (`S0/tier0_tests_06026be.txt`: Part I(b) 345 600 ladders, 0 bad). |
| Mutant 15 (charge inflated by 1/D) | exceeds tau on 17 240 / 20 000 instances; 3 680 / 38 400 (`c3c315d`) and 3 808 / 38 400 (`06026be`) half ladders wrong; with the binary, BB_72_12_6, BB_90_8_10 and TN_72_8_8 stop without an answer (driver trap) |
| Mutant 16 (ecover without the at-most-2 condition) | exceeds tau on 8 014 / 20 000 instances; 2 256 / 38 400 half ladders wrong |
| Mutants 1-12 | all detected, unchanged |
| `make test-cc-flags` | 357 / 357 (`c3c315d`), 369 / 369 (`06026be`) |
| Rules off: identity with main `123011d`, tier0+1 `-v` logs (`S0/identity_tier01.txt`, `S0/ident.py` from GH-152) | deterministic configurations 60 / 60 identical (MaxSAT `-ub-pre=off` x 2 modes, CC `-ub-search=off` with and without `-cc-stats`); CC default 15 / 15 identical; MaxSAT default 28 / 30 identical, the other 2 differ only in a `ub-pre` progress line (the finder is time-sliced; the same difference appears base vs base) |
| Witnesses | every FOUND witness is verified inside the driver (`verify_in_half`, an independent GF(2) rank test; a failure stops the run); 0 traps in all panel, S0 and Tier 5 runs. Independent pure-Python GF(2) check (`S1/runner/check_witnesses.py`: x in ker H_other and x not in rowspace H_same) of every witness printed by the `-v` runs: 108 / 108 (panel 2) and 27 / 27 (serial Tier 5 runs) verified |
| Answers | every answer equals its stem; every lower bound <= the stem's upper value (runner science check: 0 problems in the 392 runner jobs: panel 1 and 2, S0, Tier 5 and its serial check) |

## 4. S0: node counts per level (`S0/s0_table.md`, `S0/s0_results.jsonl`)

`-ub-search=off`, default seed; all 44 runs serial on core 63. "top levels" are main's three most expensive levels;
ratios are arm / main for nodes and search time. Arms: `cand` = `charge` (gap 0), `gapinf` = `charge` without the gap
gate, `ecover` alone, `both` = `charge,ecover`. (The TN_250 `ecover` and `both` times are void: a build ran on the same
core during those two runs; their node counts are valid.)

| Code | arm | wall s (ratio) | total nodes (ratio) | top levels: nodes ratio / time ratio | evaluations, prune rate (top level) |
|---|---|---|---|---|---|
| GB_144_12_12 | main | 0.20 | 0.85M | X10: 0.05M 0.01s, X11: 0.22M 0.04s, X12: 0.56M 0.12s | |
| | cand | 0.15 (0.766) | 0.34M (0.402) | X10: 0.426 / 0.750, X11: 0.411 / 0.732, X12: 0.394 / 0.712 | X12: 0.05M, 0.73 |
| | gapinf | 0.15 (0.726) | 0.28M (0.335) | X10: 0.376 / 0.796, X11: 0.346 / 0.751, X12: 0.324 / 0.721 | X12: 0.06M, 0.56 |
| | ecover | 0.18 (0.876) | 0.34M (0.399) | X10: 0.420 / 0.945, X11: 0.408 / 0.912, X12: 0.392 / 0.880 | X12: 0.05M, 0.73 |
| | both | 0.16 (0.781) | 0.32M (0.380) | X10: 0.406 / 0.811, X11: 0.389 / 0.792, X12: 0.372 / 0.761 | X12: 0.05M, 0.76 |
| TN_200_10_10 | main | 0.19 | 0.71M | X8: 0.09M 0.02s, X9: 0.28M 0.07s, Z9: 0.20M 0.05s | |
| | cand | 0.23 (1.170) | 0.59M (0.826) | X8: 0.879 / 1.245, X9: 0.843 / 1.200, Z9: 0.767 / 1.152 | X9: 0.03M, 0.23 |
| | gapinf | 0.25 (1.278) | 0.58M (0.819) | X8: 0.875 / 1.373, X9: 0.838 / 1.337, Z9: 0.754 / 1.293 | X9: 0.05M, 0.16 |
| | ecover | 0.25 (1.278) | 0.62M (0.864) | X8: 0.920 / 1.366, X9: 0.896 / 1.342, Z9: 0.793 / 1.279 | X9: 0.03M, 0.15 |
| | both | 0.26 (1.330) | 0.58M (0.820) | X8: 0.876 / 1.422, X9: 0.839 / 1.382, Z9: 0.757 / 1.310 | X9: 0.03M, 0.23 |
| BB_288_12_18 | main | 0.27 | 1.25M | X12: 0.01M 0.00s, X14: 0.13M 0.02s, X16: 1.11M 0.23s | |
| | cand | 0.31 (1.128) | 1.02M (0.820) | X12: 0.876 / 1.148, X14: 0.845 / 1.107, X16: 0.817 / 1.096 | X16: 0.14M, 0.27 |
| | gapinf | 0.32 (1.161) | 1.02M (0.818) | X12: 0.876 / 1.100, X14: 0.844 / 1.157, X16: 0.814 / 1.171 | X16: 0.18M, 0.21 |
| | ecover | 0.33 (1.201) | 1.01M (0.808) | X12: 0.873 / 1.169, X14: 0.838 / 1.188, X16: 0.803 / 1.194 | X16: 0.14M, 0.28 |
| | both | 0.34 (1.237) | 1.00M (0.805) | X12: 0.870 / 1.195, X14: 0.836 / 1.228, X16: 0.800 / 1.243 | X16: 0.14M, 0.29 |
| LP_714_100_16 | main | 0.55 | 3.02M | Z12: 0.18M 0.03s, X14: 1.18M 0.19s, Z14: 1.46M 0.25s | |
| | cand | 0.54 (0.987) | 2.35M (0.777) | Z12: 0.830 / 1.060, X14: 0.772 / 0.966, Z14: 0.769 / 0.991 | Z14: 0.11M, 0.37 |
| | gapinf | 0.58 (1.058) | 2.33M (0.771) | Z12: 0.827 / 1.107, X14: 0.767 / 1.025, Z14: 0.763 / 1.050 | Z14: 0.14M, 0.28 |
| | ecover | 0.59 (1.074) | 2.34M (0.773) | Z12: 0.829 / 1.148, X14: 0.771 / 1.053, Z14: 0.763 / 1.076 | Z14: 0.11M, 0.38 |
| | both | 0.58 (1.062) | 2.33M (0.773) | Z12: 0.828 / 1.175, X14: 0.771 / 1.051, Z14: 0.762 / 1.080 | Z14: 0.11M, 0.38 |
| BB_144_14_14 | main | 1.26 | 5.67M | X12: 0.83M 0.18s, X13: 3.98M 0.88s, X14: 0.64M 0.14s | |
| | cand | 0.74 (0.589) | 1.64M (0.290) | X12: 0.303 / 0.598, X13: 0.288 / 0.573, X14: 0.268 / 0.538 | X13: 0.28M, 0.88 |
| | gapinf | 0.63 (0.499) | 1.01M (0.178) | X12: 0.200 / 0.540, X13: 0.173 / 0.485, X14: 0.152 / 0.436 | X13: 0.32M, 0.67 |
| | ecover | 0.94 (0.742) | 1.66M (0.293) | X12: 0.304 / 0.770, X13: 0.291 / 0.730, X14: 0.274 / 0.704 | X13: 0.28M, 0.87 |
| | both | 0.75 (0.595) | 1.57M (0.276) | X12: 0.288 / 0.617, X13: 0.275 / 0.583, X14: 0.257 / 0.550 | X13: 0.27M, 0.89 |
| TN_108_2_12 | main | 0.86 | 3.36M | X10: 0.45M 0.11s, X11: 1.60M 0.40s, Z11: 0.79M 0.20s | |
| | cand | 0.84 (0.977) | 1.91M (0.568) | X10: 0.567 / 0.928, X11: 0.532 / 0.971, Z11: 0.594 / 0.972 | X11: 0.17M, 0.67 |
| | gapinf | 1.01 (1.175) | 1.70M (0.505) | X10: 0.499 / 1.219, X11: 0.459 / 1.083, Z11: 0.545 / 1.149 | X11: 0.26M, 0.46 |
| | ecover | 1.05 (1.213) | 2.10M (0.626) | X10: 0.626 / 1.176, X11: 0.592 / 1.131, Z11: 0.648 / 1.213 | X11: 0.17M, 0.58 |
| | both | 0.88 (1.019) | 1.86M (0.553) | X10: 0.554 / 1.006, X11: 0.518 / 0.953, Z11: 0.576 / 1.072 | X11: 0.16M, 0.70 |
| TN_144_2_13 | main | 3.07 | 11.71M | X12: 3.63M 0.94s, Z12: 1.90M 0.49s, Z13: 4.07M 1.08s | |
| | cand | 2.38 (0.778) | 5.12M (0.437) | X12: 0.444 / 0.807, Z12: 0.452 / 0.786, Z13: 0.397 / 0.707 | Z13: 0.33M, 0.78 |
| | gapinf | 2.55 (0.830) | 4.11M (0.351) | X12: 0.368 / 0.877, Z12: 0.364 / 0.841, Z13: 0.290 / 0.722 | Z13: 0.48M, 0.57 |
| | ecover | 3.19 (1.039) | 5.67M (0.484) | X12: 0.510 / 1.151, Z12: 0.480 / 1.024, Z13: 0.433 / 0.919 | Z13: 0.34M, 0.72 |
| | both | 2.52 (0.821) | 4.90M (0.418) | X12: 0.426 / 0.855, Z12: 0.430 / 0.825, Z13: 0.378 / 0.733 | Z13: 0.32M, 0.80 |
| TN_250_10_15 | main | 69.00 | 261.40M | X13: 37.61M 9.92s, X14: 123.95M 33.41s, Z14: 48.91M 12.62s | |
| | cand | 66.89 (0.969) | 160.02M (0.612) | X13: 0.563 / 0.898, X14: 0.543 / 0.878, Z14: 0.734 / 1.149 | X14: 12.30M, 0.59 |
| | gapinf | 74.43 (1.079) | 150.68M (0.576) | X13: 0.521 / 0.983, X14: 0.494 / 0.971, Z14: 0.720 / 1.296 | X14: 18.06M, 0.41 |
| | ecover | 82.16 (1.191) | 165.93M (0.635) | X13: 0.591 / 1.044, X14: 0.570 / 1.153, Z14: 0.747 / 1.278 | X14: 12.36M, 0.55 |
| | both | 98.68 (1.430) | 154.22M (0.590) | X13: 0.543 / 1.303, X14: 0.520 / 1.258, Z14: 0.710 / 1.758 | X14: 12.02M, 0.62 |
| TN_180_2_17 | main | 287.30 | 888.41M | X16: 324.16M 109.06s, Z16: 118.35M 42.48s, Z17: 273.04M 75.51s | |
| | cand | 188.01 (0.654) | 386.89M (0.435) | X16: 0.408 / 0.603, Z16: 0.476 / 0.626, Z17: 0.442 / 0.790 | X16: 27.55M, 0.77 |
| TN_216_4_18 | main | 610.83 | 2092.89M | X17: 853.51M 256.36s, Z17: 433.46M 121.98s, Z18: 261.45M 82.57s | |
| | cand | 505.62 (0.828) | 965.29M (0.461) | X17: 0.431 / 0.768, Z17: 0.502 / 0.915, Z18: 0.474 / 0.761 | X17: 80.62M, 0.75 |

Prunes by remaining budget are in the logs (`lbprune-by-budget`). Example, `cand` on TN_144 level Z13: 333 315
evaluations, 258 469 prunes (78 %) at remaining budgets 3 / 4 / 5 / 6 / 7: 60 531 / 128 554 / 58 891 / 9 827 / 656. TN_216
level X17: 80.6 M evaluations, 60.4 M prunes (75 %), mostly at budgets 4-6 (14.7 M / 26.1 M / 14.1 M). The prune rate grows with the level: on the open TN
codes from 20-45 % at levels 8-10 to 60-70 % at levels 16-18; on BB codes it stays at 15-28 %, on LP codes at 26-41 %
(Tier 5 logs).

## 5. Tier 1-4 panel

Settings: 5 seeds (`-seed=0..4`), default `-ub-search=on`, `-cc-stats`; tiers 1-3 limited to 1800 s, tier 4 to 5000 s.
Panel 1 (`S1/panel_table.md`): 220 runs, all four arms concurrently on cores 24-62 (`c3c315d` and `ea12971`). Panel 2
(`S1/panel2_table.md`): the final binaries (`06026be`, `13f1253`) on the four cells where the auto switch-off can trigger
(a level with >= 100 000 evaluations and < 40 % prunes; checked on the panel-1 logs), 80 runs serial on core 63. Floor
repeat (`S1/floor_repeat*.jsonl`, `S1/runner/floor_repeat.py`, preregistered after panel 1 as in GH-152): the LP cells at
the process floor, 25 interleaved runs per arm on one core. On all other cells the final binary runs the same search as
`c3c315d` (auto never triggers), so their panel-1 numbers apply.

| Tier | Code | main s | cand s | **ratio** | nodes | source | aut base s | aut cand s | **ratio** | nodes | source |
|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---|
| 1 | LP_340_56_8 | 0.020 | 0.020 | **1.001** | 0.918 | floor repeat (panel 1: 0.929) | 0.020 | 0.020 | **0.992** | 0.924 | floor repeat (panel 1: 1.040) |
| 1 | LP_442_68_10 | 0.020 | 0.020 | **0.999** | 0.868 | floor repeat (panel 1: 0.972) | 0.034 | 0.035 | **1.031** | 0.874 | floor repeat (panel 1: 1.167) |
| 2 | BB_144_14_14 | 1.115 | 0.669 | **0.600** | 0.296 | panel 1 | 1.114 | 0.691 | **0.620** | 0.296 | panel 1 |
| 2 | BB_288_12_18 | 0.287 | 0.317 | **1.105** | 0.845 | panel 2 (panel 1: 1.064) | 0.287 | 0.319 | **1.111** | 0.845 | panel 2 (panel 1: 1.138) |
| 2 | GB_144_12_12 | 0.086 | 0.065 | **0.756** | 0.417 | panel 1 | 0.087 | 0.075 | **0.862** | 0.417 | panel 1 |
| 2 | LP_544_80_12 | 0.042 | 0.043 | **1.026** | 0.860 | floor repeat (panel 1: 1.260) | 0.033 | 0.034 | **1.024** | 0.860 | floor repeat (panel 1: 1.205) |
| 2 | TN_108_2_12 | 2.083 | 1.820 | **0.874** | 0.453 | panel 1 | 2.090 | 1.821 | **0.871** | 0.453 | panel 1 |
| 2 | TN_200_10_10 | 0.288 | 0.317 | **1.101** | 0.747 | panel 1 | 0.166 | 0.188 | **1.133** | 0.743 | panel 1 |
| 3 | LP_714_100_16 | 0.714 | 0.775 | **1.085** | 0.817 | panel 2 (panel 1: 1.062) | 0.382 | 0.412 | **1.079** | 0.811 | panel 2 (panel 1: 1.104) |
| 3 | TN_144_2_13 | 5.658 | 4.460 | **0.788** | 0.381 | panel 2 (panel 1: 0.764) | 5.637 | 4.338 | **0.770** | 0.381 | panel 2 (panel 1: 0.780) |
| 4 | TN_250_10_15 | 112.847 | 106.705 | **0.946** | 0.708 | panel 2 (panel 1: 0.944) | 57.690 | 56.272 | **0.975** | 0.607 | panel 2 (panel 1: 0.969) |

| Tier | cells | geomean (main pair) | max cell | geomean (-cc-aut pair) | max cell |
|---:|---:|---:|---:|---:|---:|
| 1 | 2 | **1.000** | 1.001 | **1.012** | 1.031 |
| 2 | 6 | **0.889** | 1.105 | **0.919** | 1.133 |
| 3 | 2 | **0.925** | 1.085 | **0.911** | 1.079 |
| 4 | 1 | **0.946** | 0.946 | **0.975** | 0.975 |

Decision (pass = geomean < 1 and no cell > 1.25 per tier):
- Tier 1: the two cells sit at the process floor (20-35 ms, search < 5 ms; node ratio 0.87-0.92). Panel 0.950 / 1.102,
  floor repeat **1.000 / 1.011** (main pair / -cc-aut pair). Neutral; strictly the "< 1" condition is not met. GH-152
  treated the same situation (0.999) as a neutral pass; PI to confirm.
- Tier 2: **0.889 / 0.918**, max cell 1.105 / 1.133 (TN_200). LP_544's panel-1 1.260 is a floor artefact (50 ms total;
  repeat 1.026 / 1.024). PASS.
- Tier 3: **0.925 / 0.911**, max cell 1.085 (LP_714). PASS.
- Tier 4: **0.946 / 0.975**. PASS.

## 6. Tier 5

Settings: 6 h, default seed, default flags plus `-cc-stats`; 39 runs concurrently on cores 24-62 (`S1/tier5_results.jsonl`,
`S1/tier5_logs.tar.gz`, `S1/tier5_table.md`): `cand` (`c3c315d`, = final with `-cc-lb-auto=0`) on all 27 codes,
`autcand` (`ea12971`, `-cc-aut=on`) on the 7 codes where GH-152's orbits matter, and 5 same-session main controls. The
comparison basis is the GH-152 Tier 5 run (`S1/gh152_tier5_results_reference.jsonl`: its old arm is main's CC code, its
new arm `-cc-aut=on`). That session was about 10-15 % slower than this one: the main controls reach the same values in
0.85-0.91 of GH-152's time (TN_216 531 vs 583 s, TN_252 10 214 vs 11 204 s, TN_360 lb 22 8 579 vs 9 709 s, LP_1428 466 vs
551 s, BB_756 lb 30 16 644 vs 18 736 s). 39/39 runs clean, 0 science problems, every answer equals its stem.

| Code | GH-152 main | GH-157 cand | GH-152 aut | GH-157 autcand | main control (this session) | cand/main152 time at largest common lb | autcand/aut152 |
|---|---|---|---|---|---|---|---|
| BB_1080_4_30to48 | lb 30 (21600s) | lb 30 (21600s) | lb 30 (21600s) | - | - | lb 30: 16301 -> 16557 s (1.016) | - |
| BB_360_12_24 | d=24 @ 193s | d=24 @ 192s | d=24 @ 194s | - | - | lb 24: 193 -> 192 s (0.996) | - |
| BB_756_16_30to34 | lb 30 (21600s) | lb 30 (21600s) | lb 30 (21600s) | - | lb 30 (21600s) | lb 30: 18736 -> 18653 s (0.996) | - |
| BB_864_4_30to40 | lb 30 (21600s) | lb 30 (21600s) | lb 30 (21600s) | - | - | lb 30: 13315 -> 13913 s (1.045) | - |
| LP_1020_136_16 | d=16 @ 0s | d=16 @ 0s | d=16 @ 0s | - | - | - | - |
| LP_1054_140_20 | d=20 @ 18s | d=20 @ 16s | d=20 @ 2s | - | - | lb 20: 18 -> 16 s (0.890) | - |
| LP_1122_148_20 | d=20 @ 16s | d=20 @ 14s | d=20 @ 5s | - | - | lb 20: 16 -> 14 s (0.878) | - |
| LP_1428_184_24 | d=24 @ 551s | d=24 @ 447s | d=24 @ 138s | - | d=24 @ 466s | lb 24: 551 -> 447 s (0.811) | - |
| LP_1768_224_22 | d=22 @ 63s | d=22 @ 95s | d=22 @ 18s | - | - | lb 22: 63 -> 95 s (1.508) | - |
| LP_2610_744_16 | d=16 @ 7s | d=16 @ 6s | d=16 @ 3s | - | - | - | - |
| TN_180_2_17 | d=17 @ 191s | d=17 @ 134s | d=17 @ 189s | - | - | - | - |
| TN_216_4_18 | d=18 @ 583s | d=18 @ 424s | d=18 @ 582s | - | d=18 @ 531s | lb 18: 583 -> 424 s (0.727) | - |
| TN_252_2_21 | d=21 @ 11204s | d=21 @ 7319s | d=21 @ 11413s | d=21 @ 7462s | d=21 @ 10214s | lb 21: 11204 -> 7319 s (0.653) | lb 21: 11413 -> 7462 s (0.654) |
| TN_288_2_9to24 | lb 20 (21600s) | lb 20 (21600s) | lb 22 (21600s) | lb 22 (21600s) | - | lb 20: 11808 -> 8346 s (0.707) | lb 22: 20888 -> 14389 s (0.689) |
| TN_324_4_9to25 | lb 20 (21600s) | lb 20 (21600s) | lb 22 (21600s) | lb 22 (21600s) | - | lb 20: 10323 -> 7757 s (0.751) | lb 22: 15034 -> 10852 s (0.722) |
| TN_360_4_17to24 | lb 22 (21600s) | lb 23 (21600s) | lb 22 (21600s) | - | lb 22 (21600s) | lb 22: 9709 -> 6554 s (0.675) | - |
| TN_396_4_17to26 | lb 22 (21600s) | lb 23 (21600s) | lb 22 (21600s) | - | - | lb 22: 9544 -> 7052 s (0.739) | - |
| TN_432_8_9to29 | lb 21 (21600s) | lb 21 (21600s) | lb 23 (21600s) | lb 23 (21600s) | - | lb 21: 16517 -> 11938 s (0.723) | lb 23: 17206 -> 11858 s (0.689) |
| TN_468_4_17to29 | lb 23 (21600s) | lb 23 (21600s) | lb 23 (21600s) | - | - | lb 23: 21275 -> 16238 s (0.763) | - |
| TN_496_2_17to30 | lb 22 (21600s) | lb 22 (21600s) | lb 23 (21600s) | lb 23 (21600s) | - | lb 22: 11517 -> 9801 s (0.851) | lb 23: 16819 -> 13330 s (0.793) |
| TN_504_2_17to34 | lb 23 (21600s) | lb 24 (21600s) | lb 23 (21600s) | - | - | lb 23: 9674 -> 7008 s (0.724) | - |
| TN_540_4_9to34 | lb 21 (21600s) | lb 21 (21600s) | lb 23 (21600s) | lb 23 (21600s) | - | lb 21: 14250 -> 10752 s (0.755) | lb 23: 10757 -> 7874 s (0.732) |
| TN_576_2_9to37 | lb 22 (21600s) | lb 22 (21600s) | lb 24 (21600s) | lb 24 (21600s) | - | lb 22: 20839 -> 16489 s (0.791) | lb 24: 14303 -> 10961 s (0.766) |
| TN_612_2_17to40 | lb 24 (21600s) | lb 24 (21600s) | lb 24 (21600s) | - | - | lb 24: 18122 -> 13107 s (0.723) | - |
| TN_648_10_9to32 | lb 21 (21600s) | lb 22 (21600s) | lb 21 (21600s) | - | - | lb 21: 9106 -> 7570 s (0.831) | - |
| TN_648_14_9to28 | lb 21 (21600s) | lb 21 (21600s) | lb 21 (21600s) | - | - | lb 21: 10576 -> 7953 s (0.752) | - |
| TN_684_2_9to29 | lb 22 (21600s) | lb 22 (21600s) | lb 22 (21600s) | - | - | lb 22: 13344 -> 10288 s (0.771) | - |

Against the same-session main controls: TN_216 0.80, TN_252 0.72, TN_360 (lb 22) 0.76, LP_1428 0.96, BB_756 (lb 30) 1.12.
The BB codes run with a prune rate of 15-22 % (always-on in this run); with the final default `-cc-lb-auto=40` the BB
halves switch the bounds off after level 18 (BB_360 serial check below), so they behave like main.

**New certified CC lower bounds (stems not renamed). Reproduced on 2026-10-30 by a second run with a different search order (`mrv`, original labels; `REPRODUCTION.md`):**

| Code | CC lb before (GH-152 main arm / same-session main control) | GH-157 `cand` lb events from 19 (value@s) | verified ub (stem) |
|---|---:|---|---:|
| TN_360_4_17to24 | 22 / 22 | 19@186 20@592 21@1966 22@6554 **23@21103** | 24 |
| TN_396_4_17to26 | 22 / - | 19@237 20@712 21@2248 22@7052 **23@21564** | 26 |
| TN_504_2_17to34 | 23 / - | 19@78 20@231 21@698 22@2155 23@7008 **24@21150** | 34 |
| TN_648_10_9to32 | 21 / - | 19@918 20@2754 21@7570 **22@20712** | 32 |

All four come from the canonical CC search of main plus the `charge` pruning, which removes only nodes that provably
have no weight-w extension (section 3; Lemmas 1-2 in MODIFICATIONS.md). The deciding levels finished 36-888 s before the
6 h limit, so they are timing-sensitive: a slower session would not reach them. TN_360 now has lb 23 against the
verified ub 24. Independent cross-checks (relabelled seed, or the `-cc-aut` arm, which does not help these codes) were
not run; they would need more than 6 h per code.

With `-cc-aut=on` on both sides, `autcand` reaches every GH-152 `-cc-aut` value in 0.65-0.79 of the time (TN_288 lb 22:
0.69, TN_324 0.72, TN_432 0.69, TN_496 0.79, TN_540 0.73, TN_576 0.77, TN_252 d = 21: 0.65), but no further level in 6 h.

Serial check of the final default on core 63 (`S1/tier5_serial_results.jsonl`, `-v`):

| Code | main | `cand` (always on) | final (`-cc-lb-auto=40`) | switch-off |
|---|---:|---:|---:|---|
| LP_1768_224_22 | 60.5 s | 60.1 s | 59.4 s | X after 16, Z after 16 |
| LP_1428_184_24 | 502.0 s | 484.6 s | 450.7 s | X after 18, Z after 16 |
| BB_360_12_24 | 169.7 s | 186.2 s | 165.3 s | X after 18 |

(The LP_1768 `cand` time of 95 s in the parallel run was not reproduced serially: 60.1 s; the parallel run was disturbed.)

## 7. Discussion

- The bounds do what the theory says on the node count: 2.2-2.8x fewer nodes on the TN family (column weights 2-8, row
  weight 9), 3.4x on BB_144 (column weight 4), 2.5x on GB_144_12_12, but only 1.2-1.3x on column-weight-3 BB codes
  (packing plus overlap are already tight there) and on LP.
- One evaluation costs several nodes' worth (copy of the candidate sets plus two or three passes), so the time gain is
  smaller than the node gain: 0.65-0.83 on the TN family, 0.6 on BB_144, about neutral on TN_250 and LP, and a 10-17 %
  loss on BB_288 / TN_200 / BB codes in always-on mode. The gap gate (evaluate only where the packing is exactly at the
  limit) was the decisive change: 60-77 % of the evaluations but 76-99 % of the prunes happen there. The auto switch-off
  removes the BB/LP losses at large levels, but cannot help small codes whose last level decides the run.
- `ecover` adds 1-5 % more prunes after `charge` and costs more; on its own it prunes about as much as `charge` but is
  slower. It is kept as an option and not recommended.
- The ~25 % speed-up on the open TN codes is worth about a quarter of a level per 6 h (each level costs about 3x); this
  was enough to finish one more level on the four codes whose previous deciding level ended early enough.

## 8. PI decisions requested

1. **Adoption.** Tier 0-5 complete. Tiers 2-4 pass; Tier 1 is neutral at the process floor (1.000 / 1.012), as in GH-152.
   Options: (a) keep `charge` opt-in (no default change), (b) add `charge` to the default `-cc-rules` (with the auto
   switch-off at 40 %), (c) combine with PR #155 (`-cc-aut=on`): the gains multiply on the TN codes. A default change
   needs a baseline re-record afterwards.
2. **New lower bounds.** TN_360 >= 23, TN_396 >= 23, TN_504 >= 24, TN_648_10 >= 22 are PLAUSIBLE (one run each, default
   labelling). Cross-checks would need > 6 h per code (e.g. a 12 h relabelled-seed run, or `charge` plus `-cc-aut` once
   PR #155 is in). No stem was renamed.
3. **`ecover`.** Keep as an option, or drop it to reduce code (it never helped time).

## 9. Adoption (PI decisions of 2026-10-29)

The PI approved all three recommendations: (1) reproduce the four new lower bounds (`REPRODUCTION.md`), (2) drop
`ecover`, (3) make `charge` a default CC rule on top of the GH-152 `-cc-aut=on` default.

- `9702dde`: `ecover` removed (rule name, `lb_ecover`, Edmonds matching, mutant 16, `ecprune`/`ecexact` statistics,
  tests, docs). `-cc-rules=ecover` is now rejected. The sections above keep the `ecover` measurements as the record.
- `b064034`: merge of main `346d1c6` (PR #158 GH-148 and PR #155 `-cc-aut=on` default).
- `25030e3`: `charge` in the default `-cc-rules` (`excl,pack,orbf,parity,leaf,overlap,charge`);
  `-cc-rules=excl,pack,orbf,parity,leaf,overlap` gives the CC search before GH-157. README, `-h`, MODIFICATIONS and
  NOTICE updated. Tests: Part B and Part H default configurations now include `charge` (Part H with `-cc-aut`).
- Merge of main `6083e662` (PR #163 renamed six tier5 stems to the reproduced GH-152 bounds, e.g. TN_288_2_22to24; the Tier 5 tables above use the stem names of their run date). Source unchanged by that merge.
- `764b011`: Part I(a) restores the test RNG state, so every other part sees main's instance stream (without it, GH-148's
  mutant 2 coverage check depended on the shifted stream).

Tier 0 of the adopted default (yfclab2, pinned, 4 GB cap; records in `adopt/`):

| Check | Result |
|---|---|
| `make test-cc`, `764b011` (`adopt/tier0_tests_764b011.txt`) | PASS. Part I(a) 20 000 instances, 0 bad; Part I(b) 345 600 ladders, 0 bad; mutant 15 caught (3 408 / 38 400 ladders, 17 240 / 20 000 instances); mutants 1-14 and GH-148's mutants caught exactly as on main `346d1c6` (`adopt/tier0_tests_main_346d1c6.txt`, PASS) |
| `make test-cc-flags` | 442 / 442 |
| Answers, tier 0-3 (`adopt/answers_tier0123.jsonl`) | 61 / 61 equal to the stem: CC default (`-cc-aut=on`, `charge`) with seeds 0 and 1 on all 23 tier 0-3 codes, MaxSAT default on tier 0-1; 28 / 28 printed witnesses independently GF(2)-verified |
| Identity vs main `346d1c6`, tier0+1 `-v` logs (`adopt/identity_default.txt`, `adopt/ident_default.py`) | MaxSAT path: `-ub-pre=off` x 2 modes 30 / 30 identical; MaxSAT default 26 / 30 identical, 4 differ only in the time-sliced `ub-pre` progress line (base vs base differs the same way). Old CC path (`-cc-rules=excl,pack,orbf,parity,leaf,overlap` vs main's default CC): `-ub-search=off` with and without `-cc-stats` 30 / 30 identical, CC default 15 / 15 identical |

- Reproduction (`REPRODUCTION.md`): all four new bounds reproduced with `mrv` and the original labels within 12 h: TN_360 23 (41 464 s), TN_396 23 (35 297 s), TN_504 24 (41 050 s), TN_648_10 22 (31 744 s); every level EMPTY, node counts 1.1-2.0x the original run's at the deciding levels.
