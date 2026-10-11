# Recorded main baseline times (PI 2026-10-11: record main's times instead of re-running main every time)

Host: Mac (Apple M6, 12 CPUs), macOS. Baseline binary: frozen-main7e/distqldpc (main 7eadd54; d52c1a6 has the same solver, path resolver only), sha256 `6bdcaa2523cdcbeae5164cedbf54c9ac0f9e64f9a91c3da7ef4b804df393db9d`. Collected 2026-10-11.

Method: every completed baseline-role run of this exact binary in serial, timing-locked Mac experiments (one solve at a time, 2 GB cap in later runs).

| Tier | Case | Mode | Runs | Median s | Min s | Max s |
|---:|---|---|---:|---:|---:|---:|
| 1 | BB_108_8_10 | card-mto | 123 | 0.4631 | 0.445 | 0.4905 |
| 1 | BB_108_8_10 | no-card | 123 | 0.3615 | 0.3459 | 0.3821 |
| 1 | BB_90_8_10 | card-mto | 123 | 0.1371 | 0.1327 | 0.1483 |
| 1 | BB_90_8_10 | no-card | 123 | 0.1487 | 0.1373 | 0.1557 |
| 1 | GB_144_12_8 | card-mto | 123 | 0.0775 | 0.0736 | 0.0896 |
| 1 | GB_144_12_8 | no-card | 123 | 0.0924 | 0.0868 | 0.0933 |
| 1 | LP_238_44_6 | card-mto | 123 | 0.3908 | 0.3812 | 0.4029 |
| 1 | LP_238_44_6 | no-card | 123 | 0.4037 | 0.3921 | 0.4163 |
| 2 | LP_340_56_8 | card-mto | 33 | 1.618 | 1.5897 | 1.6471 |
| 2 | LP_340_56_8 | no-card | 33 | 1.5312 | 1.5067 | 1.5724 |
| 3 | BB_144_12_12 | card-mto | 18 | 1.1456 | 1.1332 | 1.1623 |
| 3 | BB_144_12_12 | no-card | 18 | 0.5088 | 0.5011 | 0.5183 |
| 3 | BB_144_14_14 | card-mto | 21 | 51.7116 | 51.5874 | 56.5674 |
| 3 | BB_144_14_14 | no-card | 21 | 49.0029 | 48.8988 | 53.4698 |
| 3 | GB_144_12_12 | card-mto | 24 | 106.4605 | 106.2974 | 116.1613 |
| 3 | GB_144_12_12 | no-card | 24 | 66.2305 | 65.9917 | 72.6734 |
| 3 | LP_442_68_10 | card-mto | 9 | 20.6901 | 20.6265 | 21.2572 |
| 3 | LP_442_68_10 | no-card | 9 | 32.637 | 32.5148 | 32.8602 |
| 3 | LP_544_80_12 | card-mto | 12 | 50.9969 | 50.8745 | 55.7626 |
| 3 | LP_544_80_12 | no-card | 9 | 220.5567 | 219.9041 | 241.7144 |
| 3 | TN_144_2_13 | card-mto | 9 | 160.7049 | 160.5322 | 160.8308 |
| 3 | TN_144_2_13 | no-card | 12 | 71.6527 | 71.4534 | 73.427 |

Notes:
- Session-to-session drift reaches ~10% on some cells (e.g. GB_144_12_12 no-card median 66.2 s, one batch at 72.6 s), so every cached
  comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a
  full AB/BA/AB comparison for that cell.
- Tier 4 and Tier 5 baselines are not in this table yet: the existing main runs on those cases were parallel probes (6-8 runs at once),
  not serial timing runs. Serial Tier 4 baseline runs are scheduled; Tier 5 needs the dedicated server (26 codes x 2 modes x up to 6 h).
- Rebuild this table whenever main's solver or the host changes. Server (yfclab2) times are a separate table.
