## Panel run counts and correctness

- Runs: 260 (runner errors: 0). Answers vs stem d: 252 correct, 0 wrong/bound violations, 8 without an answer (timeout).
- Runner backstop kills: 0; non-zero rc: 8; max RSS: 139 MB.
  - TIMEOUT TN_250_10_15 main-nc seed 1 (limit 5000 s, final lb 9, ub 15)
  - TIMEOUT TN_250_10_15 cand-nc seed 0 (limit 5000 s, final lb 9, ub 15)
  - TIMEOUT TN_250_10_15 cand-mto seed 3 (limit 5000 s, final lb 9, ub 15)
  - TIMEOUT TN_250_10_15 cand-nc seed 3 (limit 5000 s, final lb 9, ub 15)
  - TIMEOUT BB_288_12_18 main-mto seed 1 (limit 1800 s, final lb 17, ub 18)
  - TIMEOUT BB_288_12_18 main-mto seed 2 (limit 1800 s, final lb 17, ub 18)
  - TIMEOUT TN_250_10_15 cand-mto seed 4 (limit 5000 s, final lb 9, ub 15)
  - TIMEOUT BB_288_12_18 main-mto seed 4 (limit 1800 s, final lb 17, ub 18)

## Seed panel: per cell (wall s, median over seeds 0-4 (range); "T" = timeouts counted as the limit)

| Tier | Code | Mode | main median (range) | cand median (range) | ratio cand/main | cand worst / main best | CPU (utime) median ratio |
|---:|---|---|---|---|---:|---:|---:|
| 1 | BB_108_8_10 | no-card | 0.396 (0.244-0.775) | 0.215 (0.197-0.278) | 0.5429 | 1.14 | 0.46 |
| 1 | BB_108_8_10 | card-mto | 0.992 (0.48-1.266) | 0.217 (0.202-0.285) | 0.2188 | 0.594 | 0.181 |
| 1 | BB_144_12_12 | no-card | 0.723 (0.668-1.274) | 0.327 (0.317-0.378) | 0.4523 | 0.566 | 0.419 |
| 1 | BB_144_12_12 | card-mto | 1.431 (1.268-1.577) | 0.338 (0.316-0.36) | 0.2362 | 0.284 | 0.212 |
| 1 | LP_238_44_6 | no-card | 1.007 (0.785-1.182) | 0.804 (0.734-0.894) | 0.7984 | 1.14 | 0.805 |
| 1 | LP_238_44_6 | card-mto | 1.027 (0.794-1.39) | 0.914 (0.661-0.982) | 0.89 | 1.24 | 0.863 |
| 1 | LP_340_56_8 | no-card | 3.661 (3.253-3.92) | 2.514 (2.193-3.002) | 0.6867 | 0.923 | 0.686 |
| 1 | LP_340_56_8 | card-mto | 3.9 (3.417-4.733) | 2.912 (2.708-3.186) | 0.7467 | 0.932 | 0.754 |
| 2 | BB_144_14_14 | no-card | 81.97 (63.62-90.98) | 21.8 (18.8-43.58) | 0.266 | 0.685 | 0.265 |
| 2 | BB_144_14_14 | card-mto | 76.02 (58.93-89.38) | 25.72 (19.28-44.29) | 0.3383 | 0.752 | 0.338 |
| 2 | LP_442_68_10 | no-card | 50.22 (39.27-87.79) | 24.31 (21.43-32.41) | 0.4841 | 0.825 | 0.484 |
| 2 | LP_442_68_10 | card-mto | 64.3 (44.96-203) | 25.25 (18.71-31.24) | 0.3926 | 0.695 | 0.392 |
| 2 | TN_108_2_12 | no-card | 23.38 (20.91-26.58) | 22.64 (20.54-25.38) | 0.9681 | 1.21 | 0.97 |
| 2 | TN_108_2_12 | card-mto | 28.84 (21.58-29.96) | 25.17 (20.99-26.28) | 0.8728 | 1.22 | 0.873 |
| 3 | BB_288_12_18 | no-card | 964.9 (894.1-1432) | 297.9 (249.6-354.8) | 0.3088 | 0.397 | 0.308 |
| 3 | BB_288_12_18 | card-mto | 1800 (1144-1800, 3T) | 293.6 (283.4-416.4) | 0.1631 | 0.364 | 0.163 |
| 3 | GB_144_12_12 | no-card | 133.1 (111.7-235.5) | 67.68 (19.28-79.15) | 0.5083 | 0.708 | 0.508 |
| 3 | GB_144_12_12 | card-mto | 266.4 (55.1-392.7) | 48.92 (37.01-106.3) | 0.1836 | 1.93 | 0.183 |
| 3 | LP_544_80_12 | no-card | 398.4 (188.8-670) | 85.45 (69.45-102.3) | 0.2145 | 0.542 | 0.214 |
| 3 | LP_544_80_12 | card-mto | 410.4 (231-579.6) | 70.48 (57.62-95.69) | 0.1718 | 0.414 | 0.172 |
| 3 | TN_144_2_13 | no-card | 373.2 (299.2-1111) | 387.9 (258.1-466.1) | 1.039 | 1.56 | 1.04 |
| 3 | TN_144_2_13 | card-mto | 469.4 (234.8-767.5) | 527.4 (377.3-543.9) | 1.123 | 2.32 | 1.12 |
| 3 | TN_200_10_10 | no-card | 29.78 (22.39-138.8) | 45.44 (30.12-51.73) | 1.526 | 2.31 | 1.53 |
| 3 | TN_200_10_10 | card-mto | 22.96 (19.66-51.42) | 29.76 (25.38-267.6) | 1.296 | 13.6 | 1.3 |
| 4 | TN_250_10_15 | no-card | 2934 (2330-5000, 1T) | 4910 (3741-5000, 2T) | 1.673 | 2.15 | 1.67 |
| 4 | TN_250_10_15 | card-mto | 3786 (2380-4296) | 4672 (4447-5000, 2T) | 1.234 | 2.1 | 1.24 |

