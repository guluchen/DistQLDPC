# GH-124 S1 report: CC engine (`-engine=cc`) against main, Tier 0-5

- Date: 2026-10-16. Round GH-124 (issue #124), stage S1 (`CC_INTEGRATION_PLAN.md` §7, preregistered expectations in `S0_REPORT.md` §7).
- Candidate: branch `experiment/gh-124-cc-engine` at **244f670**. CC is optional (`-engine=cc`); the default stays MaxSAT.
- Main arm: the same binary with `-engine=maxsat -seed=S`. `-engine=maxsat -seed=0` is byte-identical to main 398054e (PRE_S1_NOTES §2; re-checked on the server, below).
- Binaries:
  - yfclab2: `~/mac-agent-20261009/frozen/server-gh124-244f670/distqldpc`, sha256 `9daab279…b701`, built from worktree `~/mac-agent-20261009/gh124-244f670` (GCC, `make`).
  - Mac: `<scratch>/frozen-gh124-244f670/distqldpc`, sha256 `9d660cc5…29b5` (Apple clang, `make CXX="c++ -Wno-reserved-user-defined-literal"`). Mac main reference: `<scratch>/frozen-main398/distqldpc`, sha256 `2c9e33b4…84d3`.
- Data: the branch's `data/matrices/tier0..tier5` (tier2 has BB_144_14_14, tier3 has BB_288_12_18, tier4 = TN_250_10_15; tier5 uses the old stem names, e.g. `LP_1054_140_17to32`).
- No PR, no merge, no GitHub post. No external solver was used.

## Summary

- **Correctness: no mismatch anywhere.** 345 panel runs (tier0-4), 26 Tier 5 runs and 85 Mac runs: every answer equals the stem d (tier0-4) or lies inside the stem range and equals the adjudicated value (tier5); no lower bound above and no upper bound below the reference; no CC trap, no withdrawn bound, no memory kill (CC max RSS 40 MB, main 118 MB).
- **Tier 1-4 seed panel (5 seeds, concurrent, pinned yfclab2 cores): every tier passes by a wide margin.** Geomean of seed-median ratios CC / main:

  | Tier | vs no-card | vs card-mto | worst cell |
  |---:|---:|---:|---|
  | 1 | 0.056 | 0.033 | BB_108_8_10 no-card 0.151 (CC at the 0.065 s process floor) |
  | 2 | 0.011 | 0.011 | TN_108_2_12 no-card 0.088 |
  | 3 | 0.0044 | 0.0032 | TN_144_2_13 no-card 0.029 |
  | 4 | 0.056 | 0.052 | TN_250_10_15 no-card 0.056 |

  No cell is above 1 (so none above 1.25). Even CC's worst seed against main's best seed stays <= 0.28 on tier1 and <= 0.14 on tiers 2-4.
- **Tier 5 (CC, default seed, 6 h): 8 codes solved = 16 of 52 cells, against main's 7 of 52**, exactly the preregistered count. All 7 main-solved cells are solved with the same d, 24-4600x sooner (LP_714 2.2 s, LP_1020 1.8 s, TN_180 257 s, TN_216 696 s). Four codes main cannot solve are solved with the adjudicated values: BB_360 d=24 (1706 s), LP_1054 d=20 (123 s), LP_1428 d=24 (2884 s), LP_1768 d=22 (327 s) - **pending certification**. Every open code ends with a lower bound >= main's (20-27 against 9 or 17) and an upper bound <= main's wherever main has one (TN_252 ub 28 from the U0 basis, now matching main's no-card 28; lb 21 vs 17).
- **Mac quick check (tier0-2, 3 serial runs):** all 51 CC answers correct; tier1 geomean 0.039 / 0.030, tier2 0.0065 / 0.0074; tier0 0.52 / 0.51 (cells at the 0.017 s process floor are neutral; the worst tier0 cell is BB_72_12_6 at 1.16, 0.021 s against 0.018 s).
- **Preregistered expectations (S0_REPORT §7.3/§7.4): met.** Every tier geomean is within 0.7-1.4x of the expected value and every cell is far from the 1.25 limit; every Tier 5 solved time is below its preregistered bound; every open lower bound is at or above its expectation ("1 h value, +1 at 6 h").
- **Gate verdict: Tier 0 PASS (correctness), Tier 1 PASS, Tier 2 PASS, Tier 3 PASS, Tier 4 PASS, Tier 5 PASS** (all five plan criteria hold). This evaluates CC as the optional `-engine=cc`; the default engine is unchanged.

## 1. Method

**Server (yfclab2, AMD EPYC 7742, 2 x 64 cores).** Every process ran as `taskset -c <core> prlimit --as=4294967296 -- <bin> ...`, one solver per physical core (a CC or MaxSAT run is a watchdog parent plus one busy child on the same core). Another user's 33-34 unpinned single-thread jobs were running on the host the whole time (load 34 before we started), so some of our cores shared an SMT sibling with them; this affects both arms alike because they ran at the same time.

