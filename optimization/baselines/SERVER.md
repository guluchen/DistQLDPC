# Recorded main baseline times on yfclab2 (2026-10-14)

Binary: main 398054e (GH-107 adopted) built on yfclab2 (frozen/server-main398/distqldpc), sha256 `9bf55806b61938d35eeabb03a32de751c4082aa341b66492d733f3c6abb47cf3`. tiers 0-4: 3 runs per case/mode, pool on pinned physical cores 0-59 (taskset), 4 GB cap (prlimit), limits tier0 600 s, tier1-3 1800 s, tier4 5000 s; tier 5: 1 run per case/mode, 6 h limit, cores 64-119, run concurrently with tiers 0-4.

## Tiers 0-4

| Tier | Case | Mode | Runs | Median s | Min s | Max s | Solved |
|---:|---|---|---:|---:|---:|---:|---|
| 0 | BB_72_12_6 | card-mto | 3 | 0.09 | 0.09 | 0.1 | yes |
| 0 | BB_72_12_6 | no-card | 3 | 0.1 | 0.09 | 0.11 | yes |
| 0 | BB_90_8_10 | card-mto | 3 | 0.26 | 0.23 | 0.26 | yes |
| 0 | BB_90_8_10 | no-card | 3 | 0.25 | 0.24 | 0.25 | yes |
| 0 | GB_144_12_8 | card-mto | 3 | 0.21 | 0.21 | 0.27 | yes |
| 0 | GB_144_12_8 | no-card | 3 | 0.36 | 0.33 | 0.5 | yes |
| 0 | LP_136_32_4 | card-mto | 3 | 0.3 | 0.19 | 0.32 | yes |
| 0 | LP_136_32_4 | no-card | 3 | 0.23 | 0.2 | 0.24 | yes |
| 0 | LP_34_20_2 | card-mto | 3 | 0.11 | 0.1 | 0.11 | yes |
| 0 | LP_34_20_2 | no-card | 3 | 0.1 | 0.1 | 0.15 | yes |
| 0 | TN_36_8_3 | card-mto | 3 | 0.12 | 0.11 | 0.16 | yes |
| 0 | TN_36_8_3 | no-card | 3 | 0.13 | 0.13 | 0.16 | yes |
| 0 | TN_36_8_4 | card-mto | 3 | 0.21 | 0.2 | 0.21 | yes |
| 0 | TN_36_8_4 | no-card | 3 | 0.17 | 0.15 | 0.17 | yes |
| 0 | TN_54_11_4 | card-mto | 3 | 0.16 | 0.15 | 0.16 | yes |
| 0 | TN_54_11_4 | no-card | 3 | 0.11 | 0.1 | 0.13 | yes |
| 0 | TN_72_14_4 | card-mto | 3 | 0.15 | 0.14 | 0.18 | yes |
| 0 | TN_72_14_4 | no-card | 3 | 0.12 | 0.1 | 0.13 | yes |
| 0 | TN_72_8_8 | card-mto | 3 | 0.87 | 0.85 | 0.88 | yes |
| 0 | TN_72_8_8 | no-card | 3 | 0.64 | 0.61 | 0.67 | yes |
| 1 | BB_108_8_10 | card-mto | 3 | 1.1 | 1.04 | 1.27 | yes |
| 1 | BB_108_8_10 | no-card | 3 | 0.82 | 0.82 | 0.97 | yes |
| 1 | BB_144_12_12 | card-mto | 3 | 1.68 | 1.67 | 1.99 | yes |
| 1 | BB_144_12_12 | no-card | 3 | 0.72 | 0.69 | 0.72 | yes |
| 1 | LP_238_44_6 | card-mto | 3 | 1.58 | 1.16 | 1.64 | yes |
| 1 | LP_238_44_6 | no-card | 3 | 1.3 | 1.27 | 1.34 | yes |
| 1 | LP_340_56_8 | card-mto | 3 | 4.46 | 4.44 | 4.59 | yes |
| 1 | LP_340_56_8 | no-card | 3 | 3.78 | 3.64 | 3.88 | yes |
| 2 | LP_442_68_10 | card-mto | 3 | 45.76 | 45.59 | 46.77 | yes |
| 2 | LP_442_68_10 | no-card | 3 | 40.69 | 40.52 | 40.8 | yes |
| 2 | TN_108_2_12 | card-mto | 3 | 30.16 | 30.01 | 30.28 | yes |
| 2 | TN_108_2_12 | no-card | 3 | 25.1 | 25.08 | 25.16 | yes |
| 3 | BB_144_14_14 | card-mto | 3 | 62.33 | 62.22 | 62.64 | yes |
| 3 | BB_144_14_14 | no-card | 3 | 72.66 | 72.09 | 72.73 | yes |
| 3 | GB_144_12_12 | card-mto | 3 | 59.26 | 59.25 | 59.71 | yes |
| 3 | GB_144_12_12 | no-card | 3 | 130.93 | 130.89 | 131.61 | yes |
| 3 | LP_544_80_12 | card-mto | 3 | 335.48 | 335.21 | 612.01 | yes |
| 3 | LP_544_80_12 | no-card | 3 | 521.38 | 492.51 | 524.15 | yes |
| 3 | TN_144_2_13 | card-mto | 3 | 340.51 | 340.31 | 642.51 | yes |
| 3 | TN_144_2_13 | no-card | 3 | 362.4 | 359.64 | 362.43 | yes |
| 3 | TN_200_10_10 | card-mto | 3 | 20.55 | 20.37 | 21.81 | yes |
| 3 | TN_200_10_10 | no-card | 3 | 129.44 | 128.44 | 132.5 | yes |
| 4 | BB_288_12_18 | card-mto | 3 | 918.98 | 915.33 | 919.56 | yes |
| 4 | BB_288_12_18 | no-card | 3 | 735.39 | 734.91 | 739.12 | yes |
| 4 | TN_250_10_15 | card-mto | 3 | 3090.89 | 3086.84 | 3099.3 | yes |
| 4 | TN_250_10_15 | no-card | 3 | 1786.05 | 1785.97 | 1818.79 | yes |