## Per-tier geomean of seed-median ratios (cand / main) and gate

| Tier | cells per mode | geomean no-card | geomean card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate (geomean < 1 per mode, no cell > 1.25) |
|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 4 | 0.6057 | 0.4305 | 0.89 | 0 | 0 | PASS |
| 2 | 3 | 0.4995 | 0.4876 | 0.9681 | 0 | 0 | PASS |
| 3 | 5 | 0.5565 | 0.3758 | 1.526 | 4 | 2 | FAIL |
| 4 | 1 | 1.673 | 1.234 | 1.673 | 2 | 1 | FAIL |

Cells with ratio > 1: T3 TN_144_2_13 no-card 1.039, T3 TN_144_2_13 card-mto 1.123, T3 TN_200_10_10 no-card 1.526, T3 TN_200_10_10 card-mto 1.296, T4 TN_250_10_15 no-card 1.673, T4 TN_250_10_15 card-mto 1.234.

## Tier 5 (candidate -frontier=on, default seed, 21600 s) vs main 398054e (SERVER.md) and the CC engine (GH-124 S1)

| Code | Mode | cand result (time) | cand final lb / ub | cand lb events (value@s, last 6) | cand ub events (value@s, last 4) | main: result, lb/ub, wall | CC: result, lb/ub, wall | cand lb vs main | cand ub vs main | check |
|---|---|---|---|---|---|---|---|---|---|---|
| BB_1080_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@2889 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/66, 21600 | = | = | ok |
| BB_1080_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@3101 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/66, 21600 | = | = | ok |
| BB_360_12_24 | card-mto | TIMEOUT | 17 / 24 | 2@0, 3@0, 5@0, 9@0, 17@86 | 30@86, 28@94, 26@200, 24@1204 | TIMEOUT, 17/24, 21600 | d=24 @ 1706 s, 24/24, 1706 | = | = | ok |
| BB_360_12_24 | no-card | TIMEOUT | 17 / 24 | 2@0, 3@0, 5@0, 9@0, 17@83 | 30@83, 28@92, 26@309, 24@479 | TIMEOUT, 17/24, 21600 | d=24 @ 1706 s, 24/24, 1706 | = | = | ok |
| BB_756_16_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@741 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/52, 21600 | = | = | ok |
| BB_756_16_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@0, 17@894 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/52, 21600 | = | = | ok |
| BB_864_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@0, 17@1100 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/108, 21600 | = | = | ok |
| BB_864_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@0, 17@944 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/108, 21600 | = | = | ok |
| LP_1020_136_16 | card-mto | d=16 @ 4511 s | 16 / 16 | 2@1, 3@1, 5@3, 9@9, 16@4511 | 16@40 | solved, 16/16, 8328 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| LP_1020_136_16 | no-card | d=16 @ 3055 s | 16 / 16 | 2@1, 3@2, 5@4, 9@19, 16@3055 | 16@71 | solved, 16/16, 7159 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| LP_1054_140_20 | card-mto | TIMEOUT | 17 / 32 | 2@1, 3@2, 5@4, 9@13, 17@11049 | 32@11358 | TIMEOUT, 17/-, 21600 | d=20 @ 123 s, 20/20, 123 | = | new | ok |
| LP_1054_140_20 | no-card | TIMEOUT | 17 / 32 | 2@1, 3@2, 5@3, 9@18, 17@10939 | 32@11380 | TIMEOUT, 17/-, 21600 | d=20 @ 123 s, 20/20, 123 | = | new | ok |
| LP_1428_184_24 | card-mto | TIMEOUT | 17 / 32 | 2@1, 3@4, 5@7, 9@16, 17@12086 | 32@21533 | TIMEOUT, 17/-, 21600 | d=24 @ 2884 s, 24/24, 2884 | = | new | ok |
| LP_1428_184_24 | no-card | TIMEOUT | 17 / - | 2@1, 3@3, 5@5, 9@14, 17@13321 |  | TIMEOUT, 17/-, 21600 | d=24 @ 2884 s, 24/24, 2884 | = | = | ok |
| LP_1768_224_22 | card-mto | TIMEOUT | 17 / - | 2@6, 3@12, 5@21, 9@62, 17@16962 |  | TIMEOUT, 9/-, 21600 | d=22 @ 327 s, 22/22, 327 | > | = | ok |
| LP_1768_224_22 | no-card | TIMEOUT | 17 / - | 2@8, 3@17, 5@33, 9@88, 17@18222 |  | TIMEOUT, 9/-, 21600 | d=22 @ 327 s, 22/22, 327 | > | = | ok |
| LP_714_100_16 | card-mto | d=16 @ 3348 s | 16 / 16 | 2@0, 3@1, 5@1, 9@6, 16@3348 | 16@21 | solved, 16/16, 5321 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| LP_714_100_16 | no-card | d=16 @ 4200 s | 16 / 16 | 2@0, 3@1, 5@2, 9@8, 16@4200 | 16@28 | solved, 16/16, 8752 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| TN_180_2_17 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@0, 9@2 |  | TIMEOUT, 17/19, 21600 | d=17 @ 257 s, 17/17, 257 | < | missing | ok |
| TN_180_2_17 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@0, 9@1 |  | solved, 17/17, 9837 | d=17 @ 257 s, 17/17, 257 | < | missing | ok |
| TN_216_4_18 | card-mto | TIMEOUT | 17 / 24 | 2@0, 3@0, 5@0, 9@2, 17@19084 | 32@19348, 24@19348 | solved, 18/18, 18346 | d=18 @ 696 s, 18/18, 696 | < | > | ok |
| TN_216_4_18 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@0, 9@2 |  | solved, 18/18, 16802 | d=18 @ 696 s, 18/18, 696 | < | missing | ok |
| TN_252_2_21 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@12404 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 21/28, 21600 | = | = | ok |
| TN_252_2_21 | no-card | TIMEOUT | 17 / 28 | 2@0, 3@0, 5@0, 9@2, 17@16351 | 28@16351 | TIMEOUT, 17/28, 21600 | TIMEOUT, 21/28, 21600 | = | = | ok |
| TN_288_2_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@8 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/32, 21600 | = | = | ok |
| TN_288_2_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@10 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/32, 21600 | = | = | ok |
| TN_324_4_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@2, 9@9 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/36, 21600 | = | = | ok |
| TN_324_4_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@2, 9@10 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/36, 21600 | = | = | ok |
| TN_360_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@8846 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/40, 21600 | = | = | ok |
| TN_360_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@4, 17@12230 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/40, 21600 | = | = | ok |
| TN_396_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@11939 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/44, 21600 | = | = | ok |
| TN_396_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@3, 17@12832 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/44, 21600 | = | = | ok |
| TN_432_8_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@3, 9@25 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/36, 21600 | = | = | ok |
| TN_432_8_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@3, 9@18 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/36, 21600 | = | = | ok |
| TN_468_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@3, 17@14070 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/52, 21600 | = | = | ok |
| TN_468_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@4, 17@11323 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/52, 21600 | = | = | ok |
| TN_496_2_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@15646 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_496_2_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@17876 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_504_2_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@1, 9@4, 17@4166 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 23/56, 21600 | = | = | ok |
| TN_504_2_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@3, 17@5434 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 23/56, 21600 | = | = | ok |
| TN_540_4_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@6, 9@26 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/50, 21600 | = | = | ok |
| TN_540_4_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@6, 9@48 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/50, 21600 | = | = | ok |
| TN_576_2_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@7, 9@38 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_576_2_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@2, 9@34 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_612_2_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@1, 9@4, 17@4325 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 24/68, 21600 | = | = | ok |
| TN_612_2_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@1, 9@6, 17@4293 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 24/68, 21600 | = | = | ok |
| TN_648_10_9to52 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@8, 9@96 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/52, 21600 | = | = | ok |
| TN_648_10_9to52 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@10, 9@62 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/52, 21600 | = | = | ok |
| TN_648_14_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@9, 9@59 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/54, 21600 | = | = | ok |
| TN_648_14_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@1, 5@18, 9@72 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/54, 21600 | = | = | ok |
| TN_684_2_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@5 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/57, 21600 | = | = | ok |
| TN_684_2_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@4 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/57, 21600 | = | = | ok |