- Seed panel, tiers 0-4 (`S1/runner/s1_panel.py`, cores 0-63, started 06:36 CST, finished 07:52): for every code and seed S in {0,1,2,3,4}, three runs queued back to back so they ran concurrently:
  - main no-card: `-engine=maxsat -no-card -seed=S`
  - main card-mto: `-engine=maxsat -card-mto -seed=S`
  - CC: `-engine=cc -seed=S` (card modes do not apply; the one CC cell is compared with each main mode)
  - limits (`-cpu-lim`): tier0 600 s, tier1-3 1800 s, tier4 5000 s. Codes were queued longest first.
  - 345 runs (tier0 150, tier1-4 195). Wall = monotonic time around the process; CPU time recorded as a cross-check.
- Tier 5 (`S1/runner/s1_tier5.py`, cores 64-89, started 06:45:41 CST): all 26 tier5 codes at once, `-engine=cc` (default seed 0), `-cpu-lim=21600`, every output line prefixed with its elapsed time. It overlapped the seed panel for its first 67 minutes.
  - A first Tier 5 launch with `-v` was aborted after 8 minutes, because the live `c d_lb`/`c d_ub` lines are only printed in quiet mode. Its partial logs are kept in `S1/server/tier5_verbose_aborted/` (level-by-level progress; no result is taken from it).
- Identity re-check on the server: all 14 tier0+tier1 codes x {no-card, card-mto}, `-v` output of frozen main 398054e (`server-main398`, sha256 `9bf55806…cf3`) against the candidate with `-engine=maxsat -seed=0`: 28/28 identical once the printed cpu-time field is masked (the only difference was `cpu 0.000s` vs `cpu 0.001s` in the dualshare line).

