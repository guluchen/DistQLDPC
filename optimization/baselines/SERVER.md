# Recorded main baseline times on yfclab2 (2026-10-18)

Binary: main cbb0642 (GH-130 adopted: -frontier=auto default) built on yfclab2 (frozen/server-main-cbb0642/distqldpc), sha256 `7afb1c6e5ccddf4ee3d4bb46c28088f2af9ab04cbcc70d51c86f9d060dfa8c4b`. tiers 0-4: runner/server_panel.py, 5 seeds (-seed=0..4; 0 = default search) per case/mode, one process per pinned physical core (taskset, cores 56-59,64-99), 4 GB cap (prlimit --as), limits tier0 600 s, tier1-3 1800 s, tier4 5000 s; the recorded time is the 5-seed median (seed-median judging, PI 2026-10-14; a timed-out seed counts as the limit); tier 5: runner/server_tier5.py, 1 run per case/mode, default seed, 6 h limit, cores 0-55, run concurrently with tiers 0-4. Column "vs 398054e" = this median / the main 398054e median (2026-10-14, 3-run medians, git history).

## Tiers 0-4 (5 seeds; the median is the reference)

| Tier | Case | Mode | Seeds | s0 | s1 | s2 | s3 | s4 | Median s | Min s | Max s | Solved | 398054e median s | vs 398054e |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|
| 0 | BB_72_12_6 | card-mto | 5 | 0.06 | 0.07 | 0.06 | 0.07 | 0.07 | 0.07 | 0.06 | 0.07 | yes | 0.09 | 0.756 |
| 0 | BB_72_12_6 | no-card | 5 | 0.07 | 0.06 | 0.07 | 0.06 | 0.06 | 0.06 | 0.06 | 0.07 | yes | 0.1 | 0.64 |
| 0 | BB_90_8_10 | card-mto | 5 | 0.13 | 0.14 | 0.13 | 0.14 | 0.13 | 0.13 | 0.13 | 0.14 | yes | 0.26 | 0.511 |
| 0 | BB_90_8_10 | no-card | 5 | 0.12 | 0.12 | 0.13 | 0.13 | 0.13 | 0.13 | 0.12 | 0.13 | yes | 0.25 | 0.52 |
| 0 | GB_144_12_8 | card-mto | 5 | 0.14 | 0.13 | 0.11 | 0.12 | 0.14 | 0.13 | 0.11 | 0.14 | yes | 0.21 | 0.629 |
| 0 | GB_144_12_8 | no-card | 5 | 0.14 | 0.14 | 0.12 | 0.12 | 0.16 | 0.14 | 0.12 | 0.16 | yes | 0.36 | 0.383 |
| 0 | LP_136_32_4 | card-mto | 5 | 0.16 | 0.18 | 0.19 | 0.22 | 0.24 | 0.19 | 0.16 | 0.24 | yes | 0.3 | 0.64 |
| 0 | LP_136_32_4 | no-card | 5 | 0.24 | 0.16 | 0.12 | 0.16 | 0.3 | 0.16 | 0.12 | 0.3 | yes | 0.23 | 0.713 |
| 0 | LP_34_20_2 | card-mto | 5 | 0.05 | 0.06 | 0.05 | 0.08 | 0.06 | 0.06 | 0.05 | 0.08 | yes | 0.11 | 0.536 |
| 0 | LP_34_20_2 | no-card | 5 | 0.05 | 0.05 | 0.04 | 0.05 | 0.08 | 0.05 | 0.04 | 0.08 | yes | 0.1 | 0.49 |
| 0 | TN_36_8_3 | card-mto | 5 | 0.09 | 0.07 | 0.05 | 0.08 | 0.06 | 0.07 | 0.05 | 0.09 | yes | 0.12 | 0.55 |
| 0 | TN_36_8_3 | no-card | 5 | 0.08 | 0.08 | 0.08 | 0.06 | 0.06 | 0.08 | 0.06 | 0.08 | yes | 0.13 | 0.6 |
| 0 | TN_36_8_4 | card-mto | 5 | 0.07 | 0.08 | 0.06 | 0.1 | 0.07 | 0.07 | 0.06 | 0.1 | yes | 0.21 | 0.352 |
| 0 | TN_36_8_4 | no-card | 5 | 0.06 | 0.09 | 0.05 | 0.09 | 0.07 | 0.07 | 0.05 | 0.09 | yes | 0.17 | 0.418 |
| 0 | TN_54_11_4 | card-mto | 5 | 0.1 | 0.1 | 0.1 | 0.14 | 0.1 | 0.1 | 0.1 | 0.14 | yes | 0.16 | 0.644 |
| 0 | TN_54_11_4 | no-card | 5 | 0.06 | 0.12 | 0.08 | 0.07 | 0.09 | 0.08 | 0.06 | 0.12 | yes | 0.11 | 0.727 |
| 0 | TN_72_14_4 | card-mto | 5 | 0.11 | 0.22 | 0.14 | 0.14 | 0.2 | 0.14 | 0.11 | 0.22 | yes | 0.15 | 0.96 |
| 0 | TN_72_14_4 | no-card | 5 | 0.09 | 0.13 | 0.17 | 0.13 | 0.1 | 0.13 | 0.09 | 0.17 | yes | 0.12 | 1.058 |
| 0 | TN_72_8_8 | card-mto | 5 | 0.91 | 0.62 | 0.51 | 0.72 | 0.68 | 0.68 | 0.51 | 0.91 | yes | 0.87 | 0.782 |
| 0 | TN_72_8_8 | no-card | 5 | 0.64 | 0.63 | 0.86 | 0.62 | 0.65 | 0.64 | 0.62 | 0.86 | yes | 0.64 | 1.005 |
| 1 | BB_108_8_10 | card-mto | 5 | 0.27 | 0.2 | 0.27 | 0.24 | 0.22 | 0.24 | 0.2 | 0.27 | yes | 1.1 | 0.221 |
| 1 | BB_108_8_10 | no-card | 5 | 0.23 | 0.19 | 0.27 | 0.23 | 0.2 | 0.23 | 0.19 | 0.27 | yes | 0.82 | 0.279 |
| 1 | BB_144_12_12 | card-mto | 5 | 0.32 | 0.41 | 0.3 | 0.29 | 0.4 | 0.32 | 0.29 | 0.41 | yes | 1.68 | 0.19 |
| 1 | BB_144_12_12 | no-card | 5 | 0.35 | 0.33 | 0.3 | 0.38 | 0.34 | 0.34 | 0.3 | 0.38 | yes | 0.72 | 0.469 |
| 1 | LP_238_44_6 | card-mto | 5 | 0.85 | 0.65 | 0.69 | 0.94 | 0.9 | 0.85 | 0.65 | 0.94 | yes | 1.58 | 0.541 |
| 1 | LP_238_44_6 | no-card | 5 | 0.78 | 0.82 | 0.74 | 0.75 | 0.89 | 0.78 | 0.74 | 0.89 | yes | 1.3 | 0.602 |
| 1 | LP_340_56_8 | card-mto | 5 | 3.59 | 3.31 | 2.87 | 3.01 | 3.12 | 3.12 | 2.87 | 3.59 | yes | 4.46 | 0.698 |
| 1 | LP_340_56_8 | no-card | 5 | 2.47 | 2.78 | 2.46 | 2.95 | 3.5 | 2.78 | 2.46 | 3.5 | yes | 3.78 | 0.735 |
| 2 | BB_144_14_14 | card-mto | 5 | 19.01 | 41.66 | 39.26 | 18.06 | 24.65 | 24.65 | 18.06 | 41.66 | yes | 62.33 | 0.396 |
| 2 | BB_144_14_14 | no-card | 5 | 18.61 | 22.52 | 35.59 | 17.73 | 22.3 | 22.3 | 17.73 | 35.59 | yes | 72.66 | 0.307 |
| 2 | LP_442_68_10 | card-mto | 5 | 31.67 | 27.88 | 20.79 | 18.13 | 25.32 | 25.32 | 18.13 | 31.67 | yes | 45.76 | 0.553 |
| 2 | LP_442_68_10 | no-card | 5 | 22.87 | 31.56 | 27.73 | 20.79 | 23.96 | 23.96 | 20.79 | 31.56 | yes | 40.69 | 0.589 |
| 2 | TN_108_2_12 | card-mto | 5 | 31.47 | 30.21 | 23.71 | 31.3 | 30.3 | 30.3 | 23.71 | 31.47 | yes | 30.16 | 1.004 |
| 2 | TN_108_2_12 | no-card | 5 | 23.66 | 29.01 | 26.2 | 24.7 | 23 | 24.7 | 23 | 29.01 | yes | 25.1 | 0.984 |
| 3 | BB_288_12_18 | card-mto | 5 | 229.69 | 244.55 | 223.27 | 255.06 | 257.93 | 244.55 | 223.27 | 257.93 | yes | 918.98 | 0.266 |
| 3 | BB_288_12_18 | no-card | 5 | 231.47 | 874.78 | 213.14 | 974.84 | 225.14 | 231.47 | 213.14 | 974.84 | yes | 735.39 | 0.315 |
| 3 | GB_144_12_12 | card-mto | 5 | 45.29 | 38.34 | 34.55 | 95.24 | 81.7 | 45.29 | 34.55 | 95.24 | yes | 59.26 | 0.764 |
| 3 | GB_144_12_12 | no-card | 5 | 60.65 | 24.36 | 17.82 | 71.75 | 62.14 | 60.65 | 17.82 | 71.75 | yes | 130.93 | 0.463 |
| 3 | LP_544_80_12 | card-mto | 5 | 54.19 | 84.07 | 72.69 | 69.12 | 55.08 | 69.12 | 54.19 | 84.07 | yes | 335.48 | 0.206 |
| 3 | LP_544_80_12 | no-card | 5 | 334.99 | 85.77 | 297.61 | 65.09 | 83.81 | 85.77 | 65.09 | 334.99 | yes | 521.38 | 0.165 |
| 3 | TN_144_2_13 | card-mto | 5 | 363.64 | 614.31 | 651.58 | 422.99 | 213.75 | 422.99 | 213.75 | 651.58 | yes | 340.51 | 1.242 |
| 3 | TN_144_2_13 | no-card | 5 | 377.02 | 278.74 | 300.95 | 287.64 | 956.43 | 300.95 | 278.74 | 956.43 | yes | 362.4 | 0.83 |
| 3 | TN_200_10_10 | card-mto | 5 | 18.45 | 19.84 | 46.66 | 30.1 | 21.72 | 21.72 | 18.45 | 46.66 | yes | 20.55 | 1.057 |
| 3 | TN_200_10_10 | no-card | 5 | 132.35 | 21.85 | 24.07 | 50.34 | 27.82 | 27.82 | 21.85 | 132.35 | yes | 129.44 | 0.215 |
| 4 | TN_250_10_15 | card-mto | 5 | 3812.09 | 2694.86 | 2850.91 | 1891.91 | 1846.51 | 2694.86 | 1846.51 | 3812.09 | yes | 3090.89 | 0.872 |
| 4 | TN_250_10_15 | no-card | 5 | 2344.33 | 4419.18 | 5000T | 1882.99 | 5000T | 4419.18 | 1882.99 | 5000 | 3/5 | 1786.05 | 2.474 |