Solved cells: cand 4 of 52, main 7 of 52, CC 16 of 52 (one CC run per code covers both mode cells).
Cells where cand is worse than main (lower lb, higher/missing ub, or unsolved where main solved): ['TN_180_2_17 card-mto', 'TN_180_2_17 no-card', 'TN_216_4_18 card-mto', 'TN_216_4_18 no-card'].
Cells where cand is better than main: 5 (LP_1054_140_20 card-mto, LP_1054_140_20 no-card, LP_1428_184_24 card-mto, LP_1768_224_22 card-mto, LP_1768_224_22 no-card).
Science problems: 0.

### Time to reach the final lower bound of main (cells where both reach the same lb >= 16), cand / main

| Code | Mode | lb | cand s | main s | ratio |
|---|---|---:|---:|---:|---:|
| BB_1080_4_ge17 | card-mto | 17 | 2889 | 2422 | 1.19 |
| BB_1080_4_ge17 | no-card | 17 | 3101 | 2423 | 1.28 |
| BB_360_12_24 | card-mto | 17 | 86 | 168 | 0.51 |
| BB_360_12_24 | no-card | 17 | 83 | 206 | 0.40 |
| BB_756_16_ge17 | card-mto | 17 | 741 | 846 | 0.88 |
| BB_756_16_ge17 | no-card | 17 | 894 | 844 | 1.06 |
| BB_864_4_ge17 | card-mto | 17 | 1100 | 1175 | 0.94 |
| BB_864_4_ge17 | no-card | 17 | 944 | 1176 | 0.80 |
| LP_1020_136_16 | card-mto | 16 | 4511 | 8328 | 0.54 |
| LP_1020_136_16 | no-card | 16 | 3055 | 7159 | 0.43 |
| LP_1054_140_20 | card-mto | 17 | 11049 | 16386 | 0.67 |
| LP_1054_140_20 | no-card | 17 | 10939 | 16379 | 0.67 |
| LP_1428_184_24 | card-mto | 17 | 12086 | 15997 | 0.76 |
| LP_1428_184_24 | no-card | 17 | 13321 | 19868 | 0.67 |
| LP_714_100_16 | card-mto | 16 | 3348 | 5321 | 0.63 |
| LP_714_100_16 | no-card | 16 | 4200 | 8751 | 0.48 |
| TN_252_2_21 | card-mto | 17 | 12404 | 8034 | 1.54 |
| TN_252_2_21 | no-card | 17 | 16351 | 8660 | 1.89 |
| TN_360_4_ge17 | card-mto | 17 | 8846 | 5154 | 1.72 |
| TN_360_4_ge17 | no-card | 17 | 12230 | 5403 | 2.26 |
| TN_396_4_ge17 | card-mto | 17 | 11939 | 4588 | 2.60 |
| TN_396_4_ge17 | no-card | 17 | 12832 | 4468 | 2.87 |
| TN_468_4_ge17 | card-mto | 17 | 14070 | 9988 | 1.41 |
| TN_468_4_ge17 | no-card | 17 | 11323 | 8437 | 1.34 |
| TN_496_2_ge17 | card-mto | 17 | 15646 | 11092 | 1.41 |
| TN_496_2_ge17 | no-card | 17 | 17876 | 9969 | 1.79 |
| TN_504_2_ge17 | card-mto | 17 | 4166 | 4866 | 0.86 |
| TN_504_2_ge17 | no-card | 17 | 5434 | 4919 | 1.10 |
| TN_612_2_ge17 | card-mto | 17 | 4325 | 4182 | 1.03 |
| TN_612_2_ge17 | no-card | 17 | 4293 | 4293 | 1.00 |

Geomean 1.011 over 30 cells.
