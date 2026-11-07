# Recorded main baseline times on yfclab2 (2026-11-04)

Binary: main 02879a93 (PR #203 merge) built on yfclab2 (frozen/server-main-02879a93/distqldpc), sha256 `f451e14a16393126ab6ddec2bede969fbc5d7b89dfb869eb53c71daafc81e54b`. Runner: runner/server_retier_20261104.py (one dynamic queue over all 80 bundled codes; the former untiered library codes, including the five AMC codes of #214 measured from its PR head 2adb6925 = the merged files, were run in the same panel), one process per pinned logical CPU in 0-71 (their SMT siblings 128-199 left idle), 4 GB cap (prlimit --as). MaxSAT (the default engine) in both cardinality modes of the tier rule, `-no-card` and `-card-mto`, seeds 0-4 (`-seed=0` = default search), **limit 5000 s for every code** (the c914ef5 table used 600/1800/5000 s by tier; the uniform limit lets every code be placed by the rule); seed 0 ran with the 6 h limit (the MaxSAT child ignores -cpu-lim, so its first 5000 s are the 5000 s run) and counts as timed out in the panel when it took longer; seeds 3-4 were skipped when seeds 0-2 all timed out (the median is then the limit). The recorded time is the 5-seed median (a timed-out seed counts as 5000 s). Tier 5: the 6 h seed-0 run per mode. CC rows are for information (default `-engine=cc -v`, seeds 0-2, 5000 s; 6 h seed 0 on tier 5). Column "vs c914ef5" = this median / the main c914ef5 median (2026-10-21 table, git history), for codes that had a c914ef5 row.

## Tiers 0-4 (5 seeds; the median is the reference)

| Tier | Case | Mode | Seeds | s0 | s1 | s2 | s3 | s4 | Median s | Min s | Max s | Solved | c914ef5 median s | vs c914ef5 |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|
| 0 | COLOR_7_1_3 | card-mto | 5 | 0.04 | 0.04 | 0.04 | 0.08 | 0.07 | 0.04 | 0.04 | 0.08 | yes | - | - |
| 0 | COLOR_7_1_3 | no-card | 5 | 0.04 | 0.04 | 0.04 | 0.07 | 0.07 | 0.04 | 0.04 | 0.07 | yes | - | - |
| 0 | HGP_13_1_3 | card-mto | 5 | 0.05 | 0.05 | 0.05 | 0.08 | 0.08 | 0.05 | 0.05 | 0.08 | yes | - | - |
| 0 | HGP_13_1_3 | no-card | 5 | 0.05 | 0.05 | 0.04 | 0.09 | 0.08 | 0.05 | 0.04 | 0.09 | yes | - | - |
| 0 | COLOR_19_1_5 | card-mto | 5 | 0.04 | 0.05 | 0.06 | 0.10 | 0.07 | 0.06 | 0.04 | 0.10 | yes | - | - |
| 0 | COLOR_19_1_5 | no-card | 5 | 0.06 | 0.04 | 0.04 | 0.08 | 0.08 | 0.06 | 0.04 | 0.08 | yes | - | - |
| 0 | BB_30_4_6 | card-mto | 5 | 0.05 | 0.05 | 0.04 | 0.06 | 0.07 | 0.05 | 0.04 | 0.07 | yes | - | - |
| 0 | BB_30_4_6 | no-card | 5 | 0.05 | 0.05 | 0.05 | 0.07 | 0.10 | 0.05 | 0.05 | 0.10 | yes | - | - |
| 0 | LP_34_20_2 | card-mto | 5 | 0.05 | 0.04 | 0.04 | 0.09 | 0.09 | 0.05 | 0.04 | 0.09 | yes | 0.07 | 0.671 |
| 0 | LP_34_20_2 | no-card | 5 | 0.05 | 0.05 | 0.05 | 0.10 | 0.09 | 0.05 | 0.05 | 0.10 | yes | 0.06 | 0.85 |
| 0 | TN_36_8_3 | card-mto | 5 | 0.06 | 0.07 | 0.06 | 0.10 | 0.10 | 0.07 | 0.06 | 0.10 | yes | 0.12 | 0.6 |
| 0 | TN_36_8_3 | no-card | 5 | 0.07 | 0.06 | 0.07 | 0.10 | 0.10 | 0.07 | 0.06 | 0.10 | yes | 0.13 | 0.523 |
| 0 | TN_36_8_4 | card-mto | 5 | 0.06 | 0.06 | 0.06 | 0.11 | 0.10 | 0.06 | 0.06 | 0.11 | yes | 0.16 | 0.388 |
| 0 | TN_36_8_4 | no-card | 5 | 0.07 | 0.06 | 0.06 | 0.10 | 0.10 | 0.07 | 0.06 | 0.10 | yes | 0.16 | 0.438 |
| 0 | HGP_41_1_5 | card-mto | 5 | 0.08 | 0.07 | 0.07 | 0.10 | 0.10 | 0.08 | 0.07 | 0.10 | yes | - | - |
| 0 | HGP_41_1_5 | no-card | 5 | 0.07 | 0.08 | 0.07 | 0.10 | 0.10 | 0.08 | 0.07 | 0.10 | yes | - | - |
| 0 | HGP_45_9_3 | card-mto | 5 | 0.06 | 0.05 | 0.06 | 0.10 | 0.10 | 0.06 | 0.05 | 0.10 | yes | - | - |
| 0 | HGP_45_9_3 | no-card | 5 | 0.05 | 0.06 | 0.05 | 0.09 | 0.08 | 0.06 | 0.05 | 0.09 | yes | - | - |
| 0 | TN_54_11_4 | card-mto | 5 | 0.06 | 0.06 | 0.07 | 0.10 | 0.10 | 0.07 | 0.06 | 0.10 | yes | 0.13 | 0.515 |
| 0 | TN_54_11_4 | no-card | 5 | 0.06 | 0.06 | 0.06 | 0.10 | 0.10 | 0.06 | 0.06 | 0.10 | yes | 0.13 | 0.492 |
| 0 | BB_72_12_6 | card-mto | 5 | 0.10 | 0.10 | 0.09 | 0.06 | 0.06 | 0.09 | 0.06 | 0.10 | yes | 0.11 | 0.855 |
| 0 | BB_72_12_6 | no-card | 5 | 0.10 | 0.10 | 0.10 | 0.06 | 0.06 | 0.10 | 0.06 | 0.10 | yes | 0.11 | 0.891 |
| 0 | TN_72_14_4 | card-mto | 5 | 0.09 | 0.09 | 0.08 | 0.07 | 0.07 | 0.08 | 0.07 | 0.09 | yes | 0.11 | 0.755 |
| 0 | TN_72_14_4 | no-card | 5 | 0.10 | 0.10 | 0.10 | 0.07 | 0.09 | 0.10 | 0.07 | 0.10 | yes | 0.11 | 0.864 |
| 0 | TN_72_8_8 | card-mto | 5 | 0.70 | 0.48 | 0.43 | 0.70 | 0.64 | 0.64 | 0.43 | 0.70 | yes | 0.68 | 0.937 |
| 0 | TN_72_8_8 | no-card | 5 | 0.52 | 0.52 | 0.73 | 0.63 | 0.69 | 0.63 | 0.52 | 0.73 | yes | 0.66 | 0.955 |
| 0 | BB_90_8_10 | card-mto | 5 | 0.10 | 0.08 | 0.12 | 0.08 | 0.09 | 0.09 | 0.08 | 0.12 | yes | 0.11 | 0.773 |
| 0 | BB_90_8_10 | no-card | 5 | 0.09 | 0.09 | 0.09 | 0.09 | 0.10 | 0.09 | 0.09 | 0.10 | yes | 0.14 | 0.643 |
| 0 | HGP_106_16_4 | card-mto | 5 | 0.11 | 0.11 | 0.10 | 0.09 | 0.11 | 0.11 | 0.09 | 0.11 | yes | - | - |
| 0 | HGP_106_16_4 | no-card | 5 | 0.09 | 0.11 | 0.10 | 0.09 | 0.11 | 0.10 | 0.09 | 0.11 | yes | - | - |
| 0 | AMC_108_6_9 | card-mto | 5 | 0.14 | 0.13 | 0.13 | 0.15 | 0.21 | 0.14 | 0.13 | 0.21 | yes | - | - |
| 0 | AMC_108_6_9 | no-card | 5 | 0.14 | 0.14 | 0.14 | 0.12 | 0.13 | 0.14 | 0.12 | 0.14 | yes | - | - |
| 0 | BB_108_8_10 | card-mto | 5 | 0.07 | 0.07 | 0.07 | 0.08 | 0.11 | 0.07 | 0.07 | 0.11 | yes | 0.14 | 0.536 |
| 0 | BB_108_8_10 | no-card | 5 | 0.08 | 0.08 | 0.07 | 0.10 | 0.11 | 0.08 | 0.07 | 0.11 | yes | 0.13 | 0.631 |
| 0 | HGP_113_1_8 | card-mto | 5 | 0.10 | 0.11 | 0.11 | 0.10 | 0.12 | 0.11 | 0.10 | 0.12 | yes | - | - |
| 0 | HGP_113_1_8 | no-card | 5 | 0.10 | 0.10 | 0.09 | 0.08 | 0.08 | 0.09 | 0.08 | 0.10 | yes | - | - |
| 0 | BB_120_8_12 | card-mto | 5 | 0.57 | 0.64 | 0.59 | 0.56 | 0.68 | 0.59 | 0.56 | 0.68 | yes | - | - |
| 0 | BB_120_8_12 | no-card | 5 | 0.46 | 0.53 | 0.65 | 0.55 | 0.58 | 0.55 | 0.46 | 0.65 | yes | - | - |
| 0 | LP_136_32_4 | card-mto | 5 | 0.11 | 0.11 | 0.10 | 0.10 | 0.11 | 0.11 | 0.10 | 0.11 | yes | 0.18 | 0.6 |
| 0 | LP_136_32_4 | no-card | 5 | 0.12 | 0.11 | 0.10 | 0.10 | 0.12 | 0.11 | 0.10 | 0.12 | yes | 0.17 | 0.647 |
| 0 | BB_144_12_12 | card-mto | 5 | 0.18 | 0.17 | 0.18 | 0.16 | 0.19 | 0.18 | 0.16 | 0.19 | yes | 0.34 | 0.518 |
| 0 | BB_144_12_12 | no-card | 5 | 0.14 | 0.14 | 0.17 | 0.16 | 0.19 | 0.16 | 0.14 | 0.19 | yes | 0.35 | 0.457 |
| 0 | GB_144_12_8 | card-mto | 5 | 0.12 | 0.11 | 0.11 | 0.10 | 0.10 | 0.11 | 0.10 | 0.12 | yes | 0.21 | 0.505 |
| 0 | GB_144_12_8 | no-card | 5 | 0.10 | 0.10 | 0.11 | 0.11 | 0.11 | 0.11 | 0.10 | 0.11 | yes | 0.20 | 0.535 |
| 0 | AMC_216_6_12 | card-mto | 5 | 0.37 | 0.37 | 0.42 | 0.35 | 0.42 | 0.37 | 0.35 | 0.42 | yes | - | - |
| 0 | AMC_216_6_12 | no-card | 5 | 0.36 | 0.32 | 0.30 | 0.35 | 0.49 | 0.35 | 0.30 | 0.49 | yes | - | - |
| 0 | LP_238_44_6 | card-mto | 5 | 0.36 | 0.24 | 0.30 | 0.34 | 0.32 | 0.32 | 0.24 | 0.36 | yes | 0.43 | 0.751 |
| 0 | LP_238_44_6 | no-card | 5 | 0.32 | 0.41 | 0.28 | 0.29 | 0.36 | 0.32 | 0.28 | 0.41 | yes | 0.44 | 0.73 |
| 0 | HGP_306_36_5 | card-mto | 5 | 0.39 | 0.41 | 0.49 | 0.42 | 0.50 | 0.42 | 0.39 | 0.50 | yes | - | - |
| 0 | HGP_306_36_5 | no-card | 5 | 0.38 | 0.37 | 0.41 | 0.36 | 0.40 | 0.38 | 0.36 | 0.41 | yes | - | - |
| 0 | AMC_330_6_14 | card-mto | 5 | 0.82 | 0.74 | 0.96 | 0.76 | 0.84 | 0.82 | 0.74 | 0.96 | yes | - | - |
| 0 | AMC_330_6_14 | no-card | 5 | 0.85 | 0.76 | 0.81 | 0.70 | 0.80 | 0.80 | 0.70 | 0.85 | yes | - | - |
| 1 | COLOR_127_1_13 | card-mto | 5 | 1.99 | 1.37 | 1.40 | 1.27 | 1.62 | 1.40 | 1.27 | 1.99 | yes | - | - |
| 1 | COLOR_127_1_13 | no-card | 5 | 1.69 | 1.60 | 1.60 | 1.47 | 1.39 | 1.60 | 1.39 | 1.69 | yes | - | - |
| 1 | GB_144_12_12 | card-mto | 5 | 1.04 | 1.10 | 1.05 | 1.11 | 1.12 | 1.10 | 1.04 | 1.12 | yes | 43.76 | 0.025 |
| 1 | GB_144_12_12 | no-card | 5 | 1.06 | 1.10 | 1.05 | 1.11 | 1.12 | 1.10 | 1.05 | 1.12 | yes | 58.96 | 0.019 |
| 1 | BB_186_10_14 | card-mto | 5 | 1.18 | 1.35 | 1.19 | 1.22 | 1.51 | 1.22 | 1.18 | 1.51 | yes | - | - |
| 1 | BB_186_10_14 | no-card | 5 | 1.29 | 1.11 | 0.99 | 1.19 | 1.11 | 1.11 | 0.99 | 1.29 | yes | - | - |
| 1 | HGP_265_1_12 | card-mto | 5 | 2.15 | 1.89 | 1.89 | 1.99 | 1.92 | 1.92 | 1.89 | 2.15 | yes | - | - |
| 1 | HGP_265_1_12 | no-card | 5 | 1.96 | 1.84 | 1.90 | 1.93 | 1.99 | 1.93 | 1.84 | 1.99 | yes | - | - |
| 1 | BB_288_12_18 | card-mto | 5 | 9.58 | 9.31 | 9.43 | 9.95 | 10.37 | 9.58 | 9.31 | 10.37 | yes | 50.62 | 0.189 |
| 1 | BB_288_12_18 | no-card | 5 | 9.44 | 9.29 | 9.42 | 9.24 | 9.53 | 9.42 | 9.24 | 9.53 | yes | 54.56 | 0.173 |
| 1 | LP_340_56_8 | card-mto | 5 | 1.83 | 2.44 | 1.88 | 2.05 | 2.20 | 2.05 | 1.83 | 2.44 | yes | 1.96 | 1.044 |
| 1 | LP_340_56_8 | no-card | 5 | 1.53 | 2.29 | 1.60 | 3.13 | 2.51 | 2.29 | 1.53 | 3.13 | yes | 2.29 | 1.0 |
| 1 | AMC_438_6_17 | card-mto | 5 | 11.53 | 8.94 | 8.69 | 9.08 | 11.18 | 9.08 | 8.69 | 11.53 | yes | - | - |
| 1 | AMC_438_6_17 | no-card | 5 | 8.85 | 9.00 | 11.00 | 4.88 | 8.52 | 8.85 | 4.88 | 11.00 | yes | - | - |
| 1 | LP_442_68_10 | card-mto | 5 | 5.10 | 4.57 | 5.50 | 5.51 | 4.95 | 5.10 | 4.57 | 5.51 | yes | 8.28 | 0.616 |
| 1 | LP_442_68_10 | no-card | 5 | 3.06 | 4.58 | 3.95 | 5.76 | 4.64 | 4.58 | 3.06 | 5.76 | yes | 8.32 | 0.551 |
| 1 | HGP_610_64_6 | card-mto | 5 | 9.47 | 8.39 | 8.09 | 8.72 | 10.05 | 8.72 | 8.09 | 10.05 | yes | - | - |
| 1 | HGP_610_64_6 | no-card | 5 | 9.13 | 10.27 | 12.08 | 8.10 | 9.53 | 9.53 | 8.10 | 12.08 | yes | - | - |
| 2 | TN_108_2_12 | card-mto | 5 | 23.85 | 21.70 | 25.57 | 19.54 | 19.49 | 21.70 | 19.49 | 25.57 | yes | 26.75 | 0.811 |
| 2 | TN_108_2_12 | no-card | 5 | 18.98 | 21.79 | 21.62 | 20.79 | 21.67 | 21.62 | 18.98 | 21.79 | yes | 22.05 | 0.98 |
| 2 | BB_144_14_14 | card-mto | 5 | 12.88 | 13.27 | 12.88 | 13.35 | 13.36 | 13.27 | 12.88 | 13.36 | yes | 23.97 | 0.554 |
| 2 | BB_144_14_14 | no-card | 5 | 12.39 | 12.46 | 13.00 | 13.57 | 13.56 | 13.00 | 12.39 | 13.57 | yes | 20.88 | 0.623 |
| 2 | TN_144_2_13 | card-mto | 5 | 90.56 | 82.44 | 91.11 | 85.16 | 83.01 | 85.16 | 82.44 | 91.11 | yes | 515 | 0.165 |
| 2 | TN_144_2_13 | no-card | 5 | 95.86 | 77.48 | 82.91 | 88.50 | 88.17 | 88.17 | 77.48 | 95.86 | yes | 306 | 0.288 |
| 2 | TN_200_10_10 | card-mto | 5 | 12.36 | 12.00 | 12.27 | 11.88 | 12.38 | 12.27 | 11.88 | 12.38 | yes | 20.94 | 0.586 |
| 2 | TN_200_10_10 | no-card | 5 | 11.55 | 11.74 | 12.53 | 11.96 | 12.68 | 11.96 | 11.55 | 12.68 | yes | 27.86 | 0.429 |
| 2 | BB_248_10_18 | card-mto | 5 | 33.00 | 32.49 | 32.16 | 33.45 | 33.78 | 33.00 | 32.16 | 33.78 | yes | - | - |
| 2 | BB_248_10_18 | no-card | 5 | 32.21 | 32.95 | 32.31 | 32.01 | 31.15 | 32.21 | 31.15 | 32.95 | yes | - | - |
| 2 | BB_340_16_18 | card-mto | 5 | 32.32 | 33.04 | 28.82 | 28.28 | 28.85 | 28.85 | 28.28 | 33.04 | yes | - | - |
| 2 | BB_340_16_18 | no-card | 5 | 33.81 | 27.74 | 28.82 | 27.93 | 29.66 | 28.82 | 27.74 | 33.81 | yes | - | - |
| 2 | AMC_522_6_20 | card-mto | 5 | 62.54 | 56.36 | 50.13 | 55.43 | 48.75 | 55.43 | 48.75 | 62.54 | yes | - | - |
| 2 | AMC_522_6_20 | no-card | 5 | 42.51 | 39.82 | 41.33 | 42.15 | 41.31 | 41.33 | 39.82 | 42.51 | yes | - | - |
| 2 | LP_544_80_12 | card-mto | 5 | 14.24 | 15.45 | 13.15 | 12.33 | 13.92 | 13.92 | 12.33 | 15.45 | yes | 61.36 | 0.227 |
| 2 | LP_544_80_12 | no-card | 5 | 14.12 | 13.76 | 13.82 | 16.35 | 15.23 | 14.12 | 13.76 | 16.35 | yes | 79.73 | 0.177 |
| 3 | TN_250_10_15 | card-mto | 5 | 1502 | 1283 | 1105 | 1171 | 1455 | 1283 | 1105 | 1502 | yes | 2866 | 0.448 |
| 3 | TN_250_10_15 | no-card | 5 | 1503 | 1218 | 1456 | 1218 | 1182 | 1218 | 1182 | 1503 | yes | 2821 | 0.432 |
| 3 | BB_294_10_20 | card-mto | 5 | 1557 | 601 | 580 | 430 | 571 | 580 | 430 | 1557 | yes | - | - |
| 3 | BB_294_10_20 | no-card | 5 | 1811 | 445 | 610 | 605 | 626 | 610 | 445 | 1811 | yes | - | - |
| 3 | HGP_481_1_16 | card-mto | 5 | 118 | 125 | 119 | 117 | 113 | 118 | 113 | 125 | yes | - | - |
| 3 | HGP_481_1_16 | no-card | 5 | 124 | 115 | 120 | 120 | 115 | 120 | 115 | 124 | yes | - | - |
| 3 | LP_714_100_16 | card-mto | 5 | 685 | 455 | 456 | 638 | 565 | 565 | 455 | 685 | yes | 626 | 0.902 |
| 3 | LP_714_100_16 | no-card | 5 | 559 | 593 | 541 | 366 | 481 | 541 | 366 | 593 | yes | 584 | 0.926 |
| 3 | LP_1020_136_16 | card-mto | 5 | 584 | 350 | 376 | 307 | 499 | 376 | 307 | 584 | yes | 1309 | 0.288 |
| 3 | LP_1020_136_16 | no-card | 5 | 593 | 362 | 393 | 327 | 533 | 393 | 327 | 593 | yes | 1331 | 0.295 |
| 3 | HGP_1261_121_6 | card-mto | 5 | 113 | 104 | 104 | 105 | 107 | 105 | 104 | 113 | yes | - | - |
| 3 | HGP_1261_121_6 | no-card | 5 | 112 | 104 | 107 | 106 | 107 | 107 | 104 | 112 | yes | - | - |
| 3 | HGP_2866_256_8 | card-mto | 5 | 516 | 562 | 742 | 929 | 475 | 562 | 475 | 929 | yes | - | - |
| 3 | HGP_2866_256_8 | no-card | 5 | 520 | 449 | 736 | 848 | 532 | 532 | 449 | 848 | yes | - | - |

"T" marks a seed that reached 5000 s (counted as 5000 s in the median); for seed 0 this includes runs that finished later inside its 6 h limit.

## Tier 5 (6 h, 1 run per cell, default seed)

| Case | Mode | Wall s | Result | Final lb | Final ub | lb reached at (s) | c914ef5 (wall s, lb, ub) |
|---|---|---:|---|---:|---:|---|---|
| TN_180_2_17 | card-mto | 6386 | solved | 17 | 17 | 2@0, 3@0, 5@0, 9@4, 17@6386 | 21600, 17, 19 |
| TN_180_2_17 | no-card | 6280 | solved | 17 | 17 | 2@0, 3@0, 5@0, 9@5, 17@6280 | 11486, 17, 17 |
| TN_216_4_18 | card-mto | 12207 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@5, 17@4391, 18@12207 | 19298, 18, 18 |
| TN_216_4_18 | no-card | 15120 | solved | 18 | 18 | 2@0, 3@0, 5@0, 9@6, 17@4693, 18@15120 | 14842, 18, 18 |
| TN_252_2_21 | card-mto | 21600 | TIMEOUT | 17 | 21 | 2@1, 3@1, 5@1, 9@5, 17@8206, 17@21600 | 21600, 17, - |
| TN_252_2_21 | no-card | 21600 | TIMEOUT | 17 | 21 | 2@1, 3@1, 5@1, 9@6, 17@8965, 17@21600 | 21600, 17, 28 |
| TN_288_2_23to24 | card-mto | 21600 | TIMEOUT | 9 | 24 | 2@1, 3@1, 5@1, 9@13, 9@21600 | 21600, 9, - |
| TN_288_2_23to24 | no-card | 21600 | TIMEOUT | 9 | 24 | 2@1, 3@1, 5@2, 9@15, 9@21600 | 21600, 9, - |
| TN_324_4_24to25 | card-mto | 21600 | TIMEOUT | 9 | 25 | 2@1, 3@1, 5@2, 9@16, 9@21600 | 21600, 9, - |
| TN_324_4_24to25 | no-card | 21600 | TIMEOUT | 9 | 25 | 2@1, 3@1, 5@2, 9@16, 9@21600 | 21600, 9, - |
| COLOR_331_1_21 | card-mto | 7914 | solved | 21 | 21 | 2@0, 3@0, 5@0, 9@1, 17@119, 21@7914 | - |
| COLOR_331_1_21 | no-card | 6472 | solved | 21 | 21 | 2@0, 3@0, 5@0, 9@1, 17@120, 21@6472 | - |
| BB_360_12_24 | card-mto | 12723 | solved | 24 | 24 | 2@0, 4@0, 6@0, 10@0, 18@11, 23@12723, 24@12723 | 21600, 18, 24 |
| BB_360_12_24 | no-card | 10317 | solved | 24 | 24 | 2@0, 4@0, 6@0, 10@0, 18@11, 23@10317, 24@10317 | 21600, 18, 24 |
| TN_360_4_24 | card-mto | 21600 | TIMEOUT | 17 | 24 | 2@1, 3@1, 5@2, 9@7, 17@9280, 17@21600 | 21600, 17, - |
| TN_360_4_24 | no-card | 21600 | TIMEOUT | 17 | 24 | 2@1, 3@1, 5@2, 9@6, 17@5539, 17@21600 | 21600, 17, - |
| TN_396_4_24to26 | card-mto | 21600 | TIMEOUT | 17 | 26 | 2@2, 3@2, 5@2, 9@9, 17@4720, 17@21600 | 21600, 17, - |
| TN_396_4_24to26 | no-card | 21600 | TIMEOUT | 17 | 26 | 2@2, 3@2, 5@2, 9@11, 17@6610, 17@21600 | 21600, 17, - |
| TN_432_8_24to29 | card-mto | 21600 | TIMEOUT | 9 | 33 | 2@2, 3@2, 5@3, 9@23, 9@21600 | 21600, 9, - |
| TN_432_8_24to29 | no-card | 21600 | TIMEOUT | 9 | 33 | 2@2, 3@3, 5@6, 9@33, 9@21600 | 21600, 9, - |
| TN_468_4_24to29 | card-mto | 21600 | TIMEOUT | 17 | 29 | 2@9, 3@10, 5@10, 9@19, 17@7588, 17@21600 | 21600, 17, - |
| TN_468_4_24to29 | no-card | 21600 | TIMEOUT | 17 | 29 | 2@10, 3@10, 5@11, 9@20, 17@6895, 17@21600 | 21600, 17, - |
| TN_496_2_29to30 | card-mto | 21600 | TIMEOUT | 17 | 32 | 2@3, 3@3, 5@3, 9@9, 17@9742, 17@21600 | 21600, 17, - |
| TN_496_2_29to30 | no-card | 21600 | TIMEOUT | 17 | 32 | 2@3, 3@3, 5@3, 9@9, 17@11666, 17@21600 | 21600, 17, - |
| TN_504_2_25to34 | card-mto | 21600 | TIMEOUT | 17 | 47 | 2@2, 3@2, 5@2, 9@12, 17@5427, 17@21600 | 21600, 17, - |
| TN_504_2_25to34 | no-card | 21600 | TIMEOUT | 17 | 47 | 2@2, 3@2, 5@3, 9@10, 17@6126, 17@21600 | 21600, 17, - |
| TN_540_4_25to34 | card-mto | 21600 | TIMEOUT | 9 | 40 | 2@5, 3@5, 5@8, 9@35, 9@21600 | 21600, 9, - |
| TN_540_4_25to34 | no-card | 21600 | TIMEOUT | 9 | 40 | 2@5, 3@5, 5@8, 9@38, 9@21600 | 21600, 9, - |
| TN_576_2_25to37 | card-mto | 21600 | TIMEOUT | 9 | 43 | 2@3, 3@3, 5@8, 9@36, 9@21600 | 21600, 9, - |
| TN_576_2_25to37 | no-card | 21600 | TIMEOUT | 9 | 43 | 2@3, 3@3, 5@8, 9@40, 9@21600 | 21600, 9, - |
| TN_612_2_25to40 | card-mto | 21600 | TIMEOUT | 17 | 41 | 2@6, 3@6, 5@6, 9@14, 17@7362, 17@21600 | 21600, 17, - |
| TN_612_2_25to40 | no-card | 21600 | TIMEOUT | 17 | 41 | 2@6, 3@6, 5@6, 9@15, 17@6932, 17@21600 | 21600, 17, - |
| TN_648_10_23to32 | card-mto | 21600 | TIMEOUT | 9 | 47 | 2@5, 3@5, 5@10, 9@65, 9@21600 | 21600, 9, - |
| TN_648_10_23to32 | no-card | 21600 | TIMEOUT | 9 | 47 | 2@5, 3@5, 5@10, 9@57, 9@21600 | 21600, 9, - |
| TN_648_14_23to28 | card-mto | 21600 | TIMEOUT | 9 | 31 | 2@6, 3@6, 5@13, 9@64, 9@21600 | 21600, 9, - |
| TN_648_14_23to28 | no-card | 21600 | TIMEOUT | 9 | 31 | 2@6, 3@6, 5@12, 9@76, 9@21600 | 21600, 9, - |
| TN_684_2_24to29 | card-mto | 21600 | TIMEOUT | 17 | 31 | 2@5, 3@5, 5@5, 9@19, 17@18931, 17@21600 | 21600, 9, - |
| TN_684_2_24to29 | no-card | 21600 | TIMEOUT | 17 | 31 | 2@5, 3@5, 5@5, 9@20, 17@18881, 17@21600 | 21600, 9, - |
| BB_756_16_34 | card-mto | 21600 | TIMEOUT | 18 | 34 | 2@10, 4@10, 6@10, 10@10, 18@18, 18@21600 | 21600, 18, - |
| BB_756_16_34 | no-card | 21600 | TIMEOUT | 18 | 34 | 2@10, 4@10, 6@10, 10@11, 18@18, 18@21600 | 21600, 18, - |
| BB_864_4_34to40 | card-mto | 21600 | TIMEOUT | 18 | 50 | 2@12, 4@12, 6@12, 10@12, 18@20, 18@21600 | 21600, 18, - |
| BB_864_4_34to40 | no-card | 21600 | TIMEOUT | 18 | 50 | 2@12, 4@12, 6@12, 10@12, 18@20, 18@21600 | 21600, 18, - |
| COLOR_1027_1_33to37 | card-mto | 21600 | TIMEOUT | 17 | 37 | 2@46, 3@46, 5@46, 9@51, 17@1729, 17@21600 | - |
| COLOR_1027_1_33to37 | no-card | 21600 | TIMEOUT | 17 | 37 | 2@46, 3@46, 5@46, 9@51, 17@1758, 17@21600 | - |
| LP_1054_140_20 | card-mto | 21600 | TIMEOUT | 18 | 20 | 2@1, 4@2, 6@3, 10@11, 18@5978, 18@21600 | 21600, 18, 32 |
| LP_1054_140_20 | no-card | 21600 | TIMEOUT | 18 | 20 | 2@1, 4@2, 6@3, 10@15, 18@6760, 18@21600 | 21600, 18, 32 |
| BB_1080_4_34to48 | card-mto | 21600 | TIMEOUT | 18 | 60 | 2@29, 4@29, 6@29, 10@29, 18@40, 18@21600 | 21600, 18, - |
| BB_1080_4_34to48 | no-card | 21600 | TIMEOUT | 18 | 60 | 2@29, 4@29, 6@29, 10@29, 18@39, 18@21600 | 21600, 18, - |
| HGP_1105_1_24 | card-mto | 21600 | TIMEOUT | 17 | 24 | 2@61, 3@61, 5@61, 9@64, 17@2097, 17@21600 | - |
| HGP_1105_1_24 | no-card | 21600 | TIMEOUT | 17 | 24 | 2@61, 3@61, 5@61, 9@63, 17@2099, 17@21600 | - |
| LP_1122_148_20 | card-mto | 19865 | solved | 20 | 20 | 2@1, 4@2, 6@4, 10@9, 18@6701, 19@19865, 20@19865 | 21600, 18, 32 |
| LP_1122_148_20 | no-card | 20456 | solved | 20 | 20 | 2@1, 4@2, 6@3, 10@12, 18@6701, 19@20456, 20@20456 | 21600, 18, 32 |
| LP_1428_184_24 | card-mto | 21600 | TIMEOUT | 18 | 24 | 2@14, 4@16, 6@18, 10@25, 18@2976, 18@21600 | 21600, 18, 32 |
| LP_1428_184_24 | no-card | 21600 | TIMEOUT | 18 | 24 | 2@14, 4@16, 6@18, 10@25, 18@2984, 18@21600 | 21600, 18, 32 |
| LP_1768_224_22 | card-mto | 21600 | TIMEOUT | 18 | 22 | 2@54, 4@57, 6@62, 10@89, 18@7745, 18@21600 | 21600, 18, - |
| LP_1768_224_22 | no-card | 21600 | TIMEOUT | 18 | 22 | 2@53, 4@57, 6@62, 10@89, 18@4533, 18@21600 | 21600, 18, - |
| LP_2610_744_16 | card-mto | 21600 | TIMEOUT | 10 | 16 | 2@8, 4@26, 6@69, 10@397, 10@21600 | 21600, 10, 16 |
| LP_2610_744_16 | no-card | 21600 | TIMEOUT | 10 | 16 | 2@8, 4@25, 6@69, 10@398, 10@21600 | 21600, 10, 16 |
| COLOR_2791_1_30to61 | card-mto | 21600 | TIMEOUT | 17 | 63 | 2@70, 3@71, 5@72, 9@103, 17@18089, 17@21600 | - |
| COLOR_2791_1_30to61 | no-card | 21600 | TIMEOUT | 17 | 63 | 2@70, 3@70, 5@71, 9@102, 17@17980, 17@21600 | - |

## CC engine (information only; not used for tier placement)

| Tier | Case | CC default s0 / s1 / s2 (s) | CC median s | CC 6 h (seed 0) | CC opt-in full median s | Lightest GF(2)-verified word |
|---:|---|---|---:|---|---:|---:|
| 0 | COLOR_7_1_3 | 0.06 / 0.06 / 0.06 | 0.06 | - | 0.06 | 3 |
| 0 | HGP_13_1_3 | 0.07 / 0.08 / 0.08 | 0.08 | - | 0.08 | 3 |
| 0 | COLOR_19_1_5 | 0.10 / 0.09 / 0.09 | 0.09 | - | 0.09 | 5 |
| 0 | BB_30_4_6 | 0.08 / 0.10 / 0.08 | 0.08 | - | 0.09 | 6 |
| 0 | LP_34_20_2 | 0.04 / 0.04 / 0.04 | 0.04 | - | - | 2 |
| 0 | TN_36_8_3 | 0.07 / 0.07 / 0.07 | 0.07 | - | - | 3 |
| 0 | TN_36_8_4 | 0.06 / 0.06 / 0.06 | 0.06 | - | - | 4 |
| 0 | HGP_41_1_5 | 0.09 / 0.09 / 0.08 | 0.09 | - | 0.08 | 5 |
| 0 | HGP_45_9_3 | 0.08 / 0.08 / 0.10 | 0.08 | - | 0.09 | 3 |
| 0 | TN_54_11_4 | 0.05 / 0.05 / 0.07 | 0.05 | - | - | 4 |
| 0 | BB_72_12_6 | 0.09 / 0.09 / 0.08 | 0.09 | - | - | 6 |
| 0 | TN_72_14_4 | 0.07 / 0.07 / 0.07 | 0.07 | - | - | 4 |
| 0 | TN_72_8_8 | 0.08 / 0.09 / 0.07 | 0.08 | - | - | 8 |
| 0 | BB_90_8_10 | 0.07 / 0.08 / 0.07 | 0.07 | - | - | 10 |
| 0 | HGP_106_16_4 | 0.08 / 0.09 / 0.08 | 0.08 | - | 0.08 | 4 |
| 0 | AMC_108_6_9 | 0.08 / 0.08 / 0.07 | 0.08 | - | 0.09 | 9 |
| 0 | BB_108_8_10 | 0.06 / 0.06 / 0.06 | 0.06 | - | - | 10 |
| 0 | HGP_113_1_8 | 0.07 / 0.07 / 0.07 | 0.07 | - | 0.07 | 8 |
| 0 | BB_120_8_12 | 0.08 / 0.07 / 0.08 | 0.08 | - | 0.10 | 12 |
| 0 | LP_136_32_4 | 0.07 / 0.07 / 0.06 | 0.07 | - | - | 4 |
| 0 | BB_144_12_12 | 0.07 / 0.06 / 0.06 | 0.06 | - | - | 12 |
| 0 | GB_144_12_8 | 0.08 / 0.08 / 0.10 | 0.08 | - | - | 8 |
| 0 | AMC_216_6_12 | 0.10 / 0.08 / 0.07 | 0.08 | - | 0.07 | 12 |
| 0 | LP_238_44_6 | 0.10 / 0.09 / 0.10 | 0.10 | - | - | 6 |
| 0 | HGP_306_36_5 | 0.06 / 0.07 / 0.06 | 0.06 | - | 0.06 | 5 |
| 0 | AMC_330_6_14 | 0.07 / 0.07 / 0.06 | 0.07 | - | 0.07 | 14 |
| 1 | COLOR_127_1_13 | 0.08 / 0.09 / 0.07 | 0.08 | - | 0.07 | 13 |
| 1 | GB_144_12_12 | 0.12 / 0.09 / 0.09 | 0.09 | - | - | 12 |
| 1 | BB_186_10_14 | 0.08 / 0.08 / 0.07 | 0.08 | - | 0.09 | 14 |
| 1 | HGP_265_1_12 | 0.08 / 0.09 / 0.10 | 0.09 | - | 0.08 | 12 |
| 1 | BB_288_12_18 | 0.42 / 0.41 / 0.42 | 0.42 | - | - | 18 |
| 1 | LP_340_56_8 | 0.07 / 0.11 / 0.11 | 0.11 | - | - | 8 |
| 1 | AMC_438_6_17 | 0.13 / 0.12 / 0.12 | 0.12 | - | 0.10 | 17 |
| 1 | LP_442_68_10 | 0.08 / 0.08 / 0.07 | 0.08 | - | - | 10 |
| 1 | HGP_610_64_6 | 0.26 / 0.19 / 0.13 | 0.19 | - | 0.19 | 6 |
| 2 | TN_108_2_12 | 0.96 / 2.13 / 2.56 | 2.13 | - | - | 12 |
| 2 | BB_144_14_14 | 0.94 / 0.69 / 0.65 | 0.69 | - | - | 14 |
| 2 | TN_144_2_13 | 1.87 / 4.87 / 5.73 | 4.87 | - | - | 13 |
| 2 | TN_200_10_10 | 0.15 / 0.20 / 0.20 | 0.20 | - | - | 10 |
| 2 | BB_248_10_18 | 0.55 / 0.54 / 0.60 | 0.55 | - | 0.43 | 18 |
| 2 | BB_340_16_18 | 0.31 / 0.32 / 0.34 | 0.32 | - | 0.26 | 18 |
| 2 | AMC_522_6_20 | 0.48 / 0.57 / 0.57 | 0.57 | - | 0.26 | 20 |
| 2 | LP_544_80_12 | 0.08 / 0.09 / 0.07 | 0.08 | - | - | 12 |
| 3 | TN_250_10_15 | 33.94 / 62.21 / 62.78 | 62.21 | - | - | 15 |
| 3 | BB_294_10_20 | 2.30 / 2.34 / 2.36 | 2.34 | - | 1.22 | 20 |
| 3 | HGP_481_1_16 | 0.24 / 0.25 / 0.24 | 0.24 | - | 0.13 | 16 |
| 3 | LP_714_100_16 | 0.37 / 0.57 / 0.53 | 0.53 | - | - | 16 |
| 3 | LP_1020_136_16 | - | - | solved 16 in 0.30 s | - | 16 |
| 3 | HGP_1261_121_6 | 3.40 / 1.87 / 5.86 | 3.40 | - | 3.37 | 6 |
| 3 | HGP_2866_256_8 | 233 / 275 / 257 | 257 | - | 191 | 8 |
| 5 | TN_180_2_17 | - | - | solved 17 in 160 s | - | 17 |
| 5 | TN_216_4_18 | - | - | solved 18 in 508 s | - | 18 |
| 5 | TN_252_2_21 | - | - | solved 21 in 8714 s | - | 21 |
| 5 | TN_288_2_23to24 | - | - | TIMEOUT lb 22 ub 24 | - | 24 |
| 5 | TN_324_4_24to25 | - | - | TIMEOUT lb 22 ub 25 | - | 25 |
| 5 | COLOR_331_1_21 | 21.25 / 122 / 148 | 122 | - | 13.65 | 21 |
| 5 | BB_360_12_24 | - | - | solved 24 in 202 s | - | 24 |
| 5 | TN_360_4_24 | - | - | TIMEOUT lb 22 ub 24 | - | 24 |
| 5 | TN_396_4_24to26 | - | - | TIMEOUT lb 22 ub 26 | - | 26 |
| 5 | TN_432_8_24to29 | - | - | TIMEOUT lb 23 ub 29 | - | 29 |
| 5 | TN_468_4_24to29 | - | - | TIMEOUT lb 23 ub 29 | - | 29 |
| 5 | TN_496_2_29to30 | - | - | TIMEOUT lb 23 ub 30 | - | 30 |
| 5 | TN_504_2_25to34 | - | - | TIMEOUT lb 23 ub 34 | - | 34 |
| 5 | TN_540_4_25to34 | - | - | TIMEOUT lb 23 ub 34 | - | 34 |
| 5 | TN_576_2_25to37 | - | - | TIMEOUT lb 24 ub 38 | - | 38 |
| 5 | TN_612_2_25to40 | - | - | TIMEOUT lb 24 ub 41 | - | 41 |
| 5 | TN_648_10_23to32 | - | - | TIMEOUT lb 21 ub 33 | - | 33 |
| 5 | TN_648_14_23to28 | - | - | TIMEOUT lb 21 ub 31 | - | 31 |
| 5 | TN_684_2_24to29 | - | - | TIMEOUT lb 22 ub 29 | - | 29 |
| 5 | BB_756_16_34 | - | - | TIMEOUT lb 28 ub 34 | - | 34 |
| 5 | BB_864_4_34to40 | - | - | TIMEOUT lb 30 ub 42 | - | 42 |
| 5 | COLOR_1027_1_33to37 | T / T / T | 5000 | TIMEOUT lb 29 ub 37 | 5000 | 37 |
| 5 | LP_1054_140_20 | - | - | solved 20 in 2.00 s | - | 20 |
| 5 | BB_1080_4_34to48 | - | - | TIMEOUT lb 30 ub 66 | - | 66 |
| 5 | HGP_1105_1_24 | 71.64 / 181 / 189 | 181 | - | 3.86 | 24 |
| 5 | LP_1122_148_20 | - | - | solved 20 in 5.30 s | - | 20 |
| 5 | LP_1428_184_24 | - | - | solved 24 in 147 s | - | 24 |
| 5 | LP_1768_224_22 | - | - | solved 22 in 17.70 s | - | 22 |
| 5 | LP_2610_744_16 | - | - | solved 16 in 2.70 s | - | 16 |
| 5 | COLOR_2791_1_30to61 | T / T / T | 5000 | TIMEOUT lb 28 ub 61 | 5000 | 61 |

## Tier placement (rule PI 2026-10-12: slower-mode MaxSAT median on this server; <1 s t0, 1-10 t1, 10-100 t2, 100-2000 t3, 2000-5000 t4, else t5)

| Case | Was | Slower mode | Slower-mode median s | Rule tier | Move |
|---|---|---|---:|---:|---|
| COLOR_7_1_3 | untiered/COLOR_7_1_unknown | no-card | 0.04 | 0 | untiered -> tier0 |
| HGP_13_1_3 | untiered/HGP_13_1_unknown | no-card | 0.05 | 0 | untiered -> tier0 |
| COLOR_19_1_5 | untiered/COLOR_19_1_unknown | no-card | 0.06 | 0 | untiered -> tier0 |
| BB_30_4_6 | untiered/BB_30_4_unknown | no-card | 0.05 | 0 | untiered -> tier0 |
| LP_34_20_2 | tier0 | no-card | 0.05 | 0 | no |
| TN_36_8_3 | tier0 | no-card | 0.07 | 0 | no |
| TN_36_8_4 | tier0 | no-card | 0.07 | 0 | no |
| HGP_41_1_5 | untiered/HGP_41_1_unknown | no-card | 0.08 | 0 | untiered -> tier0 |
| HGP_45_9_3 | untiered/HGP_45_9_unknown | no-card | 0.06 | 0 | untiered -> tier0 |
| TN_54_11_4 | tier0 | card-mto | 0.07 | 0 | no |
| BB_72_12_6 | tier0 | no-card | 0.10 | 0 | no |
| TN_72_14_4 | tier0 | no-card | 0.10 | 0 | no |
| TN_72_8_8 | tier0 | card-mto | 0.64 | 0 | no |
| BB_90_8_10 | tier0 | no-card | 0.09 | 0 | no |
| HGP_106_16_4 | untiered/HGP_106_16_unknown | card-mto | 0.11 | 0 | untiered -> tier0 |
| AMC_108_6_9 | untiered/AMC_108_6_unknown | no-card | 0.14 | 0 | untiered -> tier0 |
| BB_108_8_10 | tier0 | no-card | 0.08 | 0 | no |
| HGP_113_1_8 | untiered/HGP_113_1_unknown | card-mto | 0.11 | 0 | untiered -> tier0 |
| BB_120_8_12 | untiered/BB_120_8_unknown | card-mto | 0.59 | 0 | untiered -> tier0 |
| LP_136_32_4 | tier0 | no-card | 0.11 | 0 | no |
| BB_144_12_12 | tier0 | card-mto | 0.18 | 0 | no |
| GB_144_12_8 | tier0 | no-card | 0.11 | 0 | no |
| AMC_216_6_12 | untiered/AMC_216_6_unknown | card-mto | 0.37 | 0 | untiered -> tier0 |
| LP_238_44_6 | tier0 | no-card | 0.32 | 0 | no |
| HGP_306_36_5 | untiered/HGP_306_36_unknown | card-mto | 0.42 | 0 | untiered -> tier0 |
| AMC_330_6_14 | untiered/AMC_330_6_unknown | card-mto | 0.82 | 0 | untiered -> tier0 |
| COLOR_127_1_13 | untiered/COLOR_127_1_unknown | no-card | 1.60 | 1 | untiered -> tier1 |
| GB_144_12_12 | tier2 | no-card | 1.10 | 1 | tier2 -> tier1 |
| BB_186_10_14 | untiered/BB_186_10_unknown | card-mto | 1.22 | 1 | untiered -> tier1 |
| HGP_265_1_12 | untiered/HGP_265_1_unknown | no-card | 1.93 | 1 | untiered -> tier1 |
| BB_288_12_18 | tier2 | card-mto | 9.58 | 1 | tier2 -> tier1 |
| LP_340_56_8 | tier1 | no-card | 2.29 | 1 | no |
| AMC_438_6_17 | untiered/AMC_438_6_unknown | card-mto | 9.08 | 1 | untiered -> tier1 |
| LP_442_68_10 | tier1 | card-mto | 5.10 | 1 | no |
| HGP_610_64_6 | untiered/HGP_610_64_unknown | no-card | 9.53 | 1 | untiered -> tier1 |
| TN_108_2_12 | tier2 | card-mto | 21.70 | 2 | no |
| BB_144_14_14 | tier2 | card-mto | 13.27 | 2 | no |
| TN_144_2_13 | tier3 | no-card | 88.17 | 2 | tier3 -> tier2 |
| TN_200_10_10 | tier2 | card-mto | 12.27 | 2 | no |
| BB_248_10_18 | untiered/BB_248_10_unknown | card-mto | 33.00 | 2 | untiered -> tier2 |
| BB_340_16_18 | untiered/BB_340_16_unknown | card-mto | 28.85 | 2 | untiered -> tier2 |
| AMC_522_6_20 | untiered/AMC_522_6_unknown | card-mto | 55.43 | 2 | untiered -> tier2 |
| LP_544_80_12 | tier2 | no-card | 14.12 | 2 | no |
| TN_250_10_15 | tier4 | card-mto | 1283 | 3 | tier4 -> tier3 |
| BB_294_10_20 | untiered/BB_294_10_unknown | no-card | 610 | 3 | untiered -> tier3 |
| HGP_481_1_16 | untiered/HGP_481_1_unknown | no-card | 120 | 3 | untiered -> tier3 |
| LP_714_100_16 | tier3 | card-mto | 565 | 3 | no |
| LP_1020_136_16 | tier5 | no-card | 393 | 3 | tier5 -> tier3 |
| HGP_1261_121_6 | untiered/HGP_1261_121_unknown | no-card | 107 | 3 | untiered -> tier3 |
| HGP_2866_256_8 | untiered/HGP_2866_256_unknown | card-mto | 562 | 3 | untiered -> tier3 |
| TN_180_2_17 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_216_4_18 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_252_2_21 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_288_2_23to24 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_324_4_24to25 | tier5 | - | unsolved / > 5000 | 5 | no |
| COLOR_331_1_21 | untiered/COLOR_331_1_unknown | no-card | unsolved / > 5000 | 5 | untiered -> tier5 |
| BB_360_12_24 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_360_4_24 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_396_4_24to26 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_432_8_24to29 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_468_4_24to29 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_496_2_29to30 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_504_2_25to34 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_540_4_25to34 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_576_2_25to37 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_612_2_25to40 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_648_10_23to32 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_648_14_23to28 | tier5 | - | unsolved / > 5000 | 5 | no |
| TN_684_2_24to29 | tier5 | - | unsolved / > 5000 | 5 | no |
| BB_756_16_34 | tier5 | - | unsolved / > 5000 | 5 | no |
| BB_864_4_34to40 | tier5 | - | unsolved / > 5000 | 5 | no |
| COLOR_1027_1_33to37 | untiered/COLOR_1027_1_unknown | no-card | 5000 | 5 | untiered -> tier5 |
| LP_1054_140_20 | tier5 | - | unsolved / > 5000 | 5 | no |
| BB_1080_4_34to48 | tier5 | - | unsolved / > 5000 | 5 | no |
| HGP_1105_1_24 | untiered/HGP_1105_1_unknown | no-card | 5000 | 5 | untiered -> tier5 |
| LP_1122_148_20 | tier5 | - | unsolved / > 5000 | 5 | no |
| LP_1428_184_24 | tier5 | - | unsolved / > 5000 | 5 | no |
| LP_1768_224_22 | tier5 | - | unsolved / > 5000 | 5 | no |
| LP_2610_744_16 | tier5 | - | unsolved / > 5000 | 5 | no |
| COLOR_2791_1_30to61 | untiered/COLOR_2791_1_unknown | no-card | 5000 | 5 | untiered -> tier5 |

Notes:
- Replaces the main c914ef5 table (2026-10-21; git history). The Mac table (README.md, main_mac_reference.json) was not re-recorded: the Mac is reserved for timing work of other rounds.
- vs main c914ef5, geomean of per-cell median ratios over the codes that have a c914ef5 row (new tiers): tier0 card-mto 0.628, no-card 0.644 (start-up dominated); tier1 card-mto 0.235, no-card 0.206; tier2 card-mto 0.397, no-card 0.422; tier3 card-mto 0.488, no-card 0.490. No tier 0-4 cell is slower than 1.10x.
- **Same-day drift check.** (a) The previous baseline binary (frozen/server-main-c914ef5, sha256 `8e290383…`) was re-run on 5 codes (TN_108_2_12, TN_200_10_10, BB_144_14_14, LP_544_80_12, TN_144_2_13) x 2 modes x seeds 0-2 on clean cores 8-10 after the panel: per-seed geomean 0.905 against the recorded c914ef5 seeds (cells 0.73-0.99; LP_544_80_12 0.73-0.74), i.e. the host is about 10 % faster than on 2026-10-21. (b) 02879a93 itself on the same 30 cells (cores 11-12): 0.969 against this panel's seeds. So the panel ran about 3 % slower than the quiet host, and roughly 0.905 / 0.969 = 0.93 of each "vs c914ef5" ratio is host drift rather than solver change. Raw: raw/main-02879a93/drift_c914ef5_results.jsonl, drift_02879a93_results.jsonl.
- **Host load.** Shared host: the 6 h wave ran with load averages of about 120-200 (other users' unpinned jobs, other rounds on cores 72-127, a PI Codex batch on cores 0-89 at the start, which the runner avoided); the runner never started a process on a core that another process was pinned to or that was > 30 % busy (raw/main-02879a93/load.txt).
- **AMC codes (#214).** Merged into untiered/ while this table was prepared and placed by the PI the same day from these medians: AMC_108_6_9, AMC_216_6_12, AMC_330_6_14 tier 0, AMC_438_6_17 tier 1 (9.08 s, near the tier1/tier2 boundary), AMC_522_6_20 tier 2. Their inputs (PR head 2adb6925) are byte-identical to the merged files.
- **Codes within ~10 % of a tier boundary** (placed by the measured value; may move on a re-record): GB_144_12_12 1.10 s (tier1/tier0), BB_288_12_18 9.58 s and HGP_610_64_6 9.53 s (tier1/tier2), TN_144_2_13 88.2 s (tier2/tier3), HGP_1261_121_6 106.8 s (tier3/tier2).
- **Runner note.** The queue's follow-up rule skipped seeds 3-4 when two of seeds 0-2 had timed out (intended: all three). The only affected cell, COLOR_331_1_21 no-card, got seeds 3-4 from runner/server_retier_extra_20261104.py (seed 3 timed out, seed 4 4560 s): median 5000 s, tier 5.
- **Tier 5.** MaxSAT solves TN_180_2_17 (6280 / 6386 s), TN_216_4_18 (15120 / 12207 s), BB_360_12_24 (10317 / 12723 s), LP_1122_148_20 (20456 / 19865 s) and COLOR_331_1_21 (6472 / 7914 s; seeds 1-4 4278-4593 s card-mto) within 6 h but over 5000 s, so they stay in tier 5. LP_1020_136_16 (seed 0 593 / 584 s, 5-seed medians 393 / 376 s) moves to tier 3. HGP_1105_1_24 is unsolved by MaxSAT in 6 h (lb 17, ub 24).
- **Correctness.** 1173 panel runs plus the extra runs: every answer and bound is consistent with the stems and with the published distances of the library codes; no MEMOUT under the 4 GB cap, no runner kill. Every numeric distance has a logical of exactly that weight that passed an independent pure-Python GF(2) check (x ∈ ker H_other \ rowspan H_same) from the CC `-v` logs or the bundled basis rows (raw/main-02879a93/witness_check.jsonl: 395 logs, all witnesses valid; witnesses_lightest.txt: the lightest verified word per code).
- **CC engine (information).** CC is faster than MaxSAT on every code that MaxSAT solves (ties only at the tier-0 start-up floor) and solves TN_252_2_21 (8714 s), LP_1054/1122/1428/1768/2610 (2-147 s), HGP_1105_1_24 (72-189 s) that MaxSAT does not solve in 6 h. Its 6 h lower bounds on the open TN/BB codes are at or below the stems' (which came from opt-in or older CC configurations): TN_360/396 22 (stem 23), TN_504 23 (24), TN_648_10 21 (22), TN_496 23 (27), BB_756 28, BB_864/1080 30 (32). It raised four open lower bounds above the stems in single runs: TN_468_4 23 (stem 17), TN_612_2 24 (17), TN_648_14 21 (9), TN_684_2 22 (9); these are PLAUSIBLE only and the stems are unchanged: relabeled CC runs (`-seed=1`) were 3-6x slower per level and were stopped after about 1.6 h at levels 19-20 (TN) when it was clear they could not reach the target levels within 6 h (raw/main-02879a93/server_extra_results.jsonl); a reproduction with a different search order (e.g. `mrv`, 12 h, as for GH-152/GH-157) is needed before renaming. The same holds for COLOR_1027 lb 29 and COLOR_2791 lb 28 (single 6 h runs); their stems use the lower bounds reached by two different searches (28 and 26).
