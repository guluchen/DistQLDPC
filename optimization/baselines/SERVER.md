# Recorded main baseline times on yfclab2 (2026-10-21)

Binary: main c914ef5 (PR #137: -oddcap-skip=on default; PR #136 re-tier) built on yfclab2 (frozen/server-main-c914ef5/distqldpc), sha256 `8e2903830e2bf94fe9ba050993a024c2b538232f600ec3663ace5c4d53edfe17`. tiers 0-4: runner/server_panel.py, 5 seeds (-seed=0..4; 0 = default search) per case/mode, one process per pinned physical core (taskset, cores 54-89), 4 GB cap (prlimit --as), limits tier0 600 s, tier1-3 1800 s, tier4 5000 s; the recorded time is the 5-seed median (seed-median judging, PI 2026-10-14; a timed-out seed counts as the limit); tier 5: runner/server_tier5.py, 1 run per case/mode, default seed, 6 h limit, cores 0-53, run concurrently with tiers 0-4. Column "vs cbb0642" = this median / the main cbb0642 median (2026-10-18, 5-seed medians, git history; tier column = current tiers; LP_714_100_16 was tier 5 then, its cbb0642 value is one default-seed run).

## Tiers 0-4 (5 seeds; the median is the reference)

| Tier | Case | Mode | Seeds | s0 | s1 | s2 | s3 | s4 | Median s | Min s | Max s | Solved | cbb0642 median s | vs cbb0642 |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|
| 0 | BB_108_8_10 | card-mto | 5 | 0.14 | 0.12 | 0.14 | 0.13 | 0.14 | 0.14 | 0.12 | 0.14 | yes | 0.24 | 0.588 |
| 0 | BB_108_8_10 | no-card | 5 | 0.13 | 0.13 | 0.16 | 0.13 | 0.13 | 0.13 | 0.13 | 0.16 | yes | 0.23 | 0.57 |
| 0 | BB_144_12_12 | card-mto | 5 | 0.32 | 0.34 | 0.31 | 0.42 | 0.44 | 0.34 | 0.31 | 0.44 | yes | 0.32 | 1.056 |
| 0 | BB_144_12_12 | no-card | 5 | 0.31 | 0.31 | 0.35 | 0.42 | 0.49 | 0.35 | 0.31 | 0.49 | yes | 0.34 | 1.024 |
| 0 | BB_72_12_6 | card-mto | 5 | 0.07 | 0.11 | 0.09 | 0.15 | 0.16 | 0.11 | 0.07 | 0.16 | yes | 0.07 | 1.629 |
| 0 | BB_72_12_6 | no-card | 5 | 0.09 | 0.07 | 0.11 | 0.15 | 0.18 | 0.11 | 0.07 | 0.18 | yes | 0.06 | 1.9 |
| 0 | BB_90_8_10 | card-mto | 5 | 0.14 | 0.11 | 0.11 | 0.11 | 0.18 | 0.11 | 0.11 | 0.18 | yes | 0.13 | 0.862 |
| 0 | BB_90_8_10 | no-card | 5 | 0.16 | 0.14 | 0.13 | 0.09 | 0.15 | 0.14 | 0.09 | 0.16 | yes | 0.13 | 1.085 |
| 0 | GB_144_12_8 | card-mto | 5 | 0.21 | 0.17 | 0.22 | 0.18 | 0.24 | 0.21 | 0.17 | 0.24 | yes | 0.13 | 1.646 |
| 0 | GB_144_12_8 | no-card | 5 | 0.21 | 0.15 | 0.15 | 0.21 | 0.2 | 0.2 | 0.15 | 0.21 | yes | 0.14 | 1.457 |
| 0 | LP_136_32_4 | card-mto | 5 | 0.18 | 0.23 | 0.17 | 0.19 | 0.16 | 0.18 | 0.16 | 0.23 | yes | 0.19 | 0.958 |
| 0 | LP_136_32_4 | no-card | 5 | 0.17 | 0.2 | 0.15 | 0.17 | 0.23 | 0.17 | 0.15 | 0.23 | yes | 0.16 | 1.044 |
| 0 | LP_238_44_6 | card-mto | 5 | 0.62 | 0.33 | 0.38 | 0.56 | 0.43 | 0.43 | 0.33 | 0.62 | yes | 0.85 | 0.509 |
| 0 | LP_238_44_6 | no-card | 5 | 0.44 | 0.48 | 0.33 | 0.44 | 0.56 | 0.44 | 0.33 | 0.56 | yes | 0.78 | 0.563 |
| 0 | LP_34_20_2 | card-mto | 5 | 0.08 | 0.07 | 0.06 | 0.06 | 0.07 | 0.07 | 0.06 | 0.08 | yes | 0.06 | 1.1 |
| 0 | LP_34_20_2 | no-card | 5 | 0.07 | 0.06 | 0.06 | 0.06 | 0.06 | 0.06 | 0.06 | 0.07 | yes | 0.05 | 1.16 |
| 0 | TN_36_8_3 | card-mto | 5 | 0.1 | 0.12 | 0.16 | 0.14 | 0.11 | 0.12 | 0.1 | 0.16 | yes | 0.07 | 1.657 |
| 0 | TN_36_8_3 | no-card | 5 | 0.1 | 0.13 | 0.11 | 0.14 | 0.13 | 0.13 | 0.1 | 0.14 | yes | 0.08 | 1.663 |
| 0 | TN_36_8_4 | card-mto | 5 | 0.17 | 0.16 | 0.16 | 0.16 | 0.1 | 0.16 | 0.1 | 0.17 | yes | 0.07 | 2.329 |
| 0 | TN_36_8_4 | no-card | 5 | 0.14 | 0.16 | 0.17 | 0.17 | 0.12 | 0.16 | 0.12 | 0.17 | yes | 0.07 | 2.3 |
| 0 | TN_54_11_4 | card-mto | 5 | 0.18 | 0.13 | 0.14 | 0.13 | 0.11 | 0.13 | 0.11 | 0.18 | yes | 0.1 | 1.31 |
| 0 | TN_54_11_4 | no-card | 5 | 0.15 | 0.15 | 0.13 | 0.12 | 0.1 | 0.13 | 0.1 | 0.15 | yes | 0.08 | 1.625 |
| 0 | TN_72_14_4 | card-mto | 5 | 0.11 | 0.15 | 0.1 | 0.09 | 0.16 | 0.11 | 0.09 | 0.16 | yes | 0.14 | 0.8 |
| 0 | TN_72_14_4 | no-card | 5 | 0.14 | 0.11 | 0.08 | 0.08 | 0.16 | 0.11 | 0.08 | 0.16 | yes | 0.13 | 0.862 |
| 0 | TN_72_8_8 | card-mto | 5 | 0.86 | 0.61 | 0.52 | 0.74 | 0.68 | 0.68 | 0.52 | 0.86 | yes | 0.68 | 0.994 |
| 0 | TN_72_8_8 | no-card | 5 | 0.65 | 0.59 | 0.82 | 0.82 | 0.66 | 0.66 | 0.59 | 0.82 | yes | 0.64 | 1.031 |
| 1 | LP_340_56_8 | card-mto | 5 | 1.93 | 2.66 | 2.03 | 1.96 | 1.96 | 1.96 | 1.93 | 2.66 | yes | 3.12 | 0.628 |
| 1 | LP_340_56_8 | no-card | 5 | 1.65 | 2.44 | 1.62 | 2.62 | 2.29 | 2.29 | 1.62 | 2.62 | yes | 2.78 | 0.826 |
| 2 | BB_144_14_14 | card-mto | 5 | 18.37 | 40.91 | 38.87 | 17.87 | 23.97 | 23.97 | 17.87 | 40.91 | yes | 24.65 | 0.973 |
| 2 | BB_144_14_14 | no-card | 5 | 17.87 | 21.61 | 34.4 | 17.31 | 20.88 | 20.88 | 17.31 | 34.4 | yes | 22.3 | 0.936 |
| 2 | GB_144_12_12 | card-mto | 5 | 43.76 | 37.23 | 34.53 | 95.43 | 79.56 | 43.76 | 34.53 | 95.43 | yes | 45.29 | 0.966 |
| 2 | GB_144_12_12 | no-card | 5 | 58.96 | 25.07 | 17.94 | 70.08 | 60.4 | 58.96 | 17.94 | 70.08 | yes | 60.65 | 0.972 |
| 1 | LP_442_68_10 | card-mto | 5 | 8.28 | 8.15 | 5.88 | 8.95 | 8.37 | 8.28 | 5.88 | 8.95 | yes | 25.32 | 0.327 |
| 1 | LP_442_68_10 | no-card | 5 | 6.42 | 9.11 | 9.54 | 6.3 | 8.32 | 8.32 | 6.3 | 9.54 | yes | 23.96 | 0.347 |
| 2 | LP_544_80_12 | card-mto | 5 | 71.14 | 79.03 | 61.01 | 61.36 | 46.48 | 61.36 | 46.48 | 79.03 | yes | 69.12 | 0.888 |
| 2 | LP_544_80_12 | no-card | 5 | 100 | 81.49 | 59.83 | 77.29 | 79.73 | 79.73 | 59.83 | 100 | yes | 85.77 | 0.93 |
| 2 | TN_108_2_12 | card-mto | 5 | 26.75 | 25.8 | 20.24 | 27.77 | 27.12 | 26.75 | 20.24 | 27.77 | yes | 30.3 | 0.883 |
| 2 | TN_108_2_12 | no-card | 5 | 22.05 | 24.99 | 22.37 | 21.7 | 19.54 | 22.05 | 19.54 | 24.99 | yes | 24.7 | 0.893 |
| 2 | TN_200_10_10 | card-mto | 5 | 18 | 18.81 | 45.78 | 29.86 | 20.94 | 20.94 | 18 | 45.78 | yes | 21.72 | 0.964 |
| 2 | TN_200_10_10 | no-card | 5 | 126.06 | 20.87 | 24.08 | 49.81 | 27.86 | 27.86 | 20.87 | 126.06 | yes | 27.82 | 1.001 |
| 2 | BB_288_12_18 | card-mto | 5 | 45.32 | 45.39 | 50.62 | 64.65 | 58.83 | 50.62 | 45.32 | 64.65 | yes | 244.55 | 0.207 |
| 2 | BB_288_12_18 | no-card | 5 | 54.56 | 47.61 | 72.62 | 47.32 | 58.57 | 54.56 | 47.32 | 72.62 | yes | 231.47 | 0.236 |
| 3 | TN_144_2_13 | card-mto | 5 | 514.77 | 610.75 | 659.02 | 423.98 | 205.94 | 514.77 | 205.94 | 659.02 | yes | 422.99 | 1.217 |
| 3 | TN_144_2_13 | no-card | 5 | 385.67 | 262 | 292.5 | 306.12 | 972.97 | 306.12 | 262 | 972.97 | yes | 300.95 | 1.017 |
| 3 | LP_714_100_16 | card-mto | 5 | 530.17 | 741.27 | 723.75 | 587.8 | 626.02 | 626.02 | 530.17 | 741.27 | yes | 2662.9 | 0.235 |
| 3 | LP_714_100_16 | no-card | 5 | 741.1 | 582.52 | 679.35 | 584.2 | 547.29 | 584.2 | 547.29 | 741.1 | yes | 2670.3 | 0.219 |
| 4 | TN_250_10_15 | card-mto | 5 | 4012.9 | 2865.61 | 3693.73 | 2766.8 | 2360.07 | 2865.61 | 2360.07 | 4012.9 | yes | 2694.86 | 1.063 |
| 4 | TN_250_10_15 | no-card | 5 | 2346.59 | 5000T | 3504.53 | 2338.84 | 2820.86 | 2820.86 | 2338.84 | 5000 | 4/5 | 4419.18 | 0.638 |

"T" marks a seed that reached the limit (counted as the limit in the median).

## Tier 5 (6 h, 1 run per cell, default seed)

| Case | Mode | Wall s | Result | Final lb | Final ub | lb reached at (s) | vs cbb0642 (result, lb/ub, wall) |
|---|---|---:|---|---:|---:|---|---|
| BB_1080_4_ge30 | card-mto | 21600 | TIMEOUT | 18 | - | 2@0, 4@0, 6@0, 10@1, 18@2720, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| BB_1080_4_ge30 | no-card | 21600 | TIMEOUT | 18 | - | 2@0, 4@0, 6@0, 10@1, 18@3516, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| BB_360_12_24 | card-mto | 21600 | TIMEOUT | 18 | 24 | 2@0, 4@0, 6@0, 10@0, 18@89, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| BB_360_12_24 | no-card | 21600 | TIMEOUT | 18 | 24 | 2@0, 4@0, 6@0, 10@0, 18@88, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| BB_756_16_ge30 | card-mto | 21600 | TIMEOUT | 18 | - | 2@0, 4@0, 6@0, 10@0, 18@695, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| BB_756_16_ge30 | no-card | 21600 | TIMEOUT | 18 | - | 2@0, 4@0, 6@0, 10@1, 18@752, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| BB_864_4_ge30 | card-mto | 21600 | TIMEOUT | 18 | - | 2@0, 4@0, 6@0, 10@0, 18@941, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| BB_864_4_ge30 | no-card | 21600 | TIMEOUT | 18 | - | 2@0, 4@0, 6@0, 10@0, 18@904, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1020_136_16 | card-mto | 1309 | solved | 16 | 16 | 2@0, 4@1, 6@2, 10@7, 15@1309, 16@1309 | solved 2316 s -> 1309 s (0.57x) |
| LP_1020_136_16 | no-card | 1331 | solved | 16 | 16 | 2@0, 4@1, 6@2, 10@12, 15@1331, 16@1331 | solved 8955 s -> 1331 s (0.15x) |
| LP_1054_140_20 | card-mto | 21600 | TIMEOUT | 18 | 32 | 2@0, 4@1, 6@2, 10@10, 18@9275, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1054_140_20 | no-card | 21600 | TIMEOUT | 18 | 32 | 2@0, 4@1, 6@3, 10@15, 18@9268, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1122_148_20 | card-mto | 21600 | TIMEOUT | 18 | 32 | 2@0, 4@1, 6@2, 10@8, 18@6154, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1122_148_20 | no-card | 21600 | TIMEOUT | 18 | 32 | 2@0, 4@1, 6@3, 10@16, 18@6816, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1428_184_24 | card-mto | 21600 | TIMEOUT | 18 | 32 | 2@0, 4@2, 6@5, 10@12, 18@9638, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1428_184_24 | no-card | 21600 | TIMEOUT | 18 | 32 | 2@0, 4@2, 6@4, 10@12, 18@9590, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1768_224_22 | card-mto | 21600 | TIMEOUT | 18 | - | 2@0, 4@4, 6@10, 10@37, 18@15573, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_1768_224_22 | no-card | 21600 | TIMEOUT | 18 | - | 2@0, 4@5, 6@14, 10@49, 18@16150, 18@21600 | TIMEOUT both; lb 17 -> 18, ub = |
| LP_2610_744_16 | card-mto | 21600 | TIMEOUT | 10 | 16 | 2@0, 4@19, 6@65, 10@452, 10@21600 | TIMEOUT both; lb 9 -> 10, ub = |
| LP_2610_744_16 | no-card | 21600 | TIMEOUT | 10 | 16 | 2@0, 4@18, 6@64, 10@450, 10@21600 | TIMEOUT both; lb 9 -> 10, ub = |
| TN_180_2_17 | card-mto | 21600 | TIMEOUT | 17 | 19 | 2@0, 3@0, 5@0, 9@4, 17@11937, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_180_2_17 | no-card | 11486 | solved | 17 | 17 | 2@0, 3@0, 5@0, 9@5, 17@7300 | solved 10042 s -> 11486 s (1.14x) |
| TN_216_4_18 | card-mto | 19298 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@5, 17@4023, 18@19298 | solved 18883 s -> 19298 s (1.02x) |
| TN_216_4_18 | no-card | 14842 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@6, 17@3443, 18@14842 | solved 13499 s -> 14842 s (1.10x) |
| TN_252_2_21 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@5, 17@8759, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_252_2_21 | no-card | 21600 | TIMEOUT | 17 | 28 | 2@0, 3@0, 5@0, 9@7, 17@10656, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_288_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@12, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_288_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@14, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_324_4_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@17, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_324_4_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@14, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_360_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@5435, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_360_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@5, 17@5672, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_396_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@8, 17@4423, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_396_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@4649, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_432_8_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@2, 9@22, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_432_8_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@3, 9@22, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_468_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@10900, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_468_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@9129, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_496_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@11949, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_496_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@10690, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_504_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@5416, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_504_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@7, 17@5210, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_540_4_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@4, 9@31, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_540_4_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@3, 9@34, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_576_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@5, 9@34, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_576_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@6, 9@39, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_612_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@9, 17@5635, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_612_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@10, 17@4640, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_648_10_9to52 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@6, 9@64, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_648_10_9to52 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@1, 5@8, 9@70, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_648_14_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@8, 9@62, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_648_14_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@6, 9@74, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_684_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@15, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_684_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@20, 9@21600 | TIMEOUT both; lb =, ub = |

## Tier placement re-check (rule PI 2026-10-12: slower-mode median on this server; <1 s t0, 1-10 t1, 10-100 t2, 100-2000 t3, 2000-5000 t4, else t5)

| Case | Current tier | Slower mode | Slower-mode median s | Rule tier | Move? |
|---|---:|---|---:|---:|---|
| BB_108_8_10 | 0 | card-mto | 0.14 | 0 | no |
| BB_144_12_12 | 0 | no-card | 0.35 | 0 | no |
| BB_72_12_6 | 0 | card-mto | 0.11 | 0 | no |
| BB_90_8_10 | 0 | no-card | 0.14 | 0 | no |
| GB_144_12_8 | 0 | card-mto | 0.21 | 0 | no |
| LP_136_32_4 | 0 | card-mto | 0.18 | 0 | no |
| LP_238_44_6 | 0 | no-card | 0.44 | 0 | no |
| LP_34_20_2 | 0 | card-mto | 0.07 | 0 | no |
| TN_36_8_3 | 0 | no-card | 0.13 | 0 | no |
| TN_36_8_4 | 0 | card-mto | 0.16 | 0 | no |
| TN_54_11_4 | 0 | card-mto | 0.13 | 0 | no |
| TN_72_14_4 | 0 | card-mto | 0.11 | 0 | no |
| TN_72_8_8 | 0 | card-mto | 0.68 | 0 | no |
| LP_340_56_8 | 1 | no-card | 2.29 | 1 | no |
| BB_144_14_14 | 2 | card-mto | 23.97 | 2 | no |
| GB_144_12_12 | 2 | no-card | 58.96 | 2 | no |
| LP_442_68_10 | 2 | no-card | 8.32 | 1 | tier2 -> tier1 |
| LP_544_80_12 | 2 | no-card | 79.73 | 2 | no |
| TN_108_2_12 | 2 | card-mto | 26.75 | 2 | no |
| TN_200_10_10 | 2 | no-card | 27.86 | 2 | no |
| BB_288_12_18 | 3 | no-card | 54.56 | 2 | tier3 -> tier2 |
| TN_144_2_13 | 3 | card-mto | 514.77 | 3 | no |
| LP_714_100_16 | 4 | card-mto | 626.02 | 3 | tier4 -> tier3 |
| TN_250_10_15 | 4 | card-mto | 2865.61 | 4 | no |
| BB_1080_4_ge30 | 5 | card-mto | unsolved | 5 | no |
| BB_360_12_24 | 5 | card-mto | unsolved | 5 | no |
| BB_756_16_ge30 | 5 | card-mto | unsolved | 5 | no |
| BB_864_4_ge30 | 5 | card-mto | unsolved | 5 | no |
| LP_1020_136_16 | 5 | no-card | 1331.10 | 3 | tier5 -> tier3 |
| LP_1054_140_20 | 5 | card-mto | unsolved | 5 | no |
| LP_1122_148_20 | 5 | card-mto | unsolved | 5 | no |
| LP_1428_184_24 | 5 | card-mto | unsolved | 5 | no |
| LP_1768_224_22 | 5 | card-mto | unsolved | 5 | no |
| LP_2610_744_16 | 5 | card-mto | unsolved | 5 | no |
| TN_180_2_17 | 5 | card-mto | unsolved | 5 | no |
| TN_216_4_18 | 5 | card-mto | 19298.00 | 5 | no |
| TN_252_2_21 | 5 | card-mto | unsolved | 5 | no |
| TN_288_2_ge9 | 5 | card-mto | unsolved | 5 | no |
| TN_324_4_ge9 | 5 | card-mto | unsolved | 5 | no |
| TN_360_4_ge17 | 5 | card-mto | unsolved | 5 | no |
| TN_396_4_ge17 | 5 | card-mto | unsolved | 5 | no |
| TN_432_8_ge9 | 5 | card-mto | unsolved | 5 | no |
| TN_468_4_ge17 | 5 | card-mto | unsolved | 5 | no |
| TN_496_2_ge17 | 5 | card-mto | unsolved | 5 | no |
| TN_504_2_ge17 | 5 | card-mto | unsolved | 5 | no |
| TN_540_4_ge9 | 5 | card-mto | unsolved | 5 | no |
| TN_576_2_ge9 | 5 | card-mto | unsolved | 5 | no |
| TN_612_2_ge17 | 5 | card-mto | unsolved | 5 | no |
| TN_648_10_9to52 | 5 | card-mto | unsolved | 5 | no |
| TN_648_14_ge9 | 5 | card-mto | unsolved | 5 | no |
| TN_684_2_ge9 | 5 | card-mto | unsolved | 5 | no |

Codes that the rule would move (listed only, not moved): LP_442_68_10 (tier2 -> tier1, no-card 8 s); BB_288_12_18 (tier3 -> tier2, no-card 55 s); LP_714_100_16 (tier4 -> tier3, card-mto 626 s); LP_1020_136_16 (tier5 -> tier3, no-card 1331 s). Tier 5 rows use a single default-seed run (not a 5-seed median); for tier 0-4 cells with timed-out seeds the median counts the limit.

Notes:
- Replaces the main cbb0642 table (2026-10-18) after PR #137 (`-oddcap-skip=on` default) was merged; old table is in git history. PR #136 re-tiered the codes and renamed BB_756/864/1080 to ge28 (tier column = current tiers; comparisons by current stem).
- vs main cbb0642, geomean of per-cell median ratios (tiers 0-4, current tiers): tier0 no-card 1.156 tier0 card-mto 1.091 tier1 no-card 0.826 tier1 card-mto 0.628 tier2 no-card 0.800 tier2 card-mto 0.784 tier3 no-card 0.490 tier3 card-mto 0.502 tier4 no-card 0.374 tier4 card-mto 0.500.
- `-oddcap-skip=on` changes the bound search only on halves whose parity matrix has only odd column weights (all bundled BB and LP codes); TN and GB halves run the cbb0642 search unchanged (same 5 seeds), so their ratios measure the host only: most TN/GB seeds reproduce within a few %, but the long TN runs differ by up to ~1.4x per seed between the two batches (shared host: other users' unpinned jobs, SMT siblings, concurrent sessions).
- Tier 1-4 cells faster than 0.90x: LP_340_56_8 card-mto 0.63, LP_340_56_8 no-card 0.83, LP_442_68_10 card-mto 0.33, LP_442_68_10 no-card 0.35, LP_544_80_12 card-mto 0.89, TN_108_2_12 card-mto 0.88, TN_108_2_12 no-card 0.89, BB_288_12_18 card-mto 0.21, BB_288_12_18 no-card 0.24, LP_714_100_16 card-mto 0.24, LP_714_100_16 no-card 0.22, TN_250_10_15 no-card 0.64. Cells slower than 1.10x: TN_144_2_13 card-mto 1.22.
- Tier 0-4 seeds that reached the limit: TN_250_10_15 no-card 1/5 (seeds 1).
- Tier 5: 5 of 54 cells solved within 6 h (cbb0642: 5 of 54 comparable cells). Cells better than cbb0642 (newly solved or tighter bound): BB_1080_4_ge28 card-mto, BB_1080_4_ge28 no-card, BB_360_12_24 card-mto, BB_360_12_24 no-card, BB_756_16_ge28 card-mto, BB_756_16_ge28 no-card, BB_864_4_ge28 card-mto, BB_864_4_ge28 no-card, LP_1054_140_20 card-mto, LP_1054_140_20 no-card, LP_1122_148_20 card-mto, LP_1122_148_20 no-card, LP_1428_184_24 card-mto, LP_1428_184_24 no-card, LP_1768_224_22 card-mto, LP_1768_224_22 no-card, LP_2610_744_16 card-mto, LP_2610_744_16 no-card. Worse: none.
- Lower-bound ladders: on BB/LP halves (odd column weights, `-oddcap-skip=on`) the doubling phase probes caps 2,4,8,16,32, and a NONE at cap 2t certifies lb 2t+2 (ladder 2/4/6/10/18: lb 18 = no logical of weight <= 17); TN halves keep the cbb0642 ladder 2/3/5/9/17 (caps 1,2,4,8,16).
- Host load: this refresh used cores 0-89 only (tier 5 on 0-53 for 6 h, the panel on 54-89 for 1.4 h); another session ran 24 pinned processes on cores 100-123 from ~21:19 and other users ran ~20 unpinned jobs (load average 98-115 during the runs; raw/main-c914ef5/server_load_samples.txt, every 60 s). Tier 0 cells (all < 0.7 s) are start-up dominated and their ratios (0.5-2.3x) are host noise.
- Correctness: panel 240 runs (0 runner errors), every answer equals the stem distance and no bound crosses it; tier 5 54 runs, bounds consistent with the stems.
- BB_756/864/1080 rows carry the current stem names (renamed ge28 -> ge30 on 2026-10-22, PR #141, after this run was recorded; the run used the ge28 files, same matrices).