"T" marks a seed that reached the limit (counted as the limit in the median).

## Tier 5 (6 h, 1 run per cell, default seed)

| Case | Mode | Wall s | Result | Final lb | Final ub | lb reached at (s) | vs 398054e (result, lb/ub, wall) |
|---|---|---:|---|---:|---:|---|---|
| BB_1080_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@1, 3@1, 5@2, 9@3, 17@9264, 17@21600 | TIMEOUT both; lb =, ub = |
| BB_1080_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@2567, 17@21600 | TIMEOUT both; lb =, ub = |
| BB_360_12_24 | card-mto | 21600 | TIMEOUT | 17 | 24 | 2@0, 3@0, 5@0, 9@0, 17@87, 17@21600 | TIMEOUT both; lb =, ub = |
| BB_360_12_24 | no-card | 21600 | TIMEOUT | 17 | 24 | 2@0, 3@0, 5@0, 9@0, 17@86, 17@21600 | TIMEOUT both; lb =, ub = |
| BB_756_16_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@673, 17@21600 | TIMEOUT both; lb =, ub = |
| BB_756_16_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@1, 3@1, 5@2, 9@2, 17@3352, 17@21600 | TIMEOUT both; lb =, ub = |
| BB_864_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@873, 17@21600 | TIMEOUT both; lb =, ub = |
| BB_864_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@0, 17@876, 17@21600 | TIMEOUT both; lb =, ub = |
| LP_1020_136_16 | card-mto | 2316 | solved | 16 | 16 | 2@0, 3@1, 5@2, 9@7, 16@2316 | solved 8328 s -> 2316 s (0.28x) |
| LP_1020_136_16 | no-card | 8955 | solved | 16 | 16 | 2@3, 3@7, 5@12, 9@54, 16@8955 | solved 7159 s -> 8955 s (1.25x) |
| LP_1054_140_20 | card-mto | 21600 | TIMEOUT | 17 | 32 | 2@1, 3@1, 5@3, 9@11, 17@9357, 17@21600 | TIMEOUT both; lb =, ub - -> 32 |
| LP_1054_140_20 | no-card | 21600 | TIMEOUT | 17 | 32 | 2@1, 3@1, 5@3, 9@16, 17@9361, 17@21600 | TIMEOUT both; lb =, ub - -> 32 |
| LP_1122_148_20 | card-mto | 21600 | TIMEOUT | 17 | 32 | 2@1, 3@1, 5@3, 9@8, 17@5865, 17@21600 | new code (not in the 398054e table) |
| LP_1122_148_20 | no-card | 21600 | TIMEOUT | 17 | 32 | 2@1, 3@1, 5@3, 9@11, 17@5859, 17@21600 | new code (not in the 398054e table) |
| LP_1428_184_24 | card-mto | 21600 | TIMEOUT | 17 | 32 | 2@1, 3@3, 5@5, 9@12, 17@9149, 17@21600 | TIMEOUT both; lb =, ub - -> 32 |
| LP_1428_184_24 | no-card | 21600 | TIMEOUT | 17 | 32 | 2@1, 3@3, 5@4, 9@12, 17@9157, 17@21600 | TIMEOUT both; lb =, ub - -> 32 |
| LP_1768_224_22 | card-mto | 21600 | TIMEOUT | 17 | - | 2@18, 3@39, 5@71, 9@154, 17@14204, 17@21600 | TIMEOUT both; lb 9 -> 17, ub = |
| LP_1768_224_22 | no-card | 21600 | TIMEOUT | 17 | - | 2@3, 3@6, 5@11, 9@36, 17@14094, 17@21600 | TIMEOUT both; lb 9 -> 17, ub = |
| LP_2610_744_16 | card-mto | 21600 | TIMEOUT | 9 | 16 | 2@16, 3@34, 5@75, 9@437, 9@21600 | new code (not in the 398054e table) |
| LP_2610_744_16 | no-card | 21600 | TIMEOUT | 9 | 16 | 2@16, 3@34, 5@76, 9@437, 9@21600 | new code (not in the 398054e table) |
| LP_714_100_16 | card-mto | 2663 | solved | 16 | 16 | 2@0, 3@1, 5@1, 9@6, 16@2663 | solved 5321 s -> 2663 s (0.50x) |
| LP_714_100_16 | no-card | 2670 | solved | 16 | 16 | 2@0, 3@1, 5@1, 9@5, 16@2670 | solved 8752 s -> 2670 s (0.31x) |
| TN_180_2_17 | card-mto | 21600 | TIMEOUT | 17 | 19 | 2@0, 3@0, 5@0, 9@4, 17@11250, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_180_2_17 | no-card | 10042 | solved | 17 | 17 | 2@0, 3@0, 5@0, 9@4, 17@6530 | solved 9837 s -> 10042 s (1.02x) |
| TN_216_4_18 | card-mto | 18883 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@5, 17@3933, 18@18883 | solved 18346 s -> 18883 s (1.03x) |
| TN_216_4_18 | no-card | 13499 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@5, 17@3373, 18@13499 | solved 16802 s -> 13499 s (0.80x) |
| TN_252_2_21 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@5, 17@8634, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_252_2_21 | no-card | 21600 | TIMEOUT | 17 | 28 | 2@0, 3@0, 5@0, 9@5, 17@9235, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_288_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@3, 9@54, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_288_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@15, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_324_4_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@19, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_324_4_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@17, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_360_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@5333, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_360_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@4, 17@5525, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_396_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@7, 17@4289, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_396_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@8, 17@4356, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_432_8_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@2, 9@25, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_432_8_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@3, 9@26, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_468_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@10424, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_468_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@9, 17@8811, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_496_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@11551, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_496_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@10405, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_504_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@5107, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_504_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@7, 17@5153, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_540_4_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@1, 3@1, 5@18, 9@154, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_540_4_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@3, 9@38, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_576_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@5, 9@37, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_576_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@5, 9@42, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_612_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@9, 17@4428, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_612_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@9, 17@4656, 17@21600 | TIMEOUT both; lb =, ub = |
| TN_648_10_9to52 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@5, 9@60, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_648_10_9to52 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@1, 5@6, 9@54, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_648_14_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@8, 9@58, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_648_14_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@8, 9@91, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_684_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@15, 9@21600 | TIMEOUT both; lb =, ub = |
| TN_684_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@0, 9@18, 9@21600 | TIMEOUT both; lb =, ub = |