## Tier 5 (6 h, 1 run per cell)

| Case | Mode | Wall s | Result | Final lb | Final ub | lb reached at (s) |
|---|---|---:|---|---:|---:|---|
| BB_1080_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@2422, 17@21600 |
| BB_1080_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@2423, 17@21600 |
| BB_360_12_17to24 | card-mto | 21600 | TIMEOUT | 17 | 24 | 2@0, 3@0, 5@0, 9@0, 17@168, 17@21600 |
| BB_360_12_17to24 | no-card | 21600 | TIMEOUT | 17 | 24 | 2@0, 3@0, 5@0, 9@0, 17@206, 17@21600 |
| BB_756_16_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@846, 17@21600 |
| BB_756_16_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@844, 17@21600 |
| BB_864_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@1175, 17@21600 |
| BB_864_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@1, 17@1176, 17@21600 |
| LP_1020_136_16 | card-mto | 8328 | solved | 16 | 16 | 2@0, 3@1, 5@2, 9@17, 16@8328 |
| LP_1020_136_16 | no-card | 7159 | solved | 16 | 16 | 2@0, 3@1, 5@2, 9@18, 16@7159 |
| LP_1054_140_17to32 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@1, 5@3, 9@18, 17@16386, 17@21600 |
| LP_1054_140_17to32 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@1, 5@2, 9@21, 17@16379, 17@21600 |
| LP_1428_184_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@1, 3@2, 5@5, 9@24, 17@15997, 17@21600 |
| LP_1428_184_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@1, 3@4, 5@9, 9@46, 17@19868, 17@21600 |
| LP_1768_224_ge17 | card-mto | 21600 | TIMEOUT | 9 | - | 2@3, 3@6, 5@12, 9@48, 9@21600 |
| LP_1768_224_ge17 | no-card | 21600 | TIMEOUT | 9 | - | 2@3, 3@7, 5@13, 9@49, 9@21600 |
| LP_714_100_16 | card-mto | 5321 | solved | 16 | 16 | 2@0, 3@0, 5@1, 9@12, 16@5321 |
| LP_714_100_16 | no-card | 8752 | solved | 16 | 16 | 2@0, 3@1, 5@1, 9@20, 16@8751 |
| TN_180_2_17 | card-mto | 21600 | TIMEOUT | 17 | 19 | 2@0, 3@0, 5@0, 9@4, 17@10917, 17@21600 |
| TN_180_2_17 | no-card | 9837 | solved | 17 | 17 | 2@0, 3@0, 5@0, 9@4, 17@6395 |
| TN_216_4_18 | card-mto | 18346 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@6, 17@3733, 18@18346 |
| TN_216_4_18 | no-card | 16802 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@6, 17@3169, 18@16802 |
| TN_252_2_17to28 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@8034, 17@21600 |
| TN_252_2_17to28 | no-card | 21600 | TIMEOUT | 17 | 28 | 2@0, 3@0, 5@0, 9@5, 17@8660, 17@21600 |
| TN_288_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@12, 9@21600 |
| TN_288_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@15, 9@21600 |
| TN_324_4_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@16, 9@21600 |
| TN_324_4_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@1, 9@15, 9@21600 |
| TN_360_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@7, 17@5154, 17@21600 |
| TN_360_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@6, 17@5403, 17@21600 |
| TN_396_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@8, 17@4588, 17@21600 |
| TN_396_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@9, 17@4468, 17@21600 |
| TN_432_8_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@2, 9@20, 9@21600 |
| TN_432_8_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@3, 9@21, 9@21600 |
| TN_468_4_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@11, 17@9988, 17@21600 |
| TN_468_4_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@8437, 17@21600 |
| TN_496_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@7, 17@11092, 17@21600 |
| TN_496_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@7, 17@9969, 17@21600 |
| TN_504_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@0, 9@10, 17@4866, 17@21600 |
| TN_504_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@8, 17@4919, 17@21600 |
| TN_540_4_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@4, 9@30, 9@21600 |
| TN_540_4_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@4, 9@34, 9@21600 |
| TN_576_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@6, 9@46, 9@21600 |
| TN_576_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@7, 9@38, 9@21600 |
| TN_612_2_ge17 | card-mto | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@10, 17@4182, 17@21600 |
| TN_612_2_ge17 | no-card | 21600 | TIMEOUT | 17 | - | 2@0, 3@0, 5@1, 9@10, 17@4293, 17@21600 |
| TN_648_10_9to52 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@6, 9@59, 9@21600 |
| TN_648_10_9to52 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@6, 9@51, 9@21600 |
| TN_648_14_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@8, 9@58, 9@21600 |
| TN_648_14_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@7, 9@67, 9@21600 |
| TN_684_2_ge9 | card-mto | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@0, 9@14, 9@21600 |
| TN_684_2_ge9 | no-card | 21600 | TIMEOUT | 9 | - | 2@0, 3@0, 5@0, 9@16, 9@21600 |

Notes:
- vs main a3fe591 server table (2026-10-12): dual-map codes faster (BB_288_12_18 0.46/0.43, BB_144_14_14 0.61/0.71, BB_144_12_12 0.62/0.49); non-dual codes 4-27% slower here, but neutral (+-3%) on the Mac with identical search, so this is load noise (the Tier 5 run shared the host). Use server times for tier placement, not for small ratios.
- Tier 5: 7 of 52 cells solved within 6 h (LP_714_100_16 both modes, LP_1020_136_16 both, TN_216_4_18 both, TN_180_2_17 no-card).
- The lb sequence 3/5/9/17 comes from the doubling phase of the interleaved bound search (caps 2,4,8,16,32): lb 17 means no logical of weight <= 16 exists and the solver is searching for any logical of weight <= 32.
- Tier placement re-check with these times (slower mode median): BB_144_14_14 72.7 s -> tier2 rule; BB_288_12_18 919 s -> tier3 rule (PI placed BB_288 in tier4 on 2026-10-12; not moved, pending PI decision).
