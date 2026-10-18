## Panel run counts and correctness (auto-on cells)

- Runs: 180 (runner errors: 0). Answers vs stem d: 177 correct, 0 wrong/bound violations, 3 without an answer (timeout).
- Runner backstop kills: 0; non-zero rc: 3; max RSS: 134 MB.
  - TIMEOUT BB_288_12_18 main-mto seed 1 (limit 1800 s, final lb 17, ub 18)
  - TIMEOUT BB_288_12_18 main-mto seed 2 (limit 1800 s, final lb 17, ub 18)
  - TIMEOUT BB_288_12_18 main-mto seed 4 (limit 1800 s, final lb 17, ub 18)

## Seed panel: per cell (wall s, median over seeds 0-4 (range); "T" = timeouts counted as the limit)

| Tier | Code | Mode | auto decision | main median (range) | cand median (range) | ratio cand/main | cand worst / main best | CPU median ratio | GH-129 on/main (replicate) |
|---:|---|---|---|---|---|---:|---:|---:|---:|
| 1 | BB_108_8_10 | no-card | on/on | 0.491 (0.258-0.78) | 0.27 (0.207-0.356) | 0.5499 | 1.38 | 0.484 | 0.5429 |
| 1 | BB_108_8_10 | card-mto | on/on | 1.273 (0.476-1.324) | 0.228 (0.22-0.295) | 0.1791 | 0.62 | 0.146 | 0.2188 |
| 1 | BB_144_12_12 | no-card | on/on | 0.773 (0.678-1.295) | 0.333 (0.322-0.364) | 0.4308 | 0.537 | 0.409 | 0.4523 |
| 1 | BB_144_12_12 | card-mto | on/on | 1.648 (1.414-2.038) | 0.339 (0.318-0.384) | 0.2057 | 0.272 | 0.19 | 0.2362 |
| 1 | LP_238_44_6 | no-card | on/on | 1.09 (0.794-1.392) | 0.851 (0.753-0.913) | 0.7807 | 1.15 | 0.76 | 0.7984 |
| 1 | LP_238_44_6 | card-mto | on/on | 1.137 (0.81-1.392) | 1.019 (0.671-1.314) | 0.8962 | 1.62 | 0.884 | 0.89 |
| 1 | LP_340_56_8 | no-card | on/on | 3.738 (3.259-5.295) | 2.615 (2.239-3.039) | 0.6996 | 0.932 | 0.703 | 0.6867 |
| 1 | LP_340_56_8 | card-mto | on/on | 4.742 (3.66-5.031) | 3.031 (2.782-3.343) | 0.6392 | 0.913 | 0.641 | 0.7467 |
| 2 | BB_144_14_14 | no-card | on/on | 83.76 (65.58-98.33) | 21.68 (18.81-37.49) | 0.2588 | 0.572 | 0.258 | 0.266 |
| 2 | BB_144_14_14 | card-mto | on/on | 79.68 (56.31-96.79) | 26.51 (19.14-43.03) | 0.3327 | 0.764 | 0.332 | 0.3383 |
| 2 | LP_442_68_10 | no-card | on/on | 70.33 (40.11-88) | 31.65 (23.48-33.87) | 0.4499 | 0.844 | 0.451 | 0.4841 |
| 2 | LP_442_68_10 | card-mto | on/on | 60.15 (47.35-219.2) | 25.9 (18.89-34.42) | 0.4306 | 0.727 | 0.427 | 0.3926 |
| 2 | TN_108_2_12 | no-card | off/off | 23.38 (20.91-26.58) (GH-129 batch) | = main (identical search) | 1 | - | - | 0.9681 |
| 2 | TN_108_2_12 | card-mto | off/off | 28.84 (21.58-29.96) (GH-129 batch) | = main (identical search) | 1 | - | - | 0.8728 |
| 3 | BB_288_12_18 | no-card | on/on | 960.1 (797.9-1113) | 232 (222.5-258.3) | 0.2416 | 0.324 | 0.241 | 0.3088 |
| 3 | BB_288_12_18 | card-mto | on/on | 1800 (989.7-1800, 3T) | 342.4 (240.4-382.1) | 0.1902 | 0.386 | 0.189 | 0.1631 |
| 3 | GB_144_12_12 | no-card | on/on | 147.2 (80.91-204) | 66.03 (19.28-79.59) | 0.4485 | 0.984 | 0.447 | 0.5083 |
| 3 | GB_144_12_12 | card-mto | on/on | 284 (56.3-362.4) | 47.63 (37.42-99.59) | 0.1677 | 1.77 | 0.168 | 0.1836 |
| 3 | LP_544_80_12 | no-card | on/on | 375.7 (271.6-592.6) | 75.68 (64.86-88.62) | 0.2014 | 0.326 | 0.201 | 0.2145 |
| 3 | LP_544_80_12 | card-mto | on/on | 500 (229.3-564.4) | 68.63 (54.48-87.07) | 0.1373 | 0.38 | 0.137 | 0.1718 |
| 3 | TN_144_2_13 | no-card | off/off | 373.2 (299.2-1111) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.039 |
| 3 | TN_144_2_13 | card-mto | off/off | 469.4 (234.8-767.5) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.123 |
| 3 | TN_200_10_10 | no-card | off/off | 29.78 (22.39-138.8) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.526 |
| 3 | TN_200_10_10 | card-mto | off/off | 22.96 (19.66-51.42) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.296 |
| 4 | TN_250_10_15 | no-card | off/off | 2934 (2330-5000, 1T) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.673 |
| 4 | TN_250_10_15 | card-mto | off/off | 3786 (2380-4296) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.234 |

