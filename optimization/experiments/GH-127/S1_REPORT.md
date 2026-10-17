# GH-127 S1: unit lower-bound ladder, 5-seed Tier 1-4 panel, Tier 0 and Tier 5 on yfclab2

Issue #127, candidate branch `experiment/gh-127-orbit-split-ladder` at 32583fd (S0: `S0_REPORT.md`). Variants:
**A = `-lb-ladder=unit:8`**, **B = `-lb-ladder=unit:4`** (orbit split off in both; dropped after S0). Main arm = the same
candidate binary with no new flag (default path byte-identical to main abd1770 = 398054e's MaxSAT path) plus `-seed=S`.
Judging: docs/OPTIMIZATION_LOOP_POLICY.md (seed medians over seeds 0-4; per tier and mode the geomean of cell ratios
must be < 1 and no cell may exceed 1.25).

## 0. Summary

- **Correctness: clean.** 690 panel runs (tiers 0-4, 3 arms x 2 modes x 5 seeds) and 104 Tier 5 runs: every answer equals
  the stem distance, every live `c d_lb` <= d <= every `c d_ub`, lb sequences never decrease, ub sequences never
  increase, no runner errors, no memory-cap hits (max RSS 157 MB).
- **Tier 1-4 gates: A and B both FAIL Tier 1, Tier 2 and Tier 4, and PASS Tier 3.**

  | Tier | A no-card | A card-mto | A max cell | B no-card | B card-mto | B max cell |
  |---:|---:|---:|---:|---:|---:|---:|
  | 1 | 1.339 | 0.862 | 3.01 (BB_144_12_12 nc) | 1.501 | 1.054 | 3.02 (BB_144_12_12 nc) |
  | 2 | 0.940 | 0.823 | 1.69 (TN_108 nc) | 1.014 | 0.913 | 1.78 (TN_108 nc) |
  | 3 | 0.549 | 0.417 | 1.07 (BB_288 nc) | 0.588 | 0.435 | 1.08 (TN_200 mto) |
  | 4 | 1.270 | 1.207 | 1.27 (TN_250 nc) | 1.307 | 1.221 | 1.31 (TN_250 nc) |

  The ladder is a trade-off, not a uniform gain: large wins where main's cap-16 (or 32) feasibility probe lands on a
  poor logical and Phase 2 must descend (GB_144_12_12 5-9x, LP_442 1.7-2.7x, LP_544 1.8-2.7x, TN_144 1.5-2.3x,
  BB_288 card-mto >= 1.36x), losses where the extra refutations at caps 9, 10, ... cost more than the descent
  (BB_144_12_12 3.0x no-card / 1.3x card-mto, TN_108 1.4-1.8x, TN_250 1.2-1.3x; B also LP_340 1.9-2.2x).
- **Tier 5 (6 h, default seed): A 7 / B 7 solved cells of 52, the same 7 as main (no new solve); CC (GH-124 S1) 16.**
  Final lower bounds vs main: A higher in 28 cells, equal in 20, lower in 4 (LP_1054, LP_1428: 16 vs 17); B higher 26,
  equal 21, lower 5. Against CC: equal in the 8 cells that CC and the variant both solved (LP_714, LP_1020,
  TN_180 no-card, TN_216) and lower in the other 44; never higher. Where main stalls at lb 9 (its cap-16 refutation never
  finishes) the ladder reaches 15-16; BB codes reach 18-20 (main 17; CC 24-27). The ladder reaches lb 17 1.45-2.35x
  later than main (geomean 1.61 for A and for B over the 25-26 cells where both reach 17) and loses main's anytime upper
  bounds on BB_360 (main ub 24) and TN_252 no-card (main ub 28), because it never probes cap 32.
- **Finding (both variants, shared driver): after the global bounds meet (lb = ub), Phase 1 still runs the other half's
  probe at the same cap.** On every Tier 5 cell solved by A/B this costs 130-2200 s after lb = ub, and on TN_180 card-mto
  it turned a determined d = 17 (lb 17 and ub 17 both printed, at 19178 s for A and 20310 s for B) into a TIMEOUT. A
  small sound fix (skip a Phase 1 probe when the half's lb >= U) is proposed in section 5.3.
- **Recommendation: do not adopt A or B (gate failures at Tiers 1, 2, 4; Tier 5 gives no new solve and stays far below
  CC).** Keep `-lb-ladder` as an experimental flag. Next steps in section 6.

## 1. Setup

- Host yfclab2 (2 x EPYC 7742; physical cores 0-127, SMT siblings 128-255). Another user ran about 20-35 unpinned jobs
  throughout (load 115-145 with our 120 processes). Every process: `taskset -c CORE prlimit --as=4294967296 -- BIN ...`,
  one process per pinned physical core, at most 120 cores in use (0-63, 64-119).
- Binary: worktree `~/mac-agent-20261009/gh127-32583fd` (32583fd), built with the repository Makefile (g++ -O3),
  frozen as `~/mac-agent-20261009/frozen/server-gh127-32583fd/distqldpc`, sha256
  `26dc6f6b51f06518be73efdacc1d1f408b09b442d022fb04d202c0439f992d13`. Spot check before the runs: default-path `-v`
  output identical to the server main 398054e binary (`frozen/server-main398`) on BB_90, TN_72_8_8, LP_238,
  BB_144_12_12 x both modes (8/8; S0 has the full 28/28 identity check against abd1770).
- Seed panel (`S1/runner/s1_panel.py`, adapted from GH-124 S1): tiers 4, 3, 2, 1, 0 (longest first), cores 0-63 and
  116-119 (68 cores), started 07:44:40 CST, finished 08:55:46. Per code and seed S in {0,...,4} six runs queued back to
  back (so they ran concurrently): `[FLAG] -no-card|-card-mto -seed=S -cpu-lim=LIMIT data/matrices/tierT/STEM` with
  FLAG = none (main), `-lb-ladder=unit:8` (A), `-lb-ladder=unit:4` (B). Limits: tier0 600 s, tier1-3 1800 s,
  tier4 5000 s. Quiet runs (no `-v`): the live `c d_lb` / `c d_ub` lines were checked against the stem distance.
- Tier 5 (`S1/runner/s1_tier5.py`): every tier5 code x both modes, default seed, `-cpu-lim=21600`, quiet output with
  every line prefixed by its elapsed second (start epoch in the log header). A on cores 64-115 from 07:44:40 to
  13:44:40 (concurrently with the panel); B on cores 0-51 from 08:55:47 to 14:55:47 (after the panel, as instructed
  when cores are short). Driver: `S1/runner/run_s1.sh`. Main's Tier 5 is the recorded 398054e run
  (`optimization/baselines/SERVER.md`, 1 run per cell, 2026-10-14, also run next to other work, so Tier 5 time ratios
  carry host-load noise). CC is GH-124 S1's Tier 5 (`optimization/experiments/GH-124/S1/server/tier5/results.json`;
  old stems mapped to the renamed ones BB_360_12_24, TN_252_2_21, LP_1054_140_20, LP_1428_184_24, LP_1768_224_22).
- Nothing is left running on the server (checked after the driver's ALL_DONE at 14:55:47).

## 2. Correctness

| Arm | runs | correct answers | wrong answers / bound violations | timeouts | non-zero rc | max RSS MB |
|---|---:|---:|---:|---:|---:|---:|
| main | 230 | 227 | 0 | 3 | 3 | 155 |
| A | 230 | 230 | 0 | 0 | 0 | 157 |
| B | 230 | 230 | 0 | 0 | 0 | 151 |

Runner errors: 0; runner backstop kills: 0.

- TIMEOUT T3 BB_288_12_18 main card-mto seed 1 (limit 1800 s, final lb 17, ub 18)
- TIMEOUT T3 BB_288_12_18 main card-mto seed 2 (limit 1800 s, final lb 17, ub 18)
- TIMEOUT T3 BB_288_12_18 main card-mto seed 4 (limit 1800 s, final lb 17, ub 18)

The three main timeouts are BB_288_12_18 card-mto seeds 1, 2 and 4 at 1800 s (lb 17, ub 18, both valid); A and B solve
every seed of that cell (1049-1761 s). The non-zero rc values are those three timeouts. Tier 5: 104 runs, 0 bound or
answer problems (every lb <= the stem's upper bound and the adjudicated d, every ub >= the stem's lower bound; the 7
solved codes per variant return the stem distance).

## 3. Tier 1-4 seed panel

Ratio = median over seeds of the variant's wall time / median of main's, same cardinality mode; a timeout counts as
the limit (censored, so the BB_288 card-mto ratios 0.70/0.73 are upper bounds). "worst / main best" = the variant's
slowest seed over main's fastest seed.

### Per-tier geomean of seed-median ratios (variant / main, same mode) and gate

| Variant | Tier | cells per mode | geomean no-card | geomean card-mto | max cell | cells > 1 | cells > 1.25 | gate (geomean < 1 per mode, no cell > 1.25) |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| A (unit:8) | 1 | 4 | 1.339 | 0.862 | 3.013 | 5 | 2 | FAIL |
| A (unit:8) | 2 | 3 | 0.940 | 0.823 | 1.688 | 3 | 2 | FAIL |
| A (unit:8) | 3 | 5 | 0.549 | 0.417 | 1.067 | 2 | 0 | PASS |
| A (unit:8) | 4 | 1 | 1.270 | 1.207 | 1.270 | 2 | 1 | FAIL |
| B (unit:4) | 1 | 4 | 1.501 | 1.054 | 3.018 | 5 | 4 | FAIL |
| B (unit:4) | 2 | 3 | 1.014 | 0.913 | 1.778 | 3 | 2 | FAIL |
| B (unit:4) | 3 | 5 | 0.588 | 0.435 | 1.078 | 2 | 0 | PASS |
| B (unit:4) | 4 | 1 | 1.307 | 1.221 | 1.307 | 2 | 1 | FAIL |

- A (unit:8): geomean over all 26 tier1-4 cells 0.760; cells > 1: T1 BB_144_12_12 no-card 3.013, T2 TN_108_2_12 no-card 1.688, T2 TN_108_2_12 card-mto 1.406, T1 BB_144_12_12 card-mto 1.287, T4 TN_250_10_15 no-card 1.270, T4 TN_250_10_15 card-mto 1.207, T1 BB_108_8_10 no-card 1.079, T3 BB_288_12_18 no-card 1.067, T2 BB_144_14_14 card-mto 1.056, T1 LP_238_44_6 no-card 1.046, T3 TN_200_10_10 card-mto 1.005, T1 LP_340_56_8 card-mto 1.001.
- B (unit:4): geomean over all 26 tier1-4 cells 0.833; cells > 1: T1 BB_144_12_12 no-card 3.018, T1 LP_340_56_8 card-mto 2.217, T1 LP_340_56_8 no-card 1.896, T2 TN_108_2_12 no-card 1.778, T2 TN_108_2_12 card-mto 1.601, T1 BB_144_12_12 card-mto 1.331, T4 TN_250_10_15 no-card 1.307, T4 TN_250_10_15 card-mto 1.221, T1 BB_108_8_10 no-card 1.164, T3 TN_200_10_10 card-mto 1.078, T3 BB_288_12_18 no-card 1.056, T2 BB_144_14_14 card-mto 1.020.

### Seed panel, tiers 1-4: per cell (wall s, median over seeds 0-4, range; "T" = timeouts counted at the limit)

| Tier | Code | Mode | main median (range) | A median (range) | A ratio | B median (range) | B ratio | A worst / main best | B worst / main best |
|---:|---|---|---|---|---:|---|---:|---:|---:|
| 1 | BB_108_8_10 | no-card | 0.47 (0.27-1.089) | 0.507 (0.295-0.549) | 1.079 | 0.547 (0.337-0.775) | 1.164 | 2.03 | 2.87 |
| 1 | BB_108_8_10 | card-mto | 1.093 (0.514-1.947) | 0.496 (0.376-0.588) | 0.454 | 0.463 (0.406-0.825) | 0.424 | 1.14 | 1.61 |
| 1 | BB_144_12_12 | no-card | 0.85 (0.807-1.514) | 2.561 (2.263-2.891) | 3.013 | 2.565 (2.435-3.207) | 3.018 | 3.58 | 3.97 |
| 1 | BB_144_12_12 | card-mto | 1.914 (1.677-2.359) | 2.463 (2.275-3.522) | 1.287 | 2.547 (2.313-3.006) | 1.331 | 2.1 | 1.79 |
| 1 | LP_238_44_6 | no-card | 1.329 (0.93-1.52) | 1.39 (1.03-1.583) | 1.046 | 1.013 (0.766-1.477) | 0.762 | 1.7 | 1.59 |
| 1 | LP_238_44_6 | card-mto | 1.381 (1.004-1.941) | 1.304 (0.957-1.999) | 0.944 | 1.365 (1.037-1.513) | 0.988 | 1.99 | 1.51 |
| 1 | LP_340_56_8 | no-card | 4.073 (3.721-4.653) | 3.857 (3.662-5.001) | 0.947 | 7.723 (6.068-9.209) | 1.896 | 1.34 | 2.47 |
| 1 | LP_340_56_8 | card-mto | 4.416 (3.943-6.253) | 4.419 (3.883-7.446) | 1.001 | 9.79 (6.142-10.71) | 2.217 | 1.89 | 2.72 |
| 2 | BB_144_14_14 | no-card | 91.83 (71.12-104.5) | 91.09 (79.2-102.2) | 0.992 | 90.57 (79.21-119) | 0.986 | 1.44 | 1.67 |
| 2 | BB_144_14_14 | card-mto | 85.37 (63.58-111.9) | 90.11 (83.58-101.3) | 1.056 | 87.07 (80.4-119.4) | 1.020 | 1.59 | 1.88 |
| 2 | LP_442_68_10 | no-card | 58.02 (45.44-103.8) | 28.78 (27-29.58) | 0.496 | 34.51 (33.47-44.53) | 0.595 | 0.651 | 0.98 |
| 2 | LP_442_68_10 | card-mto | 73.07 (50.67-236.2) | 27.42 (26.2-29.72) | 0.375 | 34.01 (33.44-37.59) | 0.465 | 0.587 | 0.742 |
| 2 | TN_108_2_12 | no-card | 25.72 (24.84-29.23) | 43.41 (40.32-49.31) | 1.688 | 45.73 (42.12-48.89) | 1.778 | 1.98 | 1.97 |
| 2 | TN_108_2_12 | card-mto | 35.31 (23.67-38.34) | 49.66 (45.15-55.49) | 1.406 | 56.54 (48.67-71.55) | 1.601 | 2.34 | 3.02 |
| 3 | BB_288_12_18 | no-card | 951.8 (896.9-964.6) | 1015 (985-1020) | 1.067 | 1005 (969.2-1037) | 1.056 | 1.14 | 1.16 |
| 3 | BB_288_12_18 | card-mto | 1800 (1178-1800, 3T) | 1255 (1049-1590) | 0.697 | 1321 (1248-1761) | 0.734 | 1.35 | 1.49 |
| 3 | GB_144_12_12 | no-card | 148.1 (90.01-227.8) | 29.5 (15.14-31.9) | 0.199 | 29.38 (15.74-32.38) | 0.198 | 0.354 | 0.36 |
| 3 | GB_144_12_12 | card-mto | 288.1 (59.48-413.7) | 31.12 (24.5-41.79) | 0.108 | 31.3 (18.96-39.33) | 0.109 | 0.702 | 0.661 |
| 3 | LP_544_80_12 | no-card | 335 (193.6-656.4) | 153.8 (152.4-181.9) | 0.459 | 190.6 (156.9-246.3) | 0.569 | 0.94 | 1.27 |
| 3 | LP_544_80_12 | card-mto | 415.3 (245.2-604.1) | 156 (154.4-172.7) | 0.376 | 167.4 (159.9-212.8) | 0.403 | 0.704 | 0.868 |
| 3 | TN_144_2_13 | no-card | 343.7 (309.7-1087) | 224.9 (204.5-266.8) | 0.654 | 223.3 (206.6-275.7) | 0.649 | 0.862 | 0.89 |
| 3 | TN_144_2_13 | card-mto | 599.8 (241.8-804.1) | 265.4 (213.2-359.4) | 0.442 | 268.5 (216.1-323) | 0.448 | 1.49 | 1.34 |
| 3 | TN_200_10_10 | no-card | 32.23 (23.94-158.1) | 25.3 (24.03-34.63) | 0.785 | 29.17 (28.64-36.02) | 0.905 | 1.45 | 1.5 |
| 3 | TN_200_10_10 | card-mto | 25.15 (21.77-54.66) | 25.27 (22.89-32.09) | 1.005 | 27.1 (25.53-29.02) | 1.078 | 1.47 | 1.33 |
| 4 | TN_250_10_15 | no-card | 2781 (2229-4129) | 3532 (2778-4267) | 1.270 | 3634 (2947-3994) | 1.307 | 1.91 | 1.79 |
| 4 | TN_250_10_15 | card-mto | 2711 (2270-3762) | 3271 (2578-3834) | 1.207 | 3311 (2736-3602) | 1.221 | 1.69 | 1.59 |

Noise reference: for d <= 8 the unit:8 ladder makes exactly main's Phase 1 caps (1, 2, 4, 8), so A's search on
LP_238_44_6 and LP_340_56_8 is identical to main's (the quiet outputs are identical for all 5 seeds x 2 modes and the
utime ratios are 0.95-1.03). Their cell ratios (0.944-1.046) show the cell-level timing noise of this panel, about
+-5%. TN_200 card-mto (A 1.005, B 1.078), BB_144_14_14 (0.99-1.06) and BB_288 no-card (1.06-1.07) are within or close
to that band; BB_144_12_12, TN_108, TN_250 and (B only) LP_340 are real regressions (the utime ratios in the CPU-time
cross-check of section 4 agree).

## 4. Tier 0 (correctness only)

| Arm | runs | correct | problems | timeouts | slowest run s | geomean of seed-median ratio vs main (info) |
|---|---:|---:|---:|---:|---:|---:|
| main | 100 | 100 | 0 | 0 | 1.30 | - |
| A | 100 | 100 | 0 | 0 | 1.53 | 1.005 |
| B | 100 | 100 | 0 | 0 | 1.70 | 1.120 |

CPU-time cross-check (seed-median utime ratio A/main, B/main per tier1-4 cell): BB_108_8_10 card-mto: 0.389/0.404; BB_108_8_10 no-card: 1.03/1.15; BB_144_12_12 card-mto: 1.22/1.37; BB_144_12_12 no-card: 2.84/2.75; LP_238_44_6 card-mto: 0.945/0.911; LP_238_44_6 no-card: 1.03/0.874; LP_340_56_8 card-mto: 0.967/1.88; LP_340_56_8 no-card: 0.981/1.66; BB_144_14_14 card-mto: 1.05/1.02; BB_144_14_14 no-card: 0.993/0.992; LP_442_68_10 card-mto: 0.388/0.48; LP_442_68_10 no-card: 0.493/0.594; TN_108_2_12 card-mto: 1.45/1.52; TN_108_2_12 no-card: 1.61/1.65; BB_288_12_18 card-mto: 0.701/0.738; BB_288_12_18 no-card: 1.07/1.06; GB_144_12_12 card-mto: 0.109/0.11; GB_144_12_12 no-card: 0.203/0.202; LP_544_80_12 card-mto: 0.376/0.401; LP_544_80_12 no-card: 0.457/0.554; TN_144_2_13 card-mto: 0.448/0.453; TN_144_2_13 no-card: 0.656/0.651; TN_200_10_10 card-mto: 0.988/1.05; TN_200_10_10 no-card: 0.786/0.891; TN_250_10_15 card-mto: 1.21/1.22; TN_250_10_15 no-card: 1.27/1.31

Every tier0 run finishes in under 2 s for every arm (policy: Tier 0 gates correctness and severe slowdowns only), so
Tier 0 passes for A and B.

## 5. Tier 5

### Tier 5 (6 h, default seed): A and B against main 398054e (SERVER.md, 1 run per cell) and CC (GH-124 S1)
Cells: `d=X @ t` = solved at t s; `T, lb/ub (lb@t)` = timeout with the final bounds and the first time the final lb was printed.

| Code | Mode | main | A (unit:8) | B (unit:4) | CC (mode-free) | A lb vs main | B lb vs main | A lb events >= 15 | B lb events >= 15 | checks |
|---|---|---|---|---|---|---|---|---|---|---|
| BB_1080_4_ge17 | no-card | T, 17/- (lb@2423) | T, 18/- (lb@11626) | T, 18/- (lb@11404) | T, 27/66 (lb@10206) | > | > | 15@628, 16@1686, 17@4243, 18@11626 | 15@471, 16@1262, 17@4024, 18@11404 | ok |
| BB_1080_4_ge17 | card-mto | T, 17/- (lb@2422) | T, 18/- (lb@11160) | T, 18/- (lb@11406) | T, 27/66 (lb@10206) | > | > | 15@466, 16@1281, 17@3823, 18@11160 | 15@472, 16@1299, 17@4055, 18@11406 | ok |
| BB_360_12_24 | no-card | T, 17/24 (lb@206) | T, 20/- (lb@16556) | T, 20/- (lb@17634) | d=24 @ 1706 s | > | > | 15@52, 16@137, 17@357, 18@1222, 19@4384, 20@16556 | 15@50, 16@133, 17@349, 18@1196, 19@4357, 20@17634 | ok |
| BB_360_12_24 | card-mto | T, 17/24 (lb@168) | T, 20/- (lb@16241) | T, 20/- (lb@18900) | d=24 @ 1706 s | > | > | 15@52, 16@118, 17@297, 18@1171, 19@4103, 20@16241 | 15@69, 16@155, 17@394, 18@1291, 19@4545, 20@18900 | ok |
| BB_756_16_ge17 | no-card | T, 17/- (lb@844) | T, 19/- (lb@19275) | T, 18/- (lb@3297) | T, 27/52 (lb@11251) | > | > | 15@196, 16@464, 17@1360, 18@3646, 19@19275 | 15@183, 16@445, 17@1319, 18@3297 | ok |
| BB_756_16_ge17 | card-mto | T, 17/- (lb@846) | T, 19/- (lb@18451) | T, 19/- (lb@19302) | T, 27/52 (lb@11251) | > | > | 15@211, 16@491, 17@1389, 18@3295, 19@18451 | 15@166, 16@429, 17@1305, 18@3172, 19@19302 | ok |
| BB_864_4_ge17 | no-card | T, 17/- (lb@1176) | T, 19/- (lb@20656) | T, 19/- (lb@21586) | T, 27/108 (lb@8722) | > | > | 15@281, 16@621, 17@1880, 18@4546, 19@20656 | 15@261, 16@593, 17@1815, 18@4521, 19@21586 | ok |
| BB_864_4_ge17 | card-mto | T, 17/- (lb@1175) | T, 19/- (lb@21187) | T, 18/- (lb@4482) | T, 27/108 (lb@8722) | > | > | 15@281, 16@620, 17@1972, 18@4867, 19@21187 | 15@252, 16@585, 17@1813, 18@4482 | ok |
| LP_1020_136_16 | no-card | d=16 @ 7159 s | d=16 @ 11644 s | d=16 @ 12534 s | d=16 @ 2 s | = | = | 15@4377, 16@9910 | 15@5063, 16@10741 | ok |
| LP_1020_136_16 | card-mto | d=16 @ 8328 s | d=16 @ 11601 s | d=16 @ 11013 s | d=16 @ 2 s | = | = | 15@4353, 16@9880 | 15@3899, 16@9290 | ok |
| LP_1054_140_20 | no-card | T, 17/- (lb@16379) | T, 16/- (lb@11829) | T, 16/- (lb@10602) | d=20 @ 123 s | < | < | 15@4803, 16@11829 | 15@4388, 16@10602 | ok |
| LP_1054_140_20 | card-mto | T, 17/- (lb@16386) | T, 16/- (lb@10886) | T, 16/- (lb@10621) | d=20 @ 123 s | < | < | 15@4422, 16@10886 | 15@4394, 16@10621 | ok |
| LP_1428_184_24 | no-card | T, 17/- (lb@19868) | T, 16/- (lb@12183) | T, 16/- (lb@13444) | d=24 @ 2884 s | < | < | 15@5383, 16@12183 | 15@5728, 16@13444 | ok |
| LP_1428_184_24 | card-mto | T, 17/- (lb@15997) | T, 16/- (lb@11982) | T, 16/- (lb@12480) | d=24 @ 2884 s | < | < | 15@5233, 16@11982 | 15@5152, 16@12480 | ok |
| LP_1768_224_22 | no-card | T, 9/- (lb@49) | T, 15/- (lb@9720) | T, 15/- (lb@9702) | d=22 @ 327 s | > | > | 15@9720 | 15@9702 | ok |
| LP_1768_224_22 | card-mto | T, 9/- (lb@48) | T, 15/- (lb@10224) | T, 15/- (lb@9714) | d=22 @ 327 s | > | > | 15@10224 | 15@9714 | ok |
| LP_714_100_16 | no-card | d=16 @ 8752 s | d=16 @ 8524 s | d=16 @ 8371 s | d=16 @ 2 s | = | = | 15@3034, 16@7125 | 15@2816, 16@6962 | ok |
| LP_714_100_16 | card-mto | d=16 @ 5321 s | d=16 @ 8019 s | d=16 @ 8337 s | d=16 @ 2 s | = | = | 15@2532, 16@6593 | 15@2731, 16@6923 | ok |
| TN_180_2_17 | no-card | d=17 @ 9837 s | d=17 @ 17872 s | d=17 @ 18910 s | d=17 @ 257 s | = | = | 15@1058, 16@3562, 17@10168 | 15@1044, 16@3776, 17@10426 | ok |
| TN_180_2_17 | card-mto | T, 17/19 (lb@10917) | T, 17/17 (lb@16534) | T, 17/17 (lb@17863) | d=17 @ 257 s | = | = | 15@1391, 16@5249, 17@16534 | 15@1186, 16@5103, 17@17863 | ok |
| TN_216_4_18 | no-card | d=18 @ 16802 s | d=18 @ 14040 s | d=18 @ 14566 s | d=18 @ 696 s | = | = | 15@945, 16@2660, 17@6029, 18@13453 | 15@777, 16@2128, 17@5433, 18@13581 | ok |
| TN_216_4_18 | card-mto | d=18 @ 18346 s | d=18 @ 14199 s | d=18 @ 14539 s | d=18 @ 696 s | = | = | 15@908, 16@2351, 17@6200, 18@13819 | 15@820, 16@2214, 17@6113, 18@14130 | ok |
| TN_252_2_21 | no-card | T, 17/28 (lb@8660) | T, 17/- (lb@12516) | T, 17/- (lb@12586) | T, 21/28 (lb@10045) | = | = | 15@1029, 16@3676, 17@12516 | 15@993, 16@3486, 17@12586 | ok |
| TN_252_2_21 | card-mto | T, 17/- (lb@8034) | T, 17/- (lb@11857) | T, 17/- (lb@11818) | T, 21/28 (lb@10045) | = | = | 15@1100, 16@3557, 17@11857 | 15@1057, 16@3475, 17@11818 | ok |
| TN_288_2_ge9 | no-card | T, 9/- (lb@15) | T, 15/- (lb@7450) | T, 15/- (lb@6859) | T, 20/32 (lb@10567) | > | > | 15@7450 | 15@6859 | ok |
| TN_288_2_ge9 | card-mto | T, 9/- (lb@12) | T, 15/- (lb@6380) | T, 15/- (lb@6146) | T, 20/32 (lb@10567) | > | > | 15@6380 | 15@6146 | ok |
| TN_324_4_ge9 | no-card | T, 9/- (lb@15) | T, 16/- (lb@17126) | T, 16/- (lb@18694) | T, 20/36 (lb@9488) | > | > | 15@5744, 16@17126 | 15@5680, 16@18694 | ok |
| TN_324_4_ge9 | card-mto | T, 9/- (lb@16) | T, 16/- (lb@18381) | T, 16/- (lb@20097) | T, 20/36 (lb@9488) | > | > | 15@5497, 16@18381 | 15@5425, 16@20097 | ok |
| TN_360_4_ge17 | no-card | T, 17/- (lb@5403) | T, 17/- (lb@8362) | T, 17/- (lb@8127) | T, 22/40 (lb@10903) | = | = | 15@830, 16@2604, 17@8362 | 15@819, 16@2682, 17@8127 | ok |
| TN_360_4_ge17 | card-mto | T, 17/- (lb@5154) | T, 17/- (lb@7684) | T, 17/- (lb@7561) | T, 22/40 (lb@10903) | = | = | 15@696, 16@2400, 17@7684 | 15@681, 16@2316, 17@7561 | ok |
| TN_396_4_ge17 | no-card | T, 17/- (lb@4468) | T, 17/- (lb@7401) | T, 17/- (lb@6986) | T, 22/44 (lb@9247) | = | = | 15@974, 16@2808, 17@7401 | 15@941, 16@2742, 17@6986 | ok |
| TN_396_4_ge17 | card-mto | T, 17/- (lb@4588) | T, 17/- (lb@7073) | T, 17/- (lb@6855) | T, 22/44 (lb@9247) | = | = | 15@1022, 16@2829, 17@7073 | 15@1000, 16@2643, 17@6855 | ok |
| TN_432_8_ge9 | no-card | T, 9/- (lb@21) | T, 15/- (lb@9658) | T, 15/- (lb@9356) | T, 21/36 (lb@14128) | > | > | 15@9658 | 15@9356 | ok |
| TN_432_8_ge9 | card-mto | T, 9/- (lb@20) | T, 15/- (lb@8191) | T, 15/- (lb@8068) | T, 21/36 (lb@14128) | > | > | 15@8191 | 15@8068 | ok |
| TN_468_4_ge17 | no-card | T, 17/- (lb@8437) | T, 17/- (lb@13739) | T, 17/- (lb@13395) | T, 22/52 (lb@6906) | = | = | 15@1688, 16@5151, 17@13739 | 15@1579, 16@4755, 17@13395 | ok |
| TN_468_4_ge17 | card-mto | T, 17/- (lb@9988) | T, 17/- (lb@14564) | T, 17/- (lb@14475) | T, 22/52 (lb@6906) | = | = | 15@1591, 16@4476, 17@14564 | 15@1376, 16@4222, 17@14475 | ok |
| TN_496_2_ge17 | no-card | T, 17/- (lb@9969) | T, 17/- (lb@17404) | T, 16/- (lb@6270) | T, 22/64 (lb@13785) | = | < | 15@2242, 16@6532, 17@17404 | 15@1839, 16@6270 | ok |
| TN_496_2_ge17 | card-mto | T, 17/- (lb@11092) | T, 17/- (lb@16902) | T, 17/- (lb@20663) | T, 22/64 (lb@13785) | = | = | 15@1877, 16@5358, 17@16902 | 15@1824, 16@5366, 17@20663 | ok |
| TN_504_2_ge17 | no-card | T, 17/- (lb@4919) | T, 17/- (lb@7563) | T, 17/- (lb@7588) | T, 23/56 (lb@8145) | = | = | 15@925, 16@2513, 17@7563 | 15@899, 16@2449, 17@7588 | ok |
| TN_504_2_ge17 | card-mto | T, 17/- (lb@4866) | T, 17/- (lb@7994) | T, 17/- (lb@7592) | T, 23/56 (lb@8145) | = | = | 15@892, 16@2823, 17@7994 | 15@889, 16@2508, 17@7592 | ok |
| TN_540_4_ge9 | no-card | T, 9/- (lb@34) | T, 15/- (lb@11566) | T, 15/- (lb@11037) | T, 21/50 (lb@12298) | > | > | 15@11566 | 15@11037 | ok |
| TN_540_4_ge9 | card-mto | T, 9/- (lb@30) | T, 15/- (lb@12097) | T, 15/- (lb@12273) | T, 21/50 (lb@12298) | > | > | 15@12097 | 15@12273 | ok |
| TN_576_2_ge9 | no-card | T, 9/- (lb@38) | T, 15/- (lb@14022) | T, 15/- (lb@14290) | T, 22/64 (lb@18676) | > | > | 15@14022 | 15@14290 | ok |
| TN_576_2_ge9 | card-mto | T, 9/- (lb@46) | T, 15/- (lb@11875) | T, 15/- (lb@11905) | T, 22/64 (lb@18676) | > | > | 15@11875 | 15@11905 | ok |
| TN_612_2_ge17 | no-card | T, 17/- (lb@4293) | T, 18/- (lb@21307) | T, 17/- (lb@7675) | T, 24/68 (lb@15939) | > | = | 15@983, 16@2456, 17@6880, 18@21307 | 15@960, 16@2440, 17@7675 | ok |
| TN_612_2_ge17 | card-mto | T, 17/- (lb@4182) | T, 18/- (lb@21478) | T, 17/- (lb@7029) | T, 24/68 (lb@15939) | > | = | 15@1114, 16@2676, 17@6942, 18@21478 | 15@1076, 16@2628, 17@7029 | ok |
| TN_648_10_9to52 | no-card | T, 9/- (lb@51) | T, 15/- (lb@16591) | T, 15/- (lb@18853) | T, 21/52 (lb@8104) | > | > | 15@16591 | 15@18853 | ok |
| TN_648_10_9to52 | card-mto | T, 9/- (lb@59) | T, 15/- (lb@17042) | T, 15/- (lb@18546) | T, 21/52 (lb@8104) | > | > | 15@17042 | 15@18546 | ok |
| TN_648_14_ge9 | no-card | T, 9/- (lb@67) | T, 15/- (lb@17864) | T, 15/- (lb@19938) | T, 21/54 (lb@11075) | > | > | 15@17864 | 15@19938 | ok |
| TN_648_14_ge9 | card-mto | T, 9/- (lb@58) | T, 15/- (lb@16650) | T, 15/- (lb@17780) | T, 21/54 (lb@11075) | > | > | 15@16650 | 15@17780 | ok |
| TN_684_2_ge9 | no-card | T, 9/- (lb@16) | T, 15/- (lb@4377) | T, 15/- (lb@4376) | T, 22/57 (lb@18210) | > | > | 15@4377 | 15@4376 | ok |
| TN_684_2_ge9 | card-mto | T, 9/- (lb@14) | T, 15/- (lb@4252) | T, 15/- (lb@4224) | T, 22/57 (lb@18210) | > | > | 15@4252 | 15@4224 | ok |

Solved cells (of 52): main 7, A 7, B 7, CC 16 (one CC run per code fills both mode cells).

- A (unit:8): final lb (or d) vs main: higher 28, equal 20, lower 4; vs CC: higher 0, equal 8, lower 44.
- B (unit:4): final lb (or d) vs main: higher 26, equal 21, lower 5; vs CC: higher 0, equal 8, lower 44.

| Code | Mode | main time to d | A time to d | B time to d | CC time to d |
|---|---|---:|---:|---:|---:|
| BB_360_12_24 | no-card | T | T | T | 1706 (d=24) |
| BB_360_12_24 | card-mto | T | T | T | 1706 (d=24) |
| LP_1020_136_16 | no-card | 7159 | 11644 (d=16) | 12534 (d=16) | 2 (d=16) |
| LP_1020_136_16 | card-mto | 8328 | 11601 (d=16) | 11013 (d=16) | 2 (d=16) |
| LP_1054_140_20 | no-card | T | T | T | 123 (d=20) |
| LP_1054_140_20 | card-mto | T | T | T | 123 (d=20) |
| LP_1428_184_24 | no-card | T | T | T | 2884 (d=24) |
| LP_1428_184_24 | card-mto | T | T | T | 2884 (d=24) |
| LP_1768_224_22 | no-card | T | T | T | 327 (d=22) |
| LP_1768_224_22 | card-mto | T | T | T | 327 (d=22) |
| LP_714_100_16 | no-card | 8752 | 8524 (d=16) | 8371 (d=16) | 2 (d=16) |
| LP_714_100_16 | card-mto | 5321 | 8019 (d=16) | 8337 (d=16) | 2 (d=16) |
| TN_180_2_17 | no-card | 9837 | 17872 (d=17) | 18910 (d=17) | 257 (d=17) |
| TN_180_2_17 | card-mto | T | T | T | 257 (d=17) |
| TN_216_4_18 | no-card | 16802 | 14040 (d=18) | 14566 (d=18) | 696 (d=18) |
| TN_216_4_18 | card-mto | 18346 | 14199 (d=18) | 14539 (d=18) | 696 (d=18) |

### 5.1 What the ladder does on Tier 5

- Main's Phase 1 doubles 1, 2, 4, 8, 16, 32: lb 17 = the cap-16 refutation, after which it searches for any logical of
  weight <= 32 (which can give an early ub, e.g. BB_360 ub 24, TN_252 ub 28) and its lb stays at 17 until that probe
  ends; on codes where the cap-16 refutation does not finish in 6 h, main's lb stays at 9.
- With the ladder every cap from 9 (A) or 5 (B) upwards is a separate refutation. Each prints an lb, so the lb climbs
  10, 11, ..., but these refutations together cost more than main's single cap-16 refutation: lb 17 arrives 1.45-2.35x
  later (geomean 1.61, A and B alike). Net effect after 6 h: higher lbs on BB codes (18-20 vs 17) and on main's lb-9
  codes (15-16 vs 9), equal on most TN codes where main has lb 17, lower on LP_1054/LP_1428 (16 vs 17), and no upper
  bound on BB_360 / TN_252 (main 24 / 28), since no cap-32 probe is made.
- Solved cells: the same 7 as main. A is faster than main on TN_216 (14040/14199 s vs 16802/18346 s) and LP_714
  no-card (8524 vs 8752 s), slower on LP_1020 (11.6 k vs 7.2/8.3 k s), LP_714 card-mto (8019 vs 5321 s) and TN_180
  no-card (17872 vs 9837 s). B is similar.
- Against CC: CC solves 8 codes (16 cells) and ends with lb 20-27 on the others; the best A/B open-code lbs are 18-20 on
  BB, 15-18 on TN and 15-16 on LP. The MaxSAT path with a ladder does not approach CC on Tier 5.

### 5.2 A against B

A and B behave almost identically on Tier 5 (B's extra refutations at caps 5-8 are cheap at this size): same solved
cells, equal final lbs (or d) in 47 of 52 cells; A is higher on BB_756 no-card, BB_864 card-mto, TN_612 (both modes) and
TN_496 no-card, B is never higher. On Tiers 1-4 A is better than B in every tier.

### 5.3 Finding: Phase 1 keeps probing after the bounds meet

| Run | lb = ub reached at (s) | answer printed at (s) | after lb = ub (s) |
|---|---:|---:|---:|
| LP_1020_136_16 card-mto A | 11470 | 11601 | 131 |
| LP_1020_136_16 card-mto B | 10884 | 11013 | 129 |
| LP_1020_136_16 no-card A | 11516 | 11644 | 128 |
| LP_1020_136_16 no-card B | 12389 | 12534 | 146 |
| LP_714_100_16 card-mto A | 6619 | 8019 | 1401 |
| LP_714_100_16 card-mto B | 6949 | 8337 | 1388 |
| LP_714_100_16 no-card A | 7151 | 8524 | 1373 |
| LP_714_100_16 no-card B | 6988 | 8371 | 1384 |
| TN_180_2_17 card-mto A | 19178 | TIMEOUT (21600) | >= 2422 |
| TN_180_2_17 card-mto B | 20310 | TIMEOUT (21600) | >= 1290 |
| TN_180_2_17 no-card A | 15665 | 17872 | 2207 |
| TN_180_2_17 no-card B | 17532 | 18910 | 1378 |
| TN_216_4_18 card-mto A | 13916 | 14199 | 283 |
| TN_216_4_18 card-mto B | 14232 | 14539 | 307 |
| TN_216_4_18 no-card A | 13590 | 14040 | 450 |
| TN_216_4_18 no-card B | 13808 | 14566 | 758 |

Replay with `-v -dualshare-stats` (server, LP_442_68_10 and TN_108_2_12, A, no-card) shows the sequence: `X half cap 10 lb 10 feasibility -> FOUND 10` and then `Z half cap 10 lb 10 feasibility -> FOUND 10` before `d = 10` (TN_108: the same at cap 12). On these small codes the second probe is cheap; on Tier 5 it is either a full search for a weight-m logical in the other half or its refutation.

In `css_interleave` Phase 1 the inner loop probes both halves at cap m. When the first half's probe finds a logical
of weight U and the second half already has lb >= U (it was refuted at cap m-1), the second half's probe at cap m
cannot improve d = min(dX, dZ), yet it still runs to completion. With main's doubling caps this rarely matters (U is
usually far below the cap), but with a unit ladder U typically equals the other half's lb. Proposed fix (sound: a half
with lb >= U holds no logical of weight < U, so d = U once every half has lb >= U or has been probed): in Phase 1 skip a
half when `h.lb >= U`, as Phase 2a/2b already do. It changes main's doubling path only when a half already has
lb >= U at its probe, but it should be measured like any other change. With it, A and B would also have solved TN_180
card-mto (8 solved codes / 8 cells, still half of CC's 16).

## 6. Gate verdicts and recommendation

| Gate | A (unit:8) | B (unit:4) |
|---|---|---|
| Tier 0 (correctness, severe slowdown) | PASS | PASS |
| Tier 1 | FAIL (no-card geomean 1.339; BB_144_12_12 3.01 / 1.29) | FAIL (1.501 / 1.054; 4 cells > 1.25) |
| Tier 2 | FAIL (TN_108 1.69 / 1.41) | FAIL (no-card geomean 1.014; TN_108 1.78 / 1.60) |
| Tier 3 | PASS (0.549 / 0.417, max cell 1.07) | PASS (0.588 / 0.435, max cell 1.08) |
| Tier 4 | FAIL (TN_250 1.27 / 1.21) | FAIL (TN_250 1.31 / 1.22) |
| Tier 5 | no new solve (7 = main's 7; CC 16); lb higher than main in 28/52 cells, lower in 4; loses main's ub on BB_360 and TN_252 | same picture (lb higher in 26, lower in 5) |

**Recommendation: REJECT both A and B as a default (confirmed regressions at Tiers 1, 2 and 4).** The ladder stays an
experimental flag. The S1 data show where it helps (codes where main's first feasible solution at cap 16/32 is poor:
GB_144_12_12, LP_442, LP_544, TN_144, BB_288 card-mto) and where it hurts (codes whose refutations at caps between 8 and
d-1 are expensive relative to the descent: BB_144_12_12, TN_108, TN_250). Suggested follow-ups, each a separate round:

1. The Phase 1 early exit of section 5.3 (small, sound, measurable on its own; most useful together with any ladder).
2. If the ladder is revisited: an adaptive rule instead of a fixed K (for example keep doubling, and when a
   feasibility probe returns a logical much heavier than the current lb, try intermediate caps before Phase 2's
   descent), or the default K = 16 ladder (identical to main for d <= 16, i.e. all tier1-4 codes except BB_288) for
   Tier 5 only.
3. The Tier 5 gap to CC (no MaxSAT lb above 20 against CC's 20-27; 7 against 16 solved cells) says that cap scheduling
   is not the lever; steps 2 (frontier branching) and 3 (packing propagator) of the #127 plan address the search itself.

## 7. Files

| Path | Content |
|---|---|
| `S1/runner/s1_panel.py` | tier0-4 seed panel runner (3 arms x 2 modes x 5 seeds, pinned cores, 4 GB cap, answer/bound checks) |
| `S1/runner/s1_tier5.py` | Tier 5 runner (one variant flag, both modes, timestamped output lines) |
| `S1/runner/run_s1.sh` | driver used on yfclab2 |
| `S1/runner/analyze_s1.py` | analysis: `python3 S1/runner/analyze_s1.py S1/server/panel_results.jsonl S1/server/tier5_A_results.json S1/server/tier5_B_results.json optimization/baselines/SERVER.md optimization/experiments/GH-124/S1/server/tier5/results.json` |
| `S1/server/summary.md` | analysis output (all tables above) |
| `S1/server/panel_results.jsonl`, `panel_config.json`, `panel.out` | 690 panel run records (wall, utime, RSS, rc, answer, bounds, checks, exact command) |
| `S1/server/tier5_A_results.json`, `tier5_B_results.json`, `tier5_*.out`, `driver.log` | Tier 5 records with timestamped lb/ub events. The runner's `final_lb`/`final_ub`/`withdrawn` fields treat the MaxSAT path's `c d_ub: -` (no ub known at a timeout) as a CC-style withdrawal; `analyze_s1.py` recomputes the final bounds from the events |
| `S1/server/gh127-s1-raw-logs.tar.gz` | every raw log (690 panel logs, 104 timestamped Tier 5 logs) and the driver log |