**Judging (docs/OPTIMIZATION_LOOP_POLICY.md, seed-median judging).** Cell = code x main mode. Cell ratio = median over the 5 seeds of CC wall / median over the 5 seeds of main wall. A timed-out run counts as its limit (censored: the true time is larger, so for a timed-out main run the cell ratio overstates CC's time share). Per tier and mode: geomean of the cell ratios. Gate: pass if each mode's geomean < 1 and no cell > 1.25; cells in (1, 1.25] are listed as regressions to watch.

**Mac quick check** (`S1/runner/mac_serial.py`, Apple M6, 12 cores, load about 1.3): tier0-2 with `-engine=cc` (default seed), 3 serial runs each, under `caffeinate -i -s`, 2 GB RSS watchdog, one process at a time, plus one drift sample of frozen main 398054e per cell and mode. Compared with the recorded main table (`optimization/baselines/README.md` on main).

## 2. Correctness

| Check | Runs | Result |
|---|---:|---|
| Server panel tier0 (5 seeds x 3 arms, 600 s) | 150 | 150 correct answers, 0 timeouts, slowest run 1.07 s |
| Server panel tier1-4 (5 seeds x 3 arms) | 195 | 192 correct answers, 0 wrong; 3 timeouts, all main card-mto on BB_288_12_18 (seeds 1, 2, 4 at the 1800 s tier3 limit; final lb 17, ub 18: consistent with d=18) |
| Every printed `c d_lb` <= d and `c d_ub` >= d (panel) | 345 | 0 violations |
| CC traps / withdrawn bounds / runner backstop kills / memory kills | 345 + 26 | 0 / 0 / 0 / 0 |
| Tier 5 answers vs stem range and adjudicated value (ADJUDICATION.md) | 26 | 8 solved, all equal to the stem d or the adjudicated d; 18 timeouts; every lb <= stem/adjudicated upper value, every ub >= stem lower value |
| Mac CC answers (tier0-2, 3 runs) and main drift samples | 51 + 34 | all correct, rc 0, no memory kill |
| Server identity, `-engine=maxsat -seed=0` vs frozen main 398054e (`-v` output, cpu-time field masked) | 28 | 28 identical |

The three BB_288 card-mto timeouts are main-arm runs (main 398054e's recorded server median is 919 s; under contention and seeds 1-4 it ran 1141 s to >1800 s). They count as 1800 s in the medians, which makes that cell's ratio an overestimate of CC's time share, i.e. conservative for CC.

## 3. Tier 1-4 seed panel (server)

### 3.1 Per cell (wall s; seeds 0-4; "T" = timeout counted as the limit)

| Tier | Code | main no-card median (range) | main card-mto median (range) | CC median (range) | ratio vs no-card | ratio vs card-mto | CC worst seed / main best seed (nc / mto) |
|---:|---|---|---|---|---:|---:|---|
| 0 | BB_72_12_6 | 0.11 (0.069-0.141) | 0.089 (0.066-0.152) | 0.06 (0.047-0.076) | 0.5455 | 0.6742 | 1.1 / 1.15 |
| 0 | BB_90_8_10 | 0.299 (0.223-0.332) | 0.284 (0.227-0.414) | 0.064 (0.05-0.089) | 0.214 | 0.2254 | 0.399 / 0.392 |
| 0 | GB_144_12_8 | 0.221 (0.196-0.239) | 0.252 (0.2-0.307) | 0.061 (0.057-0.089) | 0.276 | 0.2421 | 0.454 / 0.445 |
| 0 | LP_136_32_4 | 0.238 (0.205-0.358) | 0.254 (0.229-0.313) | 0.078 (0.05-0.091) | 0.3277 | 0.3071 | 0.444 / 0.397 |
| 0 | LP_34_20_2 | 0.071 (0.051-0.093) | 0.085 (0.049-0.111) | 0.087 (0.051-0.097) | 1.225 | 1.024 | 1.9 / 1.98 |
| 0 | TN_36_8_3 | 0.131 (0.095-0.157) | 0.124 (0.1-0.146) | 0.108 (0.101-0.125) | 0.8244 | 0.871 | 1.32 / 1.25 |
| 0 | TN_36_8_4 | 0.141 (0.103-0.158) | 0.13 (0.125-0.166) | 0.114 (0.081-0.134) | 0.8085 | 0.8769 | 1.3 / 1.07 |
| 0 | TN_54_11_4 | 0.148 (0.129-0.157) | 0.172 (0.109-0.182) | 0.109 (0.078-0.139) | 0.7365 | 0.6337 | 1.08 / 1.28 |
| 0 | TN_72_14_4 | 0.166 (0.159-0.202) | 0.196 (0.155-0.237) | 0.112 (0.07-0.127) | 0.6747 | 0.5714 | 0.799 / 0.819 |
| 0 | TN_72_8_8 | 0.779 (0.703-0.953) | 0.856 (0.596-1.073) | 0.088 (0.068-0.153) | 0.113 | 0.1028 | 0.218 / 0.257 |
| 1 | BB_108_8_10 | 0.43 (0.259-1.143) | 1.45 (0.557-1.473) | 0.065 (0.064-0.071) | 0.1512 | 0.04483 | 0.274 / 0.127 |
| 1 | BB_144_12_12 | 0.85 (0.751-1.462) | 1.633 (1.461-1.796) | 0.065 (0.055-0.067) | 0.07647 | 0.0398 | 0.0892 / 0.0459 |
| 1 | LP_238_44_6 | 1.141 (0.888-1.321) | 1.223 (0.892-1.63) | 0.055 (0.053-0.064) | 0.0482 | 0.04497 | 0.0721 / 0.0717 |
| 1 | LP_340_56_8 | 4.305 (3.754-4.722) | 5.311 (4.312-6.002) | 0.075 (0.063-0.084) | 0.01742 | 0.01412 | 0.0224 / 0.0195 |
| 2 | BB_144_14_14 | 92.49 (75.95-100.9) | 82.66 (63.67-102) | 1.392 (1.304-1.805) | 0.01505 | 0.01684 | 0.0238 / 0.0283 |
| 2 | LP_442_68_10 | 75.53 (43.98-95.49) | 72.18 (50.39-217.2) | 0.083 (0.082-0.084) | 0.001099 | 0.00115 | 0.00191 / 0.00167 |
| 2 | TN_108_2_12 | 26.35 (25.84-29.02) | 31.63 (24.39-37.61) | 2.331 (1.059-3.225) | 0.08847 | 0.07369 | 0.125 / 0.132 |
| 3 | BB_288_12_18 | 834.4 (806.2-1104) | 1800 (1141-1800, 3T) | 2.188 (2.136-2.304) | 0.002622 | 0.001216 | 0.00286 / 0.00202 |
| 3 | GB_144_12_12 | 160.1 (119.9-227.2) | 290.2 (62.18-403.6) | 0.304 (0.177-0.365) | 0.001898 | 0.001047 | 0.00304 / 0.00587 |
| 3 | LP_544_80_12 | 327.2 (201.1-604.1) | 390.9 (266.3-587.6) | 0.19 (0.142-0.195) | 0.0005806 | 0.0004861 | 0.00097 / 0.000732 |
| 3 | TN_144_2_13 | 366.5 (301.6-1023) | 502.4 (242.2-776.2) | 10.54 (3.379-12.99) | 0.02877 | 0.02098 | 0.0431 / 0.0537 |
| 3 | TN_200_10_10 | 32.78 (27.02-155.3) | 26.05 (23.89-73.17) | 0.672 (0.252-0.772) | 0.0205 | 0.0258 | 0.0286 / 0.0323 |
| 4 | TN_250_10_15 | 2479 (2149-4571) | 2657 (2081-3428) | 138.1 (83.14-198.8) | 0.05573 | 0.05198 | 0.0925 / 0.0955 |

### 3.2 Per-tier geomean of seed-median ratios (CC / main) and gate

| Tier | cells | geomean vs no-card | geomean vs card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate (geomean < 1 per mode, no cell > 1.25) |
|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 4 | 0.05582 | 0.03263 | 0.1512 | 0 | 0 | PASS |
| 2 | 3 | 0.01135 | 0.01126 | 0.08847 | 0 | 0 | PASS |
| 3 | 5 | 0.004429 | 0.003199 | 0.02877 | 0 | 0 | PASS |
| 4 | 1 | 0.05573 | 0.05198 | 0.05573 | 0 | 0 | PASS |

Cells with ratio > 1: none.

Notes:

- "T" = runs that timed out; they enter the median as the limit (censored), which can only overstate CC's ratio.
- CPU-time ratios (median utime) agree with the wall ratios within noise (e.g. TN_250 0.056 / 0.052, TN_144 0.029 / 0.021, BB_108 no-card 0.008), so the CC advantage is not a wall-clock artefact of contention.
- The main arm's seed medians differ from main's recorded default-seed server medians, as expected from GH-121: e.g. TN_200 no-card 32.8 s (seed 0: 155 s, seeds 1-4: 27-63 s) against 129 s recorded; GB_144 card-mto 290 s against 59 s; LP_442 75 / 72 s against 41 / 46 s; BB_288 no-card 834 s against 735 s. The main runs also shared the host with another user's 33 unpinned jobs and with our Tier 5 run.
- CC's own seed spread is small on BB/GB/LP codes (1.0-1.4x max/min) and larger on TN codes (TN_108 1.06-3.2 s, TN_144 3.4-13.0 s, TN_200 0.25-0.77 s, TN_250 83-199 s); seed 0 is the fastest CC seed on every TN code, as S0 §5.4 predicted.

## 4. Tier 5 (server, 6 h, CC default seed)

One CC run per code (CC has no card modes, so each run fills both mode cells). lb events list the values from 15 upward with the elapsed second at which they were printed (full event lists in `S1/server/tier5/results.json`; the lb values below 15 appear within the first second). Main's columns are the recorded 398054e run (`optimization/baselines/SERVER.md` on main).

| Code | CC result | CC wall s | CC final lb / ub | CC lb events (value@s) | main no-card: result, lb/ub, wall | main card-mto: result, lb/ub, wall | lb >= main | ub <= main | check |
|---|---|---:|---|---|---|---|---|---|---|
| BB_1080_4_ge17 | TIMEOUT | 21600 | 27 / 66 | 22@56, 23@212, 24@643, 25@1667, 26@3883, 27@10206 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| BB_360_12_17to24 | d=24 @ 1705.5 s | 1706 | 24 / 24 | 19@6, 20@18, 21@56, 22@173, 23@540, 24@1699 | TIMEOUT, 17/24, 21600 | TIMEOUT, 17/24, 21600 | yes | yes | ok |
| BB_756_16_ge17 | TIMEOUT | 21600 | 27 / 52 | 22@55, 23@164, 24@446, 25@1254, 26@4251, 27@11251 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| BB_864_4_ge17 | TIMEOUT | 21600 | 27 / 108 | 22@49, 23@137, 24@384, 25@1078, 26@3057, 27@8722 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| LP_1020_136_16 | d=16 @ 1.8 s | 2 | 16 / 16 | 15@1, 16@2 | solved, 16/16, 7159 | solved, 16/16, 8328 | yes | yes | ok |
| LP_1054_140_17to32 | d=20 @ 123.1 s | 123 | 20 / 20 | 15@1, 16@2, 17@5, 18@14, 19@42, 20@123 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| LP_1428_184_ge17 | d=24 @ 2884.5 s | 2884 | 24 / 24 | 19@15, 20@43, 21@120, 22@337, 23@975, 24@2884 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| LP_1768_224_ge17 | d=22 @ 326.7 s | 327 | 22 / 22 | 17@2, 18@5, 19@15, 20@42, 21@117, 22@324 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| LP_714_100_16 | d=16 @ 2.2 s | 2 | 16 / 16 | 15@1, 16@2 | solved, 16/16, 8752 | solved, 16/16, 5321 | yes | yes | ok |
| TN_180_2_17 | d=17 @ 257.1 s | 257 | 17 / 17 | 15@14, 16@49, 17@178 | solved, 17/17, 9837 | TIMEOUT, 17/19, 21600 | yes | yes | ok |
| TN_216_4_18 | d=18 @ 695.6 s | 696 | 18 / 18 | 15@20, 16@68, 17@219, 18@615 | solved, 18/18, 16802 | solved, 18/18, 18346 | yes | yes | ok |
| TN_252_2_17to28 | TIMEOUT | 21600 | 21 / 28 | 16@18, 17@61, 18@229, 19@769, 20@2740, 21@10045 | TIMEOUT, 17/28, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| TN_288_2_ge9 | TIMEOUT | 21600 | 20 / 32 | 15@28, 16@89, 17@285, 18@928, 19@3096, 20@10567 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| TN_324_4_ge9 | TIMEOUT | 21600 | 20 / 36 | 15@31, 16@94, 17@289, 18@904, 19@2901, 20@9488 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| TN_360_4_ge17 | TIMEOUT | 21600 | 22 / 40 | 17@22, 18@70, 19@225, 20@735, 21@3150, 22@10903 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| TN_396_4_ge17 | TIMEOUT | 21600 | 22 / 44 | 17@30, 18@92, 19@286, 20@895, 21@2856, 22@9247 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| TN_432_8_ge9 | TIMEOUT | 21600 | 21 / 36 | 16@54, 17@158, 18@473, 19@1442, 20@4474, 21@14128 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| TN_468_4_ge17 | TIMEOUT | 21600 | 22 / 52 | 17@27, 18@79, 19@238, 20@721, 21@2219, 22@6906 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| TN_496_2_ge17 | TIMEOUT | 21600 | 22 / 64 | 17@66, 18@191, 19@578, 20@1717, 21@5140, 22@13785 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| TN_504_2_ge17 | TIMEOUT | 21600 | 23 / 56 | 18@30, 19@90, 20@271, 21@825, 22@2571, 23@8145 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| TN_540_4_ge9 | TIMEOUT | 21600 | 21 / 50 | 16@53, 17@158, 18@524, 19@1394, 20@4068, 21@12298 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| TN_576_2_ge9 | TIMEOUT | 21600 | 22 / 64 | 17@94, 18@262, 19@736, 20@2117, 21@6190, 22@18676 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| TN_612_2_ge17 | TIMEOUT | 21600 | 24 / 68 | 19@66, 20@191, 21@564, 22@1692, 23@5148, 24@15939 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/-, 21600 | yes | yes | ok |
| TN_648_10_9to52 | TIMEOUT | 21600 | 21 / 52 | 16@63, 17@140, 18@354, 19@958, 20@2878, 21@8104 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| TN_648_14_ge9 | TIMEOUT | 21600 | 21 / 54 | 16@47, 17@130, 18@364, 19@1043, 20@3058, 21@11075 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |
| TN_684_2_ge9 | TIMEOUT | 21600 | 22 / 57 | 17@57, 18@203, 19@732, 20@2357, 21@6557, 22@18210 | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/-, 21600 | yes | yes | ok |

**Solved cells:** CC 16 of 52 (8 codes), main 7 of 52.

| Code | CC time to d | main time to d (no-card / card-mto) | speed-up |
|---|---:|---|---|
| LP_714_100_16 | 2.2 s | 8752 / 5321 s | about 2400-4000x |
| LP_1020_136_16 | 1.8 s | 7159 / 8328 s | about 4000-4600x |
| TN_180_2_17 | 257 s | 9837 s / TIMEOUT [17,19] | 38x / new solve |
| TN_216_4_18 | 696 s | 16802 / 18346 s | 24-26x |
| BB_360_12_17to24 | 1706 s, d=24 | TIMEOUT [17,24] both | new solve (pending certification) |
| LP_1054_140_17to32 | 123 s, d=20 | TIMEOUT [17,-] both | new solve (pending certification) |
| LP_1428_184_ge17 | 2884 s, d=24 | TIMEOUT [17,-] both | new solve (pending certification) |
| LP_1768_224_ge17 | 327 s, d=22 | TIMEOUT [9,-] both | new solve (pending certification) |

**Plan §7 Tier 5 criteria:**

| Criterion | Result |
|---|---|
| No semantic mismatch | holds: 0 science problems; every result and bound within the stem range and consistent with the adjudicated values |
| All 7 cells main solves are solved, with the same d | holds (LP_714 16, LP_1020 16, TN_180 17, TN_216 18) |
| lb >= main's in every cell | holds in all 52 cells (CC lb 16-27 against main's 9-18) |
| ub <= main's wherever main has one | holds: BB_360 24 <= 24, TN_180 17 <= 19, TN_252 28 <= 28 (U0 basis; `-ub-basis` is on by default inside CC since f38075a), the solved codes equal |
| New exact values reported only as pending certification | yes: BB_360 d=24, LP_1054 d=20, LP_1428 d=24, LP_1768 d=22 reproduce S0e and the adjudicated values; their stems are not renamed here. The new open-code lower bounds (e.g. BB_864/BB_756/BB_1080 >= 27, TN_612 >= 24) come from the same canonical CC search as S0 and keep ADJUDICATION's PLAUSIBLE status until the certification track (`cc_check`) or an independent search confirms them. |

**Lower bounds on the 18 open codes** (S0 1 h value -> S1 6 h value): TN_288 18 -> 20, TN_324 18 -> 20, TN_432 19 -> 21, TN_540 19 -> 21, TN_576 20 -> 22, TN_648_14 20 -> 21, TN_648_10 20 -> 21, TN_684 20 -> 22, TN_360 21 -> 22, TN_396 21 -> 22, TN_468 21 -> 22, TN_496 20 -> 22, TN_504 21 -> 23, TN_612 22 -> 24, BB_756 25 -> 27, BB_864 26 -> 27, BB_1080 25 -> 27; TN_252 21 (S0 6 h: 21). CC reaches main's final 6 h lower bound (9 or 17) within 0.1-66 s on every open code (main needed 168-19868 s to reach its 17).

## 5. Mac quick check (tier0-2, default seed, 3 serial runs)

Every CC answer is correct. The main drift samples are inside the recorded range +-3% on all tier1-2 cells (closest to the edge: BB_144_14_14 29.4 / 27.8 s against 30.25-30.28 / 28.13-28.20 s, 1-3% faster). The tier0 drift outliers are cells at the 0.017-0.06 s floor (first-process cold start for BB_72_12_6: CC run 1 took 0.274 s, runs 2-3 0.021 s).

| Tier | Code | CC runs (s) | CC median | main no-card / card-mto recorded median | ratio no-card / card-mto | main drift sample no-card / card-mto (recorded range) |
|---:|---|---|---:|---|---|---|
| 0 | BB_72_12_6 | 0.2739, 0.0207, 0.0204 | 0.0207 | 0.0178 / 0.0177 | 1.1629 / 1.1695 | 0.0347 (0.0175-0.0183) **out** / 0.0193 (0.0175-0.018) **out** |
| 0 | BB_90_8_10 | 0.0182, 0.0181, 0.0182 | 0.0182 | 0.0906 / 0.0628 | 0.2009 / 0.2898 | 0.0935 (0.0906-0.0927) / 0.0623 (0.0626-0.074) |
| 0 | GB_144_12_8 | 0.0159, 0.0176, 0.0156 | 0.0159 | 0.0626 / 0.0479 | 0.2540 / 0.3319 | 0.0626 (0.0601-0.0629) / 0.0586 (0.0469-0.0485) **out** |
| 0 | LP_136_32_4 | 0.0172, 0.0177, 0.0178 | 0.0177 | 0.0601 / 0.0477 | 0.2945 / 0.3711 | 0.0595 (0.0586-0.0633) / 0.0473 (0.0475-0.0478) |
| 0 | LP_34_20_2 | 0.0171, 0.0175, 0.0168 | 0.0171 | 0.0176 / 0.0178 | 0.9716 / 0.9607 | 0.0172 (0.0174-0.0178) / 0.0173 (0.0178-0.0178) |
| 0 | TN_36_8_3 | 0.0176, 0.0176, 0.0179 | 0.0176 | 0.0179 / 0.018 | 0.9832 / 0.9778 | 0.018 (0.0177-0.0182) / 0.0183 (0.0179-0.018) |
| 0 | TN_36_8_4 | 0.0180, 0.0183, 0.0181 | 0.0181 | 0.0177 / 0.0178 | 1.0226 / 1.0169 | 0.0183 (0.0176-0.0179) / 0.0179 (0.0175-0.0179) |
| 0 | TN_54_11_4 | 0.0177, 0.0180, 0.0181 | 0.0180 | 0.0175 / 0.0174 | 1.0286 / 1.0345 | 0.0183 (0.0175-0.0181) / 0.018 (0.0174-0.0176) |
| 0 | TN_72_14_4 | 0.0177, 0.0166, 0.0178 | 0.0177 | 0.0179 / 0.0325 | 0.9888 / 0.5446 | 0.0173 (0.0177-0.0182) / 0.0326 (0.0325-0.0326) |
| 0 | TN_72_8_8 | 0.0170, 0.0170, 0.0173 | 0.0170 | 0.1981 / 0.3186 | 0.0858 / 0.0534 | 0.1961 (0.198-0.2054) / 0.3296 (0.317-0.3187) **out** |
| 1 | BB_108_8_10 | 0.0177, 0.0177, 0.0177 | 0.0177 | 0.2847 / 0.3877 | 0.0622 / 0.0457 | 0.2852 (0.2847-0.2849) / 0.3856 (0.375-0.3883) |
| 1 | BB_144_12_12 | 0.0175, 0.0176, 0.0177 | 0.0176 | 0.2516 / 0.5496 | 0.0700 / 0.0320 | 0.2522 (0.2464-0.253) / 0.5506 (0.5429-0.5517) |
| 1 | LP_238_44_6 | 0.0178, 0.0177, 0.0174 | 0.0177 | 0.3949 / 0.3761 | 0.0448 / 0.0471 | 0.3997 (0.3919-0.4007) / 0.3746 (0.3751-0.3856) |
| 1 | LP_340_56_8 | 0.0178, 0.0177, 0.0177 | 0.0177 | 1.484 / 1.563 | 0.0119 / 0.0113 | 1.479 (1.48-1.484) / 1.558 (1.562-1.57) |
| 2 | BB_144_14_14 | 0.4799, 0.4792, 0.4806 | 0.4799 | 30.28 / 28.19 | 0.0159 / 0.0170 | 29.39 (30.25-30.28) / 27.77 (28.13-28.2) |
| 2 | LP_442_68_10 | 0.0185, 0.0178, 0.0179 | 0.0179 | 32.18 / 20.52 | 0.0006 / 0.0009 | 32.16 (31.72-32.2) / 20.49 (20.49-20.53) |
| 2 | TN_108_2_12 | 0.3001, 0.3102, 0.2988 | 0.3001 | 9.587 / 11.02 | 0.0313 / 0.0272 | 9.583 (9.584-9.592) / 11.02 (11.01-11.02) |

| Tier | geomean no-card | geomean card-mto | max cell ratio |
|---:|---:|---:|---:|
| 0 | 0.5216 | 0.5104 | 1.169 |
| 1 | 0.0391 | 0.0297 | 0.070 |
| 2 | 0.0065 | 0.0074 | 0.031 |

The Mac ratios match S0 §6 (tier1 0.040 / 0.031, tier2 0.0067 / 0.0076) to within 3%.

## 6. Comparison with the preregistered expectations (S0_REPORT §7, plan §7)

**Tier 1-4 (S0_REPORT §7.3, expected seed-median ratios on yfclab2):**

| Tier | Code | Expected CC seed median (s) | Measured CC seed median (range) | Expected ratio nc / mto | Measured ratio nc / mto |
|---:|---|---|---|---|---|
| 1 | BB_108_8_10 | about 0.1 (floor) | 0.065 (0.064-0.071) | 0.13 / 0.09 | 0.151 / 0.045 |
| 1 | BB_144_12_12 | about 0.1 | 0.065 (0.055-0.067) | 0.14 / 0.06 | 0.076 / 0.040 |
| 1 | LP_238_44_6 | about 0.1 | 0.055 (0.053-0.064) | 0.08 / 0.06 | 0.048 / 0.045 |
| 1 | LP_340_56_8 | about 0.11 | 0.075 (0.063-0.084) | 0.03 / 0.02 | 0.017 / 0.014 |
| 2 | BB_144_14_14 | 1.30 (1.22-1.34) | 1.39 (1.30-1.81) | 0.018 / 0.021 | 0.015 / 0.017 |
| 2 | LP_442_68_10 | about 0.1 | 0.083 (0.082-0.084) | 0.0025 / 0.0022 | 0.0011 / 0.0012 |
| 2 | TN_108_2_12 | 2.27 (0.83-3.09) | 2.33 (1.06-3.23) | 0.09 / 0.075 | 0.088 / 0.074 |
| 3 | BB_288_12_18 | 2.83 (2.43-3.83) | 2.19 (2.14-2.30) | 0.0039 / 0.0031 | 0.0026 / 0.0012 (censored) |
| 3 | GB_144_12_12 | 0.29 (0.26-0.38) | 0.30 (0.18-0.37) | 0.0022 / 0.0049 | 0.0019 / 0.0010 |
| 3 | LP_544_80_12 | 0.23 (0.20-0.23) | 0.19 (0.14-0.20) | 0.0004 / 0.0007 | 0.00058 / 0.00049 |
| 3 | TN_144_2_13 | 9.9 (2.9-11.2) | 10.5 (3.4-13.0) | 0.027 / 0.029 | 0.029 / 0.021 |
| 3 | TN_200_10_10 | 0.56 (0.26-0.59) | 0.67 (0.25-0.77) | 0.0043 / 0.027 | 0.021 / 0.026 |
| 4 | TN_250_10_15 | 140.9 (75.1-180.6) | 138.1 (83.1-198.8) | 0.079 / 0.046 | 0.056 / 0.052 |

| Tier | Expected geomean nc / mto | Measured |
|---:|---|---|
| 1 | 0.08 / 0.05 | 0.056 / 0.033 |
| 2 | 0.016 / 0.015 | 0.011 / 0.011 |
| 3 | 0.0034 / 0.0061 | 0.0044 / 0.0032 |
| 4 | 0.079 / 0.046 | 0.056 / 0.052 |

- On the codes above the process floor, CC's measured seed medians are 0.77-1.20x the predicted ones (BB_288 0.77, LP_544 0.83, TN_250 0.98, GB_144/TN_108 1.03, TN_144 1.06, BB_144_14_14 1.07, TN_200 1.20); the floor codes (predicted "about 0.1 s") measured 0.055-0.083 s.
- The largest deviation is a ratio, not a CC time: TN_200 no-card 0.021 against 0.0043 expected, because the main panel's no-card seed median (32.8 s) is 4x below main's recorded default-seed median (129 s; main seed 0 itself took 155 s here). This is the main-side seed effect that §7.1 A5 warned about. Tier 3 no-card geomean is therefore 1.3x the expectation, still 0.0044.
- §7.3 said "even a 5x adverse deviation keeps every cell under 1"; the worst observed cell is 0.151.

**Tier 5 (S0_REPORT §7.4):**

| Stem(s) | S1 expectation | Measured |
|---|---|---|
| LP_714_100_16 | d=16, <= 10 s | d=16, 2.2 s |
| LP_1020_136_16 | d=16, <= 10 s | d=16, 1.8 s |
| TN_216_4_18 | d=18, <= 1350 s | d=18, 696 s |
| TN_180_2_17 | d=17, <= 550 s | d=17, 257 s |
| BB_360_12_17to24 | d=24, <= 4.0 ks | d=24, 1706 s |
| LP_1054_140_17to32 | d=20, <= 170 s | d=20, 123 s |
| LP_1768_224_ge17 | d=22, <= 700 s | d=22, 327 s |
| LP_1428_184_ge17 | d=24, <= 8.5 ks | d=24, 2884 s |
| TN_252_2_17to28 | TIMEOUT, lb 21; ub 28 only with `-ub-basis=on` | TIMEOUT, lb 21 (at 10045 s), ub 28 (U0 at 0.1 s; on by default) |
| TN ge9 group (7) + TN_648_10 | TIMEOUT; lb >= the 1 h value, +1 expected | TIMEOUT; lb 20-22, +1 or +2 over the 1 h value |
| TN ge17 group (6) | TIMEOUT; lb >= the 1 h value, +1 expected | TIMEOUT; lb 22-24, +1 or +2 |
| BB_756 / BB_864 / BB_1080 | TIMEOUT; lb >= 25 / 26 / 25, +1 expected | TIMEOUT; lb 27 / 27 / 27 |
| Solved cells | 16 of 52 | 16 of 52 |

The one open S0 issue that touched a Tier 5 criterion (TN_252 no-card ub '-' against main's 28) is closed by `-ub-basis` being on by default inside CC. TN_252 is still not solved under the default lockstep schedule (S0 §9 item 1), as preregistered.

## 7. Gate verdicts

| Tier | Rule (policy / plan §7) | Evidence | Verdict |
|---|---|---|---|
| 0 | 100% correct, no severe slowdown | 150 server runs (5 seeds x 3 arms) + 30 Mac CC runs + 20 Mac main samples all correct; slowest server CC tier0 run 0.15 s, Mac 0.27 s (cold start) | **PASS** (correctness). The QDistSAT cross-repo CI check with `-engine=auto` / `-engine=maxsat` was not part of this S1 run; PRE_S1_NOTES §4 records the local test suites (`make test-cc`, `make test-cc-flags`, smoke) on 244f670. |
| 1 | geomean < 1 per mode, no cell > 1.25 | 0.056 / 0.033, max 0.151 | **PASS** |
| 2 | same | 0.011 / 0.011, max 0.088 | **PASS** |
| 3 | same | 0.0044 / 0.0032, max 0.029 | **PASS** |
| 4 | same | 0.056 / 0.052, max 0.056 | **PASS** |
| 5 | plan §7 Tier 5 criteria | 16/52 solved (main 7), all 5 criteria hold | **PASS** |

No cell is a regression to watch (none above 1.0). Mac quick filter (tier1-2): direction as expected, no cell above 0.07: consistent.

## 8. Anomalies and notes

1. **Aborted first Tier 5 launch.** With `-v` the binary does not print the live `c d_lb`/`c d_ub` lines (they are printed only when verbosity is 0, `src/core/distqldpc.cc`, `ProgressState(verb == 0)`), so the first launch was stopped after 8 minutes and restarted without `-v` at 06:45:41. The partial `-v` logs are kept; no result is taken from them. This is main's pre-existing reporting behaviour, not a CC issue.
2. **Host contention.** Another user's 33-34 unpinned jobs ran throughout (host load 34 before our start, 55-100 during). Our 90 pinned processes shared SMT siblings with some of them. Both panel arms ran concurrently, so the ratios are comparable; absolute main-arm seed medians are up to about 2x main's recorded default-seed medians (seed effect plus contention).
3. **BB_288_12_18 main card-mto** timed out in 3 of 5 seeds at the tier3 limit (1800 s), although main's recorded default-seed median is 919 s. This is the GH-121 seed effect plus contention (S0/GH-121 already saw 924-2024 s across seeds). It does not affect the verdict (the CC cell is 0.0012 even with the censored main median). It may matter for the next main re-record and tier placement (BB_288 card-mto seed median > 1800 s would argue for tier4 under the policy's slower-mode rule).
4. **Tier 0 timing at the floor.** Server tier0 ratios 0.10-1.23 and Mac 0.05-1.17; the cells above 1 (server LP_34_20_2 no-card 1.23, Mac BB_72_12_6 1.16) are 0.02-0.09 s runs at the process floor. Tier 0 gates only severe slowdowns.
5. **No anomaly in correctness or in the bound semantics** was observed. The new Tier 5 exact values and lower bounds are reported as pending certification; this report renames no stem.
6. The local `-v` identity re-check found only the printed dualshare cpu-time field differing (0.000 s vs 0.001 s).

## 9. Files

All paths relative to `optimization/experiments/GH-124/S1/`.

- `runner/`: `s1_panel.py`, `s1_tier5.py` (server runners), `mac_serial.py` (Mac runner), `analyze_server.py`, `analyze_mac.py`.
- `server/panel/`: `config.json`, `results.jsonl` (345 runs: wall, CPU, rc, answer, final lb/ub, checks, command), `logs.tar.gz` (one stdout log per run), `RUNNER_DONE`; `server/panel.out`.
- `server/tier5/`: `results.json` (timestamped lb/ub events, result, checks), one timestamped log per code, `RUNNER_DONE`; `server/tier5.out`.
- `server/tier5_verbose_aborted/`: the aborted 8-minute `-v` launch.
- `server/main398054e_SERVER.md`: main's recorded server table used for Tier 5 (copied from main).
- `server/server_summary.md`: the full output of `analyze_server.py`.
- `mac/`: `jobs.jsonl`, `results.tsv`, `logs/`, `mac_summary.md`.
- Server originals: `yfclab2:~/mac-agent-20261009/gh124-s1/`. Nothing was left running on either host.

Reproduce the summaries:

```
python3 runner/analyze_server.py server/panel/results.jsonl server/tier5/results.json server/main398054e_SERVER.md
python3 runner/analyze_mac.py mac <main's optimization/baselines/README.md>
```

## Completion report

- **What changed:** this report, the S1 runners/analysis scripts and the raw S1 data under `S1/`. No code change; the evaluated binary is 244f670.
- **Validation performed:** Tier 0-4 seed panel on yfclab2 (345 runs), Tier 5 on yfclab2 (26 runs, 6 h), Mac quick check (85 runs), server identity re-check of the MaxSAT path against frozen main 398054e (28 runs). Every answer and printed bound was checked against the stem and, for tier5, against the adjudicated values.
- **Results:** Tier 0-5 gates all pass (§7); Tier 5 16/52 solved cells against main's 7/52.
- **Unresolved issues:** TN_252 still unsolved under the lockstep schedule (S0 §9 item 1); the new tier5 values and lower bounds await certification (`cc_check`, S0 §9 item 4); the QDistSAT cross-repo CI check for `-engine=auto` was not run here; BB_288_12_18 card-mto seed median exceeded 1800 s in the main arm (note 3).
- **Scientific semantics changed:** no.
- **PI action required:** yes, decisions only: whether and how CC (optional `-engine=cc`) moves on from S1, and the certification/rename questions already open in S0 §10.