## Per-tier geomean of seed-median ratios (cand / main) and gate

| Tier | cells per mode | geomean no-card | geomean card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate |
|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 4 | 0.5998 | 0.3812 | 0.8962 | 0 | 0 | PASS |
| 2 | 3 | 0.4884 | 0.5233 | 1 | 0 | 0 | PASS |
| 3 | 5 | 0.4654 | 0.3375 | 1 | 0 | 0 | PASS |
| 4 | 1 | 1 | 1 | 1 | 0 | 0 | NEUTRAL (identical to main) |

Cells with ratio > 1: none.

## Tier 5 (default seed, 21600 s): -frontier=auto vs main 398054e (SERVER.md), GH-129 -frontier=on and CC (GH-124 S1)

| Code | Mode | auto | auto result | auto lb / ub | auto lb events | auto ub events | main result, lb/ub, wall | GH-129 on result, lb/ub | CC result, lb/ub, wall | auto vs main | check |
|---|---|---|---|---|---|---|---|---|---|---|---|
| BB_1080_4_ge17 | card-mto | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@2162 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/66, 21600 | lb =, ub = | ok |
| BB_1080_4_ge17 | no-card | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@2162 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/66, 21600 | lb =, ub = | ok |
| BB_360_12_24 | card-mto | on | TIMEOUT | 17 / 24 | 5@0, 9@0, 17@70 | 28@77, 26@160, 24@923 | TIMEOUT, 17/24, 21600 | TIMEOUT, 17/24 | d=24 @ 1706 s, 24/24, 1706 | lb =, ub = | ok |
| BB_360_12_24 | no-card | on | TIMEOUT | 17 / 24 | 5@0, 9@0, 17@69 | 28@76, 26@255, 24@398 | TIMEOUT, 17/24, 21600 | TIMEOUT, 17/24 | d=24 @ 1706 s, 24/24, 1706 | lb =, ub = | ok |
| BB_756_16_ge17 | card-mto | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@554 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/52, 21600 | lb =, ub = | ok |
| BB_756_16_ge17 | no-card | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@549 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/52, 21600 | lb =, ub = | ok |
| BB_864_4_ge17 | card-mto | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@721 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/108, 21600 | lb =, ub = | ok |
| BB_864_4_ge17 | no-card | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@716 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/108, 21600 | lb =, ub = | ok |
| LP_1020_136_16 | card-mto | on | d=16 @ 2061 s | 16 / 16 | 5@5, 9@14, 16@2061 | 16@58 | solved, 16/16, 8328 | d=16 @ 4511 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |
| LP_1020_136_16 | no-card | on | d=16 @ 2246 s | 16 / 16 | 5@5, 9@19, 16@2246 | 16@63 | solved, 16/16, 7159 | d=16 @ 3055 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |
| LP_1054_140_20 | card-mto | on | TIMEOUT | 17 / 32 | 5@3, 9@12, 17@7991 | 32@8191 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/32 | d=20 @ 123 s, 20/20, 123 | lb =, ub new | ok |
| LP_1054_140_20 | no-card | on | TIMEOUT | 17 / 32 | 5@3, 9@16, 17@8052 | 32@8252 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/32 | d=20 @ 123 s, 20/20, 123 | lb =, ub new | ok |
| LP_1428_184_24 | card-mto | on | TIMEOUT | 17 / 32 | 5@4, 9@10, 17@8162 | 32@15985 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/32 | d=24 @ 2884 s, 24/24, 2884 | lb =, ub new | ok |
| LP_1428_184_24 | no-card | on | TIMEOUT | 17 / 32 | 5@4, 9@10, 17@8498 | 32@16330 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | d=24 @ 2884 s, 24/24, 2884 | lb =, ub new | ok |
| LP_1768_224_22 | card-mto | on | TIMEOUT | 17 / - | 5@10, 9@31, 17@12618 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 17/- | d=22 @ 327 s, 22/22, 327 | lb >, ub = | ok |
| LP_1768_224_22 | no-card | on | TIMEOUT | 17 / - | 5@10, 9@31, 17@12497 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 17/- | d=22 @ 327 s, 22/22, 327 | lb >, ub = | ok |
| LP_714_100_16 | card-mto | on | d=16 @ 2363 s | 16 / 16 | 5@1, 9@5, 16@2363 | 16@16 | solved, 16/16, 5321 | d=16 @ 3348 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |
| LP_714_100_16 | no-card | on | d=16 @ 2685 s | 16 / 16 | 5@1, 9@4, 16@2685 | 16@16 | solved, 16/16, 8752 | d=16 @ 4200 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |
| TN_180_2_17 | card-mto | off | = main | 17 / 19 | (main) | (main) | TIMEOUT, 17/19, 21600 | TIMEOUT, 9/- | d=17 @ 257 s, 17/17, 257 | identical | - |
| TN_180_2_17 | no-card | off | = main | 17 / 17 | (main) | (main) | solved, 17/17, 9837 | TIMEOUT, 9/- | d=17 @ 257 s, 17/17, 257 | identical | - |
| TN_216_4_18 | card-mto | off | = main | 18 / 18 | (main) | (main) | solved, 18/18, 18346 | TIMEOUT, 17/24 | d=18 @ 696 s, 18/18, 696 | identical | - |
| TN_216_4_18 | no-card | off | = main | 18 / 18 | (main) | (main) | solved, 18/18, 16802 | TIMEOUT, 9/- | d=18 @ 696 s, 18/18, 696 | identical | - |
| TN_252_2_21 | card-mto | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 21/28, 21600 | identical | - |
| TN_252_2_21 | no-card | off | = main | 17 / 28 | (main) | (main) | TIMEOUT, 17/28, 21600 | TIMEOUT, 17/28 | TIMEOUT, 21/28, 21600 | identical | - |
| TN_288_2_ge9 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 20/32, 21600 | identical | - |
| TN_288_2_ge9 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 20/32, 21600 | identical | - |
| TN_324_4_ge9 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 20/36, 21600 | identical | - |
| TN_324_4_ge9 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 20/36, 21600 | identical | - |
| TN_360_4_ge17 | card-mto | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/40, 21600 | identical | - |
| TN_360_4_ge17 | no-card | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/40, 21600 | identical | - |
| TN_396_4_ge17 | card-mto | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/44, 21600 | identical | - |
| TN_396_4_ge17 | no-card | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/44, 21600 | identical | - |
| TN_432_8_ge9 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/36, 21600 | identical | - |
| TN_432_8_ge9 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/36, 21600 | identical | - |
| TN_468_4_ge17 | card-mto | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/52, 21600 | identical | - |
| TN_468_4_ge17 | no-card | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/52, 21600 | identical | - |
| TN_496_2_ge17 | card-mto | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/64, 21600 | identical | - |
| TN_496_2_ge17 | no-card | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 22/64, 21600 | identical | - |
| TN_504_2_ge17 | card-mto | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 23/56, 21600 | identical | - |
| TN_504_2_ge17 | no-card | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 23/56, 21600 | identical | - |
| TN_540_4_ge9 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/50, 21600 | identical | - |
| TN_540_4_ge9 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/50, 21600 | identical | - |
| TN_576_2_ge9 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 22/64, 21600 | identical | - |
| TN_576_2_ge9 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 22/64, 21600 | identical | - |
| TN_612_2_ge17 | card-mto | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 24/68, 21600 | identical | - |
| TN_612_2_ge17 | no-card | off | = main | 17 / - | (main) | (main) | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 24/68, 21600 | identical | - |
| TN_648_10_9to52 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/52, 21600 | identical | - |
| TN_648_10_9to52 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/52, 21600 | identical | - |
| TN_648_14_ge9 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/54, 21600 | identical | - |
| TN_648_14_ge9 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 21/54, 21600 | identical | - |
| TN_684_2_ge9 | card-mto | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 22/57, 21600 | identical | - |
| TN_684_2_ge9 | no-card | off | = main | 9 / - | (main) | (main) | TIMEOUT, 9/-, 21600 | TIMEOUT, 9/- | TIMEOUT, 22/57, 21600 | identical | - |