## Tier placement re-check (rule PI 2026-10-12: slower-mode median on this server; <1 s t0, 1-10 t1, 10-100 t2, 100-2000 t3, 2000-5000 t4, else t5)

| Case | Current tier | Slower mode | Slower-mode median s | Rule tier | Move? |
|---|---:|---|---:|---:|---|
| BB_72_12_6 | 0 | card-mto | 0.07 | 0 | no |
| BB_90_8_10 | 0 | card-mto | 0.13 | 0 | no |
| GB_144_12_8 | 0 | no-card | 0.14 | 0 | no |
| LP_136_32_4 | 0 | card-mto | 0.19 | 0 | no |
| LP_34_20_2 | 0 | card-mto | 0.06 | 0 | no |
| TN_36_8_3 | 0 | no-card | 0.08 | 0 | no |
| TN_36_8_4 | 0 | card-mto | 0.07 | 0 | no |
| TN_54_11_4 | 0 | card-mto | 0.10 | 0 | no |
| TN_72_14_4 | 0 | card-mto | 0.14 | 0 | no |
| TN_72_8_8 | 0 | card-mto | 0.68 | 0 | no |
| BB_108_8_10 | 1 | card-mto | 0.24 | 0 | tier1 -> tier0 |
| BB_144_12_12 | 1 | no-card | 0.34 | 0 | tier1 -> tier0 |
| LP_238_44_6 | 1 | card-mto | 0.85 | 0 | tier1 -> tier0 |
| LP_340_56_8 | 1 | card-mto | 3.12 | 1 | no |
| BB_144_14_14 | 2 | card-mto | 24.65 | 2 | no |
| LP_442_68_10 | 2 | card-mto | 25.32 | 2 | no |
| TN_108_2_12 | 2 | card-mto | 30.30 | 2 | no |
| BB_288_12_18 | 3 | card-mto | 244.55 | 3 | no |
| GB_144_12_12 | 3 | no-card | 60.65 | 2 | tier3 -> tier2 |
| LP_544_80_12 | 3 | no-card | 85.77 | 2 | tier3 -> tier2 |
| TN_144_2_13 | 3 | card-mto | 422.99 | 3 | no |
| TN_200_10_10 | 3 | no-card | 27.82 | 2 | tier3 -> tier2 |
| TN_250_10_15 | 4 | no-card | 4419.18 | 4 | no |
| BB_1080_4_ge17 | 5 | card-mto | unsolved | 5 | no |
| BB_360_12_24 | 5 | card-mto | unsolved | 5 | no |
| BB_756_16_ge17 | 5 | card-mto | unsolved | 5 | no |
| BB_864_4_ge17 | 5 | card-mto | unsolved | 5 | no |
| LP_1020_136_16 | 5 | no-card | 8954.80 | 5 | no |
| LP_1054_140_20 | 5 | card-mto | unsolved | 5 | no |
| LP_1122_148_20 | 5 | card-mto | unsolved | 5 | no |
| LP_1428_184_24 | 5 | card-mto | unsolved | 5 | no |
| LP_1768_224_22 | 5 | card-mto | unsolved | 5 | no |
| LP_2610_744_16 | 5 | card-mto | unsolved | 5 | no |
| LP_714_100_16 | 5 | no-card | 2670.30 | 4 | tier5 -> tier4 |
| TN_180_2_17 | 5 | card-mto | unsolved | 5 | no |
| TN_216_4_18 | 5 | card-mto | 18883.20 | 5 | no |
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

