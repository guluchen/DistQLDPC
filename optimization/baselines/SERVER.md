# Recorded main baseline times on yfclab2 (2026-10-12)

Binary: main a3fe591 built on yfclab2 (frozen/server-main/distqldpc), sha256 `56e12016921c59a73119e5af981172e5a2972648d443ec1b6e42884915988215`. Method: 3 runs per case/mode, pool of 120 workers on physical cores 0-59,64-123 (taskset), 4 GB cap (prlimit, server rule), limits tier0 600 s, tier1-3 1800 s, tier4 2000 s; up to 120 processes ran concurrently.

| Tier | Case | Mode | Runs | Median s | Min s | Max s | Solved |
|---:|---|---|---:|---:|---:|---:|---|
| 0 | BB_72_12_6 | card-mto | 3 | 0.22 | 0.21 | 0.26 | yes |
| 0 | BB_72_12_6 | no-card | 3 | 0.28 | 0.25 | 0.29 | yes |
| 0 | LP_136_32_4 | card-mto | 3 | 0.42 | 0.39 | 0.43 | yes |
| 0 | LP_136_32_4 | no-card | 3 | 0.43 | 0.4 | 0.45 | yes |
| 0 | LP_34_20_2 | card-mto | 3 | 0.11 | 0.1 | 0.14 | yes |
| 0 | LP_34_20_2 | no-card | 3 | 0.11 | 0.1 | 0.12 | yes |
| 0 | TN_108_2_12 | card-mto | 3 | 25.67 | 25.65 | 25.72 | yes |
| 0 | TN_108_2_12 | no-card | 3 | 20.66 | 20.65 | 20.97 | yes |
| 0 | TN_200_10_10 | card-mto | 3 | 17.23 | 17.18 | 17.61 | yes |
| 0 | TN_200_10_10 | no-card | 3 | 119.22 | 119.18 | 119.38 | yes |
| 0 | TN_36_8_3 | card-mto | 3 | 0.1 | 0.09 | 0.11 | yes |
| 0 | TN_36_8_3 | no-card | 3 | 0.1 | 0.08 | 0.11 | yes |
| 0 | TN_36_8_4 | card-mto | 3 | 0.2 | 0.18 | 0.21 | yes |
| 0 | TN_36_8_4 | no-card | 3 | 0.18 | 0.15 | 0.22 | yes |
| 0 | TN_54_11_4 | card-mto | 3 | 0.19 | 0.11 | 0.2 | yes |
| 0 | TN_54_11_4 | no-card | 3 | 0.17 | 0.14 | 0.2 | yes |
| 0 | TN_72_14_4 | card-mto | 3 | 0.17 | 0.16 | 0.17 | yes |
| 0 | TN_72_14_4 | no-card | 3 | 0.19 | 0.15 | 0.2 | yes |
| 0 | TN_72_8_8 | card-mto | 3 | 0.81 | 0.8 | 0.81 | yes |
| 0 | TN_72_8_8 | no-card | 3 | 0.58 | 0.57 | 0.59 | yes |
| 1 | BB_108_8_10 | card-mto | 3 | 1.32 | 1.31 | 1.33 | yes |
| 1 | BB_108_8_10 | no-card | 3 | 1.13 | 1.12 | 1.15 | yes |
| 1 | BB_90_8_10 | card-mto | 3 | 0.67 | 0.64 | 0.71 | yes |
| 1 | BB_90_8_10 | no-card | 3 | 0.62 | 0.61 | 0.66 | yes |
| 1 | GB_144_12_8 | card-mto | 3 | 0.57 | 0.52 | 0.57 | yes |
| 1 | GB_144_12_8 | no-card | 3 | 0.52 | 0.51 | 0.52 | yes |
| 1 | LP_238_44_6 | card-mto | 3 | 1.24 | 1.21 | 1.25 | yes |
| 1 | LP_238_44_6 | no-card | 3 | 1.39 | 1.38 | 1.41 | yes |
| 2 | LP_340_56_8 | card-mto | 3 | 3.5 | 3.49 | 3.5 | yes |
| 2 | LP_340_56_8 | no-card | 3 | 3.08 | 3.08 | 3.13 | yes |
| 3 | BB_144_12_12 | card-mto | 3 | 2.71 | 2.66 | 2.72 | yes |
| 3 | BB_144_12_12 | no-card | 3 | 1.47 | 1.46 | 1.51 | yes |
| 3 | BB_144_14_14 | card-mto | 3 | 101.71 | 101.51 | 101.96 | yes |
| 3 | BB_144_14_14 | no-card | 3 | 101.96 | 101.89 | 104.49 | yes |
| 3 | GB_144_12_12 | card-mto | 3 | 56.77 | 56.73 | 57.37 | yes |
| 3 | GB_144_12_12 | no-card | 3 | 124.49 | 124.26 | 124.56 | yes |
| 3 | LP_442_68_10 | card-mto | 3 | 40.7 | 40.68 | 40.74 | yes |
| 3 | LP_442_68_10 | no-card | 3 | 35.74 | 35.64 | 35.78 | yes |
| 3 | LP_544_80_12 | card-mto | 3 | 318.59 | 318.33 | 322.01 | yes |
| 3 | LP_544_80_12 | no-card | 3 | 500.55 | 499.77 | 501.1 | yes |
| 3 | TN_144_2_13 | card-mto | 3 | 328.15 | 327.56 | 328.89 | yes |
| 3 | TN_144_2_13 | no-card | 3 | 341.27 | 340.47 | 341.42 | yes |
| 4 | BB_288_12_18 | card-mto | 3 | 1673.99 | 1643.1 | 1674.42 | yes |
| 4 | BB_288_12_18 | no-card | 3 | 1420.67 | 1415.91 | 1425.86 | yes |
| 4 | LP_714_100_16 | card-mto | 3 | 2000.04 | 2000.03 | 2000.04 | TIMEOUT (lb 9, ub 16) |
| 4 | LP_714_100_16 | no-card | 3 | 2000.04 | 2000.03 | 2000.04 | TIMEOUT (lb 9, ub 16) |
| 4 | TN_250_10_15 | card-mto | 3 | 2000.04 | 2000.03 | 2000.04 | TIMEOUT (lb 9, ub 15) |
| 4 | TN_250_10_15 | no-card | 3 | 1805.77 | 1804.21 | 1809.48 | yes |

Notes:
- The server's cores are ~2-3x slower than the Mac's (e.g. BB_288_12_18 no-card 1421 s vs 618 s on the Mac).
- With the Tier 4 limit of 2000 s, main times out on TN_250_10_15 card-mto and LP_714_100_16 (both modes) on this host;
  a server-specific Tier 4 limit is a PI decision.
- Tier 5 on the server is recorded by the Tier 5 run (main + candidate, 100 processes at once, 6 h).