Solved cells (of 52): auto 7 (re-run on-cells + main's off-cells), main 7, GH-129 on 4, CC 16 (one CC run per code covers both modes).
auto-on cells worse than main: none; better than main: 6 (LP_1054_140_20 card-mto, LP_1054_140_20 no-card, LP_1428_184_24 card-mto, LP_1428_184_24 no-card, LP_1768_224_22 card-mto, LP_1768_224_22 no-card).
Science problems in re-run cells: 0.

### Time to main's final lb (auto-on cells, lb >= 16): auto / main and GH-129 on / main

| Code | Mode | lb | auto s | GH-129 on s | main s | auto/main | on/main |
|---|---|---:|---:|---:|---:|---:|---:|
| BB_1080_4_ge17 | card-mto | 17 | 2162 | 2888.6 | 2422 | 0.89 | 1.19 |
| BB_1080_4_ge17 | no-card | 17 | 2162 | 3100.8 | 2423 | 0.89 | 1.28 |
| BB_360_12_24 | card-mto | 17 | 70 | 85.8 | 168 | 0.42 | 0.51 |
| BB_360_12_24 | no-card | 17 | 69 | 83.3 | 206 | 0.34 | 0.40 |
| BB_756_16_ge17 | card-mto | 17 | 554 | 740.8 | 846 | 0.65 | 0.88 |
| BB_756_16_ge17 | no-card | 17 | 549 | 893.9 | 844 | 0.65 | 1.06 |
| BB_864_4_ge17 | card-mto | 17 | 721 | 1099.9 | 1175 | 0.61 | 0.94 |
| BB_864_4_ge17 | no-card | 17 | 716 | 944.5 | 1176 | 0.61 | 0.80 |
| LP_1020_136_16 | card-mto | 16 | 2061 | 4510.9 | 8328 | 0.25 | 0.54 |
| LP_1020_136_16 | no-card | 16 | 2246 | 3054.6 | 7159 | 0.31 | 0.43 |
| LP_1054_140_20 | card-mto | 17 | 7991 | 11048.8 | 16386 | 0.49 | 0.67 |
| LP_1054_140_20 | no-card | 17 | 8052 | 10939.0 | 16379 | 0.49 | 0.67 |
| LP_1428_184_24 | card-mto | 17 | 8162 | 12085.5 | 15997 | 0.51 | 0.76 |
| LP_1428_184_24 | no-card | 17 | 8498 | 13321.4 | 19868 | 0.43 | 0.67 |
| LP_714_100_16 | card-mto | 16 | 2363 | 3348.4 | 5321 | 0.44 | 0.63 |
| LP_714_100_16 | no-card | 16 | 2685 | 4199.6 | 8751 | 0.31 | 0.48 |

Geomean auto/main 0.487 over 16 cells.