Codes that the rule would move (listed only, not moved): BB_108_8_10 (tier1 -> tier0, card-mto 0 s); BB_144_12_12 (tier1 -> tier0, no-card 0 s); LP_238_44_6 (tier1 -> tier0, card-mto 1 s); GB_144_12_12 (tier3 -> tier2, no-card 61 s); LP_544_80_12 (tier3 -> tier2, no-card 86 s); TN_200_10_10 (tier3 -> tier2, no-card 28 s); LP_714_100_16 (tier5 -> tier4, no-card 2670 s). Tier 5 rows use a single default-seed run (not a 5-seed median); for tier 0-4 cells with timed-out seeds the median counts the limit.

Notes:
- Replaces the main 398054e table (2026-10-14) after GH-130 (PR #131, `-frontier=auto` default) was merged; old table is in git history. The 398054e table used 3-run medians; this one uses 5-seed medians, so small ratios also carry the seed spread.
- vs main 398054e, geomean of per-cell median ratios (tiers 0-4): tier0 no-card 0.622 tier0 card-mto 0.616 tier1 no-card 0.491 tier1 card-mto 0.355 tier2 no-card 0.562 tier2 card-mto 0.604 tier3 no-card 0.336 tier3 card-mto 0.560 tier4 no-card 2.474 tier4 card-mto 0.872.
- `-frontier=auto` turns frontier branching on for every BB/GB/LP half and off for every TN half of tiers 1-5, so TN cells run the 398054e search unchanged (GH-130 S1 identity check): their ratios here are seed spread (5-seed median vs 3 default-seed runs) plus host load, not a solver change. Tier 0 cells are all < 1 s and their ratios (0.35-0.78) are dominated by the host load of the two batches.
- Tier 1-4 cells faster than 0.90x: BB_108_8_10 card-mto 0.22, BB_108_8_10 no-card 0.28, BB_144_12_12 card-mto 0.19, BB_144_12_12 no-card 0.47, LP_238_44_6 card-mto 0.54, LP_238_44_6 no-card 0.60, LP_340_56_8 card-mto 0.70, LP_340_56_8 no-card 0.73, BB_144_14_14 card-mto 0.40, BB_144_14_14 no-card 0.31, LP_442_68_10 card-mto 0.55, LP_442_68_10 no-card 0.59, BB_288_12_18 card-mto 0.27, BB_288_12_18 no-card 0.31, GB_144_12_12 card-mto 0.76, GB_144_12_12 no-card 0.46, LP_544_80_12 card-mto 0.21, LP_544_80_12 no-card 0.16, TN_144_2_13 no-card 0.83, TN_200_10_10 no-card 0.21, TN_250_10_15 card-mto 0.87. Cells slower than 1.10x: TN_144_2_13 card-mto 1.24, TN_250_10_15 no-card 2.47.
- Tier 0-4 seeds that reached the limit: TN_250_10_15 no-card 2/5 (seeds 2, 4).
- Tier 5: 7 of 56 cells solved within 6 h (398054e: 7 of 52 comparable cells). Cells better than 398054e (newly solved or tighter bound): LP_1054_140_20 card-mto, LP_1054_140_20 no-card, LP_1428_184_24 card-mto, LP_1428_184_24 no-card, LP_1768_224_22 card-mto, LP_1768_224_22 no-card. Worse: none.
- New tier5 codes (PR #132, Cain et al. via C. Crocker's Zenodo distances): LP_1122_148_20 card-mto: TIMEOUT lb 17 ub 32; LP_1122_148_20 no-card: TIMEOUT lb 17 ub 32; LP_2610_744_16 card-mto: TIMEOUT lb 9 ub 16; LP_2610_744_16 no-card: TIMEOUT lb 9 ub 16.
- The lb sequence 3/5/9/17 comes from the doubling phase of the interleaved bound search (caps 2,4,8,16,32): lb 17 means no logical of weight <= 16 exists and the solver is searching for any logical of weight <= 32.
- Correctness: panel 230 runs (0 runner errors), every answer equals the stem distance and no bound crosses it; tier 5 56 runs, bounds consistent with the stems.
