# Recorded main baseline times on yfclab2 (2026-10-23)

Binary: main 12b3e05 (PR #147: -ub-pre=on default on the split MaxSAT path, -ub-search=on default in the optional CC engine; LP_442_68_10 -> tier1, BB_288_12_18 -> tier2, LP_714_100_16 -> tier3) built on yfclab2 (frozen/server-main-12b3e05/distqldpc), sha256 `c1780ce39b1f203846756704df970ef4949ab7cb142cbafdcf80e2f827786698`. tiers 0-4: runner/server_panel.py, 5 seeds (-seed=0..4; 0 = default search) per case/mode, one process per pinned physical core (taskset, cores 54-89), 4 GB cap (prlimit --as), limits tier0 600 s, tier1-3 1800 s, tier4 5000 s; the recorded time is the 5-seed median (seed-median judging, PI 2026-10-14; a timed-out seed counts as the limit); tier 5: runner/server_tier5.py, 1 run per case/mode, default seed, 6 h limit, cores 0-53, run concurrently with tiers 0-4 (panel on cores 62-89); LP_1020_136_16 additionally seeds 1-4 x both modes (6 h, cores 54-61) for a 5-seed median. Column "vs c914ef5" = this median / the main c914ef5 median (2026-10-21, 5-seed medians, git history; tier column = current tiers). Column "First ub" = the distinct first `c d_ub` values over the seeds (with the default `-ub-pre` it is the verified pre-pass word).

## Tiers 0-4 (5 seeds; the median is the reference)

| Tier | Case | Mode | Seeds | s0 | s1 | s2 | s3 | s4 | Median s | Min s | Max s | Solved | First ub | c914ef5 median s | vs c914ef5 |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---:|---:|
| 0 | BB_108_8_10 | card-mto | 5 | 0.08 | 0.1 | 0.08 | 0.08 | 0.1 | 0.08 | 0.08 | 0.1 | yes | 10 | 0.14 | 0.6 |
| 0 | BB_108_8_10 | no-card | 5 | 0.09 | 0.08 | 0.09 | 0.07 | 0.11 | 0.09 | 0.07 | 0.11 | yes | 10 | 0.13 | 0.654 |
| 0 | BB_144_12_12 | card-mto | 5 | 0.24 | 0.21 | 0.21 | 0.26 | 0.27 | 0.24 | 0.21 | 0.27 | yes | 12 | 0.34 | 0.718 |
| 0 | BB_144_12_12 | no-card | 5 | 0.2 | 0.21 | 0.22 | 0.2 | 0.25 | 0.21 | 0.2 | 0.25 | yes | 12 | 0.35 | 0.611 |
| 0 | BB_72_12_6 | card-mto | 5 | 0.08 | 0.08 | 0.13 | 0.15 | 0.14 | 0.13 | 0.08 | 0.15 | yes | 6 | 0.11 | 1.218 |
| 0 | BB_72_12_6 | no-card | 5 | 0.1 | 0.1 | 0.14 | 0.13 | 0.14 | 0.13 | 0.1 | 0.14 | yes | 6 | 0.11 | 1.155 |
| 0 | BB_90_8_10 | card-mto | 5 | 0.17 | 0.14 | 0.09 | 0.14 | 0.12 | 0.14 | 0.09 | 0.17 | yes | 10 | 0.11 | 1.246 |
| 0 | BB_90_8_10 | no-card | 5 | 0.18 | 0.16 | 0.11 | 0.11 | 0.15 | 0.15 | 0.11 | 0.18 | yes | 10 | 0.14 | 1.079 |
| 0 | GB_144_12_8 | card-mto | 5 | 0.14 | 0.13 | 0.14 | 0.17 | 0.15 | 0.14 | 0.13 | 0.17 | yes | 8 | 0.21 | 0.648 |
| 0 | GB_144_12_8 | no-card | 5 | 0.17 | 0.13 | 0.1 | 0.17 | 0.16 | 0.16 | 0.1 | 0.17 | yes | 8 | 0.2 | 0.795 |
| 0 | LP_136_32_4 | card-mto | 5 | 0.12 | 0.16 | 0.11 | 0.1 | 0.09 | 0.11 | 0.09 | 0.16 | yes | 4 | 0.18 | 0.622 |
| 0 | LP_136_32_4 | no-card | 5 | 0.15 | 0.11 | 0.12 | 0.1 | 0.15 | 0.12 | 0.1 | 0.15 | yes | 4 | 0.17 | 0.718 |
| 0 | LP_238_44_6 | card-mto | 5 | 0.39 | 0.23 | 0.34 | 0.29 | 0.28 | 0.29 | 0.23 | 0.39 | yes | 6 | 0.43 | 0.684 |
| 0 | LP_238_44_6 | no-card | 5 | 0.29 | 0.46 | 0.28 | 0.28 | 0.38 | 0.29 | 0.28 | 0.46 | yes | 6 | 0.44 | 0.652 |
| 0 | LP_34_20_2 | card-mto | 5 | 0.06 | 0.06 | 0.06 | 0.06 | 0.05 | 0.06 | 0.05 | 0.06 | yes | 2 | 0.07 | 0.843 |
| 0 | LP_34_20_2 | no-card | 5 | 0.06 | 0.07 | 0.06 | 0.07 | 0.05 | 0.06 | 0.05 | 0.07 | yes | 2 | 0.06 | 1.033 |
| 0 | TN_36_8_3 | card-mto | 5 | 0.06 | 0.06 | 0.09 | 0.1 | 0.09 | 0.09 | 0.06 | 0.1 | yes | 3 | 0.12 | 0.708 |
| 0 | TN_36_8_3 | no-card | 5 | 0.05 | 0.06 | 0.06 | 0.06 | 0.09 | 0.06 | 0.05 | 0.09 | yes | 3 | 0.13 | 0.446 |
| 0 | TN_36_8_4 | card-mto | 5 | 0.13 | 0.16 | 0.17 | 0.17 | 0.16 | 0.16 | 0.13 | 0.17 | yes | 4 | 0.16 | 1 |
| 0 | TN_36_8_4 | no-card | 5 | 0.1 | 0.09 | 0.16 | 0.16 | 0.16 | 0.16 | 0.09 | 0.16 | yes | 4 | 0.16 | 0.981 |
| 0 | TN_54_11_4 | card-mto | 5 | 0.16 | 0.13 | 0.15 | 0.15 | 0.13 | 0.15 | 0.13 | 0.16 | yes | 4 | 0.13 | 1.154 |
| 0 | TN_54_11_4 | no-card | 5 | 0.16 | 0.21 | 0.12 | 0.12 | 0.11 | 0.12 | 0.11 | 0.21 | yes | 4 | 0.13 | 0.946 |
| 0 | TN_72_14_4 | card-mto | 5 | 0.12 | 0.12 | 0.11 | 0.12 | 0.13 | 0.12 | 0.11 | 0.13 | yes | 4 | 0.11 | 1.073 |
| 0 | TN_72_14_4 | no-card | 5 | 0.15 | 0.14 | 0.1 | 0.09 | 0.13 | 0.13 | 0.09 | 0.15 | yes | 4 | 0.11 | 1.218 |
| 0 | TN_72_8_8 | card-mto | 5 | 0.79 | 0.51 | 0.43 | 0.65 | 0.59 | 0.59 | 0.43 | 0.79 | yes | 8 | 0.68 | 0.874 |
| 0 | TN_72_8_8 | no-card | 5 | 0.58 | 0.57 | 0.77 | 0.58 | 0.64 | 0.58 | 0.57 | 0.77 | yes | 8 | 0.66 | 0.88 |
| 1 | LP_340_56_8 | card-mto | 5 | 1.78 | 2.51 | 1.82 | 1.76 | 1.84 | 1.82 | 1.76 | 2.51 | yes | 8 | 1.96 | 0.931 |
| 1 | LP_340_56_8 | no-card | 5 | 1.48 | 2.25 | 1.53 | 2.63 | 2.17 | 2.17 | 1.48 | 2.63 | yes | 8 | 2.29 | 0.949 |
| 1 | LP_442_68_10 | card-mto | 5 | 4.94 | 4.43 | 3.92 | 5.37 | 4.81 | 4.81 | 3.92 | 5.37 | yes | 10 | 8.28 | 0.581 |
| 1 | LP_442_68_10 | no-card | 5 | 2.97 | 4.35 | 3.81 | 4.78 | 3.86 | 3.86 | 2.97 | 4.78 | yes | 10 | 8.32 | 0.464 |
| 2 | BB_144_14_14 | card-mto | 5 | 14.3 | 14.03 | 13.95 | 13.3 | 13.76 | 13.95 | 13.3 | 14.3 | yes | 14 | 23.97 | 0.582 |
| 2 | BB_144_14_14 | no-card | 5 | 13.65 | 14.14 | 13.61 | 13.62 | 13.45 | 13.62 | 13.45 | 14.14 | yes | 14 | 20.88 | 0.652 |
| 2 | BB_288_12_18 | card-mto | 5 | 42.82 | 45.58 | 48.08 | 55.84 | 53.79 | 48.08 | 42.82 | 55.84 | yes | 18 | 50.62 | 0.95 |
| 2 | BB_288_12_18 | no-card | 5 | 53.49 | 47.31 | 44.45 | 42.8 | 53.39 | 47.31 | 42.8 | 53.49 | yes | 18 | 54.56 | 0.867 |
| 2 | GB_144_12_12 | card-mto | 5 | 1.14 | 1.07 | 1.13 | 1.13 | 1.16 | 1.13 | 1.07 | 1.16 | yes | 12 | 43.76 | 0.026 |
| 2 | GB_144_12_12 | no-card | 5 | 1.12 | 1.06 | 1.1 | 1.11 | 1.14 | 1.11 | 1.06 | 1.14 | yes | 12 | 58.96 | 0.019 |
| 2 | LP_544_80_12 | card-mto | 5 | 15.71 | 25.66 | 19.87 | 15.94 | 20.53 | 19.87 | 15.71 | 25.66 | yes | 12 | 61.36 | 0.324 |
| 2 | LP_544_80_12 | no-card | 5 | 22.78 | 25.21 | 21.12 | 18.79 | 15.31 | 21.12 | 15.31 | 25.21 | yes | 12 | 79.73 | 0.265 |
| 2 | TN_108_2_12 | card-mto | 5 | 20.43 | 24.86 | 19 | 22.23 | 19.82 | 20.43 | 19 | 24.86 | yes | 12 | 26.75 | 0.764 |
| 2 | TN_108_2_12 | no-card | 5 | 21.21 | 23.87 | 21.45 | 20.64 | 18.7 | 21.21 | 18.7 | 23.87 | yes | 12 | 22.05 | 0.962 |
| 2 | TN_200_10_10 | card-mto | 5 | 12.18 | 13.48 | 12.06 | 12.44 | 13.7 | 12.44 | 12.06 | 13.7 | yes | 10 | 20.94 | 0.594 |
| 2 | TN_200_10_10 | no-card | 5 | 12.49 | 12.53 | 12.3 | 13.22 | 12.55 | 12.53 | 12.3 | 13.22 | yes | 10 | 27.86 | 0.45 |
| 3 | LP_714_100_16 | card-mto | 5 | 500.15 | 644.47 | 696.61 | 570.02 | 577.9 | 577.9 | 500.15 | 696.61 | yes | 16 | 626.02 | 0.923 |
| 3 | LP_714_100_16 | no-card | 5 | 705.25 | 547.82 | 660.18 | 565.39 | 506.12 | 565.39 | 506.12 | 705.25 | yes | 16 | 584.2 | 0.968 |
| 3 | TN_144_2_13 | card-mto | 5 | 67.41 | 73.06 | 72.7 | 84.97 | 67.71 | 72.7 | 67.41 | 84.97 | yes | 13 | 514.77 | 0.141 |
| 3 | TN_144_2_13 | no-card | 5 | 69.63 | 71.91 | 75.39 | 76.65 | 85.83 | 75.39 | 69.63 | 85.83 | yes | 13 | 306.12 | 0.246 |
| 4 | TN_250_10_15 | card-mto | 5 | 1654.41 | 1468.1 | 1435.05 | 1508.51 | 1464.61 | 1468.1 | 1435.05 | 1654.41 | yes | 15 | 2865.61 | 0.512 |
| 4 | TN_250_10_15 | no-card | 5 | 1485.85 | 1538.2 | 1659.7 | 1609.72 | 1532.28 | 1538.2 | 1485.85 | 1659.7 | yes | 15 | 2820.86 | 0.545 |

"T" marks a seed that reached the limit (counted as the limit in the median).

## Tier 5 (6 h, 1 run per cell, default seed)

| Case | Mode | Wall s | Result | Final lb | Final ub | First ub @ s | lb reached at (s) | vs c914ef5 (result, lb/ub, wall) |
|---|---|---:|---|---:|---:|---|---|---|
| BB_1080_4_30to48 | card-mto | 21600 | TIMEOUT | 18 | 70 | 70 @ 17 | 2@17, 4@17, 6@17, 10@17, 18@3028, 18@21600 | TIMEOUT both; lb =, ub - -> 70 |
| BB_1080_4_30to48 | no-card | 21600 | TIMEOUT | 18 | 70 | 70 @ 16 | 2@16, 4@17, 6@17, 10@17, 18@2689, 18@21600 | TIMEOUT both; lb =, ub - -> 70 |
| BB_360_12_24 | card-mto | 21600 | TIMEOUT | 18 | 24 | 24 @ 0 | 2@0, 4@0, 6@0, 10@0, 18@88, 18@21600 | TIMEOUT both; lb =, ub = |
| BB_360_12_24 | no-card | 21600 | TIMEOUT | 18 | 24 | 24 @ 0 | 2@0, 4@0, 6@0, 10@0, 18@87, 18@21600 | TIMEOUT both; lb =, ub = |
| BB_756_16_30to34 | card-mto | 21600 | TIMEOUT | 18 | 34 | 34 @ 8 | 2@8, 4@8, 6@8, 10@8, 18@702, 18@21600 | TIMEOUT both; lb =, ub - -> 34 |
| BB_756_16_30to34 | no-card | 21600 | TIMEOUT | 18 | 34 | 34 @ 8 | 2@8, 4@8, 6@8, 10@8, 18@696, 18@21600 | TIMEOUT both; lb =, ub - -> 34 |
| BB_864_4_30to40 | card-mto | 21600 | TIMEOUT | 18 | 52 | 52 @ 10 | 2@10, 4@10, 6@10, 10@11, 18@920, 18@21600 | TIMEOUT both; lb =, ub - -> 52 |
| BB_864_4_30to40 | no-card | 21600 | TIMEOUT | 18 | 52 | 52 @ 10 | 2@10, 4@10, 6@10, 10@10, 18@903, 18@21600 | TIMEOUT both; lb =, ub - -> 52 |
| LP_1020_136_16 | card-mto | 1264 | solved | 16 | 16 | 16 @ 1 | 2@1, 4@2, 6@3, 10@8, 15@1264, 16@1264 | solved 1309 s -> 1264 s (0.97x) |
| LP_1020_136_16 | no-card | 1270 | solved | 16 | 16 | 16 @ 1 | 2@1, 4@2, 6@3, 10@12, 15@1270, 16@1270 | solved 1331 s -> 1270 s (0.95x) |
| LP_1054_140_20 | card-mto | 21600 | TIMEOUT | 18 | 20 | 20 @ 3 | 2@3, 4@4, 6@6, 10@14, 18@9295, 18@21600 | TIMEOUT both; lb =, ub 32 -> 20 |
| LP_1054_140_20 | no-card | 21600 | TIMEOUT | 18 | 20 | 20 @ 3 | 2@3, 4@4, 6@6, 10@18, 18@9365, 18@21600 | TIMEOUT both; lb =, ub 32 -> 20 |
| LP_1122_148_20 | card-mto | 21600 | TIMEOUT | 18 | 20 | 20 @ 5 | 2@5, 4@6, 6@7, 10@12, 18@5853, 18@21600 | TIMEOUT both; lb =, ub 32 -> 20 |
| LP_1122_148_20 | no-card | 21600 | TIMEOUT | 18 | 20 | 20 @ 5 | 2@5, 4@6, 6@7, 10@14, 18@5859, 18@21600 | TIMEOUT both; lb =, ub 32 -> 20 |
| LP_1428_184_24 | card-mto | 21600 | TIMEOUT | 18 | 24 | 24 @ 26 | 2@26, 4@28, 6@30, 10@37, 18@9572, 18@21600 | TIMEOUT both; lb =, ub 32 -> 24 |
| LP_1428_184_24 | no-card | 21600 | TIMEOUT | 18 | 24 | 24 @ 27 | 2@27, 4@28, 6@30, 10@37, 18@9581, 18@21600 | TIMEOUT both; lb =, ub 32 -> 24 |
| LP_1768_224_22 | card-mto | 21600 | TIMEOUT | 18 | 22 | 22 @ 60 | 2@60, 4@64, 6@70, 10@97, 18@14616, 18@21600 | TIMEOUT both; lb =, ub - -> 22 |
| LP_1768_224_22 | no-card | 21600 | TIMEOUT | 18 | 22 | 22 @ 60 | 2@60, 4@64, 6@71, 10@98, 18@16190, 18@21600 | TIMEOUT both; lb =, ub - -> 22 |
| LP_2610_744_16 | card-mto | 21600 | TIMEOUT | 10 | 16 | 16 @ 12 | 2@12, 4@28, 6@66, 10@438, 10@21600 | TIMEOUT both; lb =, ub = |
| LP_2610_744_16 | no-card | 21600 | TIMEOUT | 10 | 16 | 16 @ 12 | 2@12, 4@28, 6@65, 10@437, 10@21600 | TIMEOUT both; lb =, ub = |
| TN_180_2_17 | card-mto | 11634 | solved | 17 | 17 | 17 @ 0 | 2@0, 3@0, 5@0, 9@4, 17@11634 | newly solved (c914ef5: TIMEOUT lb 17 ub 19) |
| TN_180_2_17 | no-card | 6549 | solved | 17 | 17 | 17 @ 0 | 2@0, 3@0, 5@0, 9@4, 17@6549 | solved 11486 s -> 6549 s (0.57x) |
| TN_216_4_18 | card-mto | 11593 | solved | 18 | 18 | 18 @ 0 | 2@0, 3@0, 5@0, 9@5, 17@3884, 18@11593 | solved 19298 s -> 11593 s (0.60x) |
| TN_216_4_18 | no-card | 10818 | solved | 18 | 18 | 18 @ 0 | 2@0, 3@0, 5@0, 9@5, 17@3310, 18@10818 | solved 14842 s -> 10818 s (0.73x) |
| TN_252_2_21 | card-mto | 21600 | TIMEOUT | 17 | 21 | 21 @ 0 | 2@1, 3@1, 5@1, 9@5, 17@8678, 17@21600 | TIMEOUT both; lb =, ub - -> 21 |
| TN_252_2_21 | no-card | 21600 | TIMEOUT | 17 | 21 | 21 @ 0 | 2@1, 3@1, 5@1, 9@6, 17@9602, 17@21600 | TIMEOUT both; lb =, ub 28 -> 21 |
| TN_288_2_9to24 | card-mto | 21600 | TIMEOUT | 9 | 24 | 24 @ 1 | 2@1, 3@1, 5@1, 9@12, 9@21600 | TIMEOUT both; lb =, ub - -> 24 |
| TN_288_2_9to24 | no-card | 21600 | TIMEOUT | 9 | 24 | 24 @ 1 | 2@1, 3@1, 5@2, 9@16, 9@21600 | TIMEOUT both; lb =, ub - -> 24 |
| TN_324_4_9to25 | card-mto | 21600 | TIMEOUT | 9 | 25 | 25 @ 1 | 2@1, 3@1, 5@2, 9@16, 9@21600 | TIMEOUT both; lb =, ub - -> 25 |
| TN_324_4_9to25 | no-card | 21600 | TIMEOUT | 9 | 25 | 25 @ 1 | 2@1, 3@1, 5@2, 9@16, 9@21600 | TIMEOUT both; lb =, ub - -> 25 |
| TN_360_4_17to24 | card-mto | 21600 | TIMEOUT | 17 | 24 | 24 @ 1 | 2@1, 3@1, 5@2, 9@7, 17@5284, 17@21600 | TIMEOUT both; lb =, ub - -> 24 |
| TN_360_4_17to24 | no-card | 21600 | TIMEOUT | 17 | 24 | 24 @ 1 | 2@1, 3@1, 5@2, 9@6, 17@5493, 17@21600 | TIMEOUT both; lb =, ub - -> 24 |
| TN_396_4_17to26 | card-mto | 21600 | TIMEOUT | 17 | 27 | 27 @ 1 | 2@1, 3@1, 5@1, 9@8, 17@4296, 17@21600 | TIMEOUT both; lb =, ub - -> 27 |
| TN_396_4_17to26 | no-card | 21600 | TIMEOUT | 17 | 27 | 27 @ 1 | 2@1, 3@1, 5@1, 9@9, 17@4445, 17@21600 | TIMEOUT both; lb =, ub - -> 27 |
| TN_432_8_9to29 | card-mto | 21600 | TIMEOUT | 9 | 32 | 32 @ 7 | 2@7, 3@7, 5@8, 9@29, 9@21600 | TIMEOUT both; lb =, ub - -> 32 |
| TN_432_8_9to29 | no-card | 21600 | TIMEOUT | 9 | 32 | 32 @ 7 | 2@7, 3@7, 5@10, 9@30, 9@21600 | TIMEOUT both; lb =, ub - -> 32 |
| TN_468_4_17to29 | card-mto | 21600 | TIMEOUT | 17 | 33 | 33 @ 1 | 2@1, 3@2, 5@2, 9@12, 17@10697, 17@21600 | TIMEOUT both; lb =, ub - -> 33 |
| TN_468_4_17to29 | no-card | 21600 | TIMEOUT | 17 | 33 | 33 @ 1 | 2@1, 3@2, 5@2, 9@11, 17@9211, 17@21600 | TIMEOUT both; lb =, ub - -> 33 |
| TN_496_2_17to30 | card-mto | 21600 | TIMEOUT | 17 | 34 | 34 @ 3 | 2@3, 3@3, 5@3, 9@9, 17@12854, 17@21600 | TIMEOUT both; lb =, ub - -> 34 |
| TN_496_2_17to30 | no-card | 21600 | TIMEOUT | 17 | 34 | 34 @ 3 | 2@3, 3@3, 5@3, 9@9, 17@10910, 17@21600 | TIMEOUT both; lb =, ub - -> 34 |
| TN_504_2_17to34 | card-mto | 21600 | TIMEOUT | 17 | 45 | 45 @ 4 | 2@4, 3@4, 5@4, 9@17, 17@5096, 17@21600 | TIMEOUT both; lb =, ub - -> 45 |
| TN_504_2_17to34 | no-card | 21600 | TIMEOUT | 17 | 45 | 45 @ 3 | 2@3, 3@3, 5@3, 9@10, 17@5238, 17@21600 | TIMEOUT both; lb =, ub - -> 45 |
| TN_540_4_9to34 | card-mto | 21600 | TIMEOUT | 9 | 46 | 46 @ 2 | 2@2, 3@2, 5@6, 9@35, 9@21600 | TIMEOUT both; lb =, ub - -> 46 |
| TN_540_4_9to34 | no-card | 21600 | TIMEOUT | 9 | 46 | 46 @ 2 | 2@2, 3@3, 5@6, 9@38, 9@21600 | TIMEOUT both; lb =, ub - -> 46 |
| TN_576_2_9to37 | card-mto | 21600 | TIMEOUT | 9 | 54 | 54 @ 3 | 2@3, 3@3, 5@8, 9@38, 9@21600 | TIMEOUT both; lb =, ub - -> 54 |
| TN_576_2_9to37 | no-card | 21600 | TIMEOUT | 9 | 54 | 54 @ 3 | 2@3, 3@3, 5@8, 9@43, 9@21600 | TIMEOUT both; lb =, ub - -> 54 |
| TN_612_2_17to40 | card-mto | 21600 | TIMEOUT | 17 | 62 | 62 @ 3 | 2@3, 3@3, 5@4, 9@12, 17@4386, 17@21600 | TIMEOUT both; lb =, ub - -> 62 |
| TN_612_2_17to40 | no-card | 21600 | TIMEOUT | 17 | 62 | 62 @ 3 | 2@3, 3@3, 5@4, 9@13, 17@4508, 17@21600 | TIMEOUT both; lb =, ub - -> 62 |
| TN_648_10_9to32 | card-mto | 21600 | TIMEOUT | 9 | 65 | 65 @ 3 | 2@3, 3@4, 5@9, 9@65, 9@21600 | TIMEOUT both; lb =, ub - -> 65 |
| TN_648_10_9to32 | no-card | 21600 | TIMEOUT | 9 | 65 | 65 @ 4 | 2@4, 3@4, 5@9, 9@59, 9@21600 | TIMEOUT both; lb =, ub - -> 65 |
| TN_648_14_9to28 | card-mto | 21600 | TIMEOUT | 9 | 40 | 40 @ 3 | 2@3, 3@4, 5@11, 9@65, 9@21600 | TIMEOUT both; lb =, ub - -> 40 |
| TN_648_14_9to28 | no-card | 21600 | TIMEOUT | 9 | 40 | 40 @ 3 | 2@3, 3@3, 5@9, 9@76, 9@21600 | TIMEOUT both; lb =, ub - -> 40 |
| TN_684_2_9to29 | card-mto | 21600 | TIMEOUT | 9 | 31 | 31 @ 10 | 2@10, 3@10, 5@11, 9@25, 9@21600 | TIMEOUT both; lb =, ub - -> 31 |
| TN_684_2_9to29 | no-card | 21600 | TIMEOUT | 9 | 31 | 31 @ 10 | 2@10, 3@10, 5@11, 9@26, 9@21600 | TIMEOUT both; lb =, ub - -> 31 |

### Tier 5 extra seeds (5-seed median; seed 0 = the default-seed run above, seeds 1-4 run concurrently with it, 6 h each)

| Case | Mode | s0 | s1 | s2 | s3 | s4 | Median s | Solved | First ub per seed |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| LP_1020_136_16 | card-mto | 1264 | 877 | 905 | 795 | 781 | 877 | yes | s0 16@1, s1 16@1, s2 16@2, s3 16@2, s4 16@2 |
| LP_1020_136_16 | no-card | 1270 | 878 | 902 | 796 | 790 | 878 | yes | s0 16@1, s1 16@1, s2 16@2, s3 16@2, s4 16@2 |

## Tier placement re-check (rule PI 2026-10-12: slower-mode median on this server; <1 s t0, 1-10 t1, 10-100 t2, 100-2000 t3, 2000-5000 t4, else t5)

| Case | Current tier | Slower mode | Slower-mode median s | Rule tier | Move? |
|---|---:|---|---:|---:|---|
| BB_108_8_10 | 0 | no-card | 0.09 | 0 | no |
| BB_144_12_12 | 0 | card-mto | 0.24 | 0 | no |
| BB_72_12_6 | 0 | card-mto | 0.13 | 0 | no |
| BB_90_8_10 | 0 | no-card | 0.15 | 0 | no |
| GB_144_12_8 | 0 | no-card | 0.16 | 0 | no |
| LP_136_32_4 | 0 | no-card | 0.12 | 0 | no |
| LP_238_44_6 | 0 | card-mto | 0.29 | 0 | no |
| LP_34_20_2 | 0 | no-card | 0.06 | 0 | no |
| TN_36_8_3 | 0 | card-mto | 0.09 | 0 | no |
| TN_36_8_4 | 0 | card-mto | 0.16 | 0 | no |
| TN_54_11_4 | 0 | card-mto | 0.15 | 0 | no |
| TN_72_14_4 | 0 | no-card | 0.13 | 0 | no |
| TN_72_8_8 | 0 | card-mto | 0.59 | 0 | no |
| LP_340_56_8 | 1 | no-card | 2.17 | 1 | no |
| LP_442_68_10 | 1 | card-mto | 4.81 | 1 | no |
| BB_144_14_14 | 2 | card-mto | 13.95 | 2 | no |
| BB_288_12_18 | 2 | card-mto | 48.08 | 2 | no |
| GB_144_12_12 | 2 | card-mto | 1.13 | 1 | tier2 -> tier1 |
| LP_544_80_12 | 2 | no-card | 21.12 | 2 | no |
| TN_108_2_12 | 2 | no-card | 21.21 | 2 | no |
| TN_200_10_10 | 2 | no-card | 12.53 | 2 | no |
| LP_714_100_16 | 3 | card-mto | 577.90 | 3 | no |
| TN_144_2_13 | 3 | no-card | 75.39 | 2 | tier3 -> tier2 |
| TN_250_10_15 | 4 | no-card | 1538.20 | 3 | tier4 -> tier3 |
| BB_1080_4_30to48 | 5 | card-mto | unsolved | 5 | no |
| BB_360_12_24 | 5 | card-mto | unsolved | 5 | no |
| BB_756_16_30to34 | 5 | card-mto | unsolved | 5 | no |
| BB_864_4_30to40 | 5 | card-mto | unsolved | 5 | no |
| LP_1020_136_16 | 5 | no-card | 877.70 | 3 | tier5 -> tier3 |
| LP_1054_140_20 | 5 | card-mto | unsolved | 5 | no |
| LP_1122_148_20 | 5 | card-mto | unsolved | 5 | no |
| LP_1428_184_24 | 5 | card-mto | unsolved | 5 | no |
| LP_1768_224_22 | 5 | card-mto | unsolved | 5 | no |
| LP_2610_744_16 | 5 | card-mto | unsolved | 5 | no |
| TN_180_2_17 | 5 | card-mto | 11634.00 | 5 | no |
| TN_216_4_18 | 5 | card-mto | 11592.70 | 5 | no |
| TN_252_2_21 | 5 | card-mto | unsolved | 5 | no |
| TN_288_2_9to24 | 5 | card-mto | unsolved | 5 | no |
| TN_324_4_9to25 | 5 | card-mto | unsolved | 5 | no |
| TN_360_4_17to24 | 5 | card-mto | unsolved | 5 | no |
| TN_396_4_17to26 | 5 | card-mto | unsolved | 5 | no |
| TN_432_8_9to29 | 5 | card-mto | unsolved | 5 | no |
| TN_468_4_17to29 | 5 | card-mto | unsolved | 5 | no |
| TN_496_2_17to30 | 5 | card-mto | unsolved | 5 | no |
| TN_504_2_17to34 | 5 | card-mto | unsolved | 5 | no |
| TN_540_4_9to34 | 5 | card-mto | unsolved | 5 | no |
| TN_576_2_9to37 | 5 | card-mto | unsolved | 5 | no |
| TN_612_2_17to40 | 5 | card-mto | unsolved | 5 | no |
| TN_648_10_9to32 | 5 | card-mto | unsolved | 5 | no |
| TN_648_14_9to28 | 5 | card-mto | unsolved | 5 | no |
| TN_684_2_9to29 | 5 | card-mto | unsolved | 5 | no |

Codes that the rule would move (listed only, not moved): GB_144_12_12 (tier2 -> tier1, card-mto 1 s); TN_144_2_13 (tier3 -> tier2, no-card 75 s); TN_250_10_15 (tier4 -> tier3, no-card 1538 s); LP_1020_136_16 (tier5 -> tier3, no-card 878 s). Tier 5 rows use a single default-seed run (not a 5-seed median) except LP_1020_136_16 (5-seed median, extra-seed table above); for cells with timed-out seeds the median counts the limit.

Notes:
- Replaces the main c914ef5 table (2026-10-21) after PR #147 (`-ub-pre=on` default on the split MaxSAT path; `-ub-search=on` default inside the optional CC engine, not used by these default `-engine=maxsat` runs) was merged; old table is in git history. PR #147 also re-tiered LP_442_68_10 -> tier1, BB_288_12_18 -> tier2, LP_714_100_16 -> tier3 (tier column = current tiers; comparisons by stem).
- vs main c914ef5, geomean of per-cell median ratios (tiers 0-4, current tiers): tier0 no-card 0.827 tier0 card-mto 0.847 tier1 no-card 0.664 tier1 card-mto 0.735 tier2 no-card 0.327 tier2 card-mto 0.358 tier3 no-card 0.488 tier3 card-mto 0.361 tier4 no-card 0.545 tier4 card-mto 0.512.
- `-ub-pre=on` runs a verified randomized low-weight-logical pre-pass (at most 60 s; a half stops earlier after 16 re-hits or a plateau; seeded by -seed) before the interleaved search on every split MaxSAT run, so every cell (all families, both modes) runs a changed search; a pre-pass word U0 lets Phase 1 skip caps >= U0 - 1 and Phase 2 probe at U0 - 1.
- Tier 1-4 cells faster than 0.90x: LP_442_68_10 card-mto 0.58, LP_442_68_10 no-card 0.46, BB_144_14_14 card-mto 0.58, BB_144_14_14 no-card 0.65, BB_288_12_18 no-card 0.87, GB_144_12_12 card-mto 0.03, GB_144_12_12 no-card 0.02, LP_544_80_12 card-mto 0.32, LP_544_80_12 no-card 0.26, TN_108_2_12 card-mto 0.76, TN_200_10_10 card-mto 0.59, TN_200_10_10 no-card 0.45, TN_144_2_13 card-mto 0.14, TN_144_2_13 no-card 0.25, TN_250_10_15 card-mto 0.51, TN_250_10_15 no-card 0.55. Cells slower than 1.10x: none.
- Tier 0-4 seeds that reached the limit: none.
- Tier 5: 6 of 54 cells solved within 6 h (c914ef5: 5 of 54 comparable cells). Cells better than c914ef5 (newly solved or tighter bound): BB_1080_4_30to48 card-mto, BB_1080_4_30to48 no-card, BB_756_16_30to34 card-mto, BB_756_16_30to34 no-card, BB_864_4_30to40 card-mto, BB_864_4_30to40 no-card, LP_1054_140_20 card-mto, LP_1054_140_20 no-card, LP_1122_148_20 card-mto, LP_1122_148_20 no-card, LP_1428_184_24 card-mto, LP_1428_184_24 no-card, LP_1768_224_22 card-mto, LP_1768_224_22 no-card, TN_180_2_17 card-mto, TN_252_2_21 card-mto, TN_252_2_21 no-card, TN_288_2_9to24 card-mto, TN_288_2_9to24 no-card, TN_324_4_9to25 card-mto, TN_324_4_9to25 no-card, TN_360_4_17to24 card-mto, TN_360_4_17to24 no-card, TN_396_4_17to26 card-mto, TN_396_4_17to26 no-card, TN_432_8_9to29 card-mto, TN_432_8_9to29 no-card, TN_468_4_17to29 card-mto, TN_468_4_17to29 no-card, TN_496_2_17to30 card-mto, TN_496_2_17to30 no-card, TN_504_2_17to34 card-mto, TN_504_2_17to34 no-card, TN_540_4_9to34 card-mto, TN_540_4_9to34 no-card, TN_576_2_9to37 card-mto, TN_576_2_9to37 no-card, TN_612_2_17to40 card-mto, TN_612_2_17to40 no-card, TN_648_10_9to32 card-mto, TN_648_10_9to32 no-card, TN_648_14_9to28 card-mto, TN_648_14_9to28 no-card, TN_684_2_9to29 card-mto, TN_684_2_9to29 no-card. Worse: none.
- Lower-bound ladders: on BB/LP halves (odd column weights, `-oddcap-skip=on`) the doubling phase probes caps 2,4,8,16,32, and a NONE at cap 2t certifies lb 2t+2 (ladder 2/4/6/10/18); TN halves keep the ladder 2/3/5/9/17 (caps 1,2,4,8,16). With a pre-pass word U0, Phase 1 skips caps >= U0 - 1, so the lb ladder can stop below 18/17 and the remaining gap is closed by Phase 2 probes at U - 1.
- Stem names: PR #149 (merged after these runs) renamed tier 5 stems; tables use the current names, raw files keep the run names (run name -> current name): BB_1080_4_ge30 -> BB_1080_4_30to48, BB_756_16_ge30 -> BB_756_16_30to34, BB_864_4_ge30 -> BB_864_4_30to40, TN_288_2_ge9 -> TN_288_2_9to24, TN_324_4_ge9 -> TN_324_4_9to25, TN_360_4_ge17 -> TN_360_4_17to24, TN_396_4_ge17 -> TN_396_4_17to26, TN_432_8_ge9 -> TN_432_8_9to29, TN_468_4_ge17 -> TN_468_4_17to29, TN_496_2_ge17 -> TN_496_2_17to30, TN_504_2_ge17 -> TN_504_2_17to34, TN_540_4_ge9 -> TN_540_4_9to34, TN_576_2_ge9 -> TN_576_2_9to37, TN_612_2_ge17 -> TN_612_2_17to40, TN_648_10_9to52 -> TN_648_10_9to32, TN_648_14_ge9 -> TN_648_14_9to28, TN_684_2_ge9 -> TN_684_2_9to29. Answers and bounds were checked against both names.
- Host load: started 2026-10-23 07:44 (+0800) after the GH-146 session's processes were gone (pgrep -fc gh146 = 0 twice, 2 min apart); tier 5 on cores 0-53 (6 h), LP_1020_136_16 seeds 1-4 on cores 54-61, panel on cores 62-89 (done after ~32 min); other users ran ~10-25 unpinned jobs (raw/main-12b3e05/server_load_samples.txt, every 60 s).
- **Basis (PI 2026-10-23):** no baseline will be recorded for main e52d15b (PR #149: finder default -ub-isd=stern, tier 5 stems renamed to {lb}to{ub}); these main 12b3e05 tables remain the official comparison basis. Tier 5 upper bounds after e52d15b are in optimization/experiments/GH-146/REPORT.md.
- Correctness: panel 240 runs (0 runner errors), every answer equals the stem distance and no bound crosses it; tier 5 54 runs + 8 extra-seed runs, every answer and bound consistent with the stems; the first `c d_ub` of every run (the `-ub-pre` word) is >= the stem distance / stem lower bound.
