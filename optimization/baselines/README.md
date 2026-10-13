# Recorded main baseline times (PI 2026-10-11: record main's times instead of re-running main every time)

Host: Mac (Apple M6, 12 CPUs), macOS. Baseline binary: frozen-main7e/distqldpc (main 7eadd54; d52c1a6 has the same solver, path resolver only), sha256 `6bdcaa2523cdcbeae5164cedbf54c9ac0f9e64f9a91c3da7ef4b804df393db9d`. Collected 2026-10-11.

Method: every completed baseline-role run of this exact binary in serial, timing-locked Mac experiments (one solve at a time, 2 GB cap in later runs).

| Tier | Case | Mode | Runs | Median s | Min s | Max s |
|---:|---|---|---:|---:|---:|---:|
| 1 | BB_108_8_10 | card-mto | 123 | 0.4631 | 0.445 | 0.4905 |
| 1 | BB_108_8_10 | no-card | 123 | 0.3615 | 0.3459 | 0.3821 |
| 0 | BB_90_8_10 | card-mto | 123 | 0.1371 | 0.1327 | 0.1483 |
| 0 | BB_90_8_10 | no-card | 123 | 0.1487 | 0.1373 | 0.1557 |
| 0 | GB_144_12_8 | card-mto | 123 | 0.0775 | 0.0736 | 0.0896 |
| 0 | GB_144_12_8 | no-card | 123 | 0.0924 | 0.0868 | 0.0933 |
| 1 | LP_238_44_6 | card-mto | 123 | 0.3908 | 0.3812 | 0.4029 |
| 1 | LP_238_44_6 | no-card | 123 | 0.4037 | 0.3921 | 0.4163 |
| 1 | LP_340_56_8 | card-mto | 33 | 1.618 | 1.5897 | 1.6471 |
| 1 | LP_340_56_8 | no-card | 33 | 1.5312 | 1.5067 | 1.5724 |
| 1 | BB_144_12_12 | card-mto | 18 | 1.1456 | 1.1332 | 1.1623 |
| 1 | BB_144_12_12 | no-card | 18 | 0.5088 | 0.5011 | 0.5183 |
| 3 | BB_144_14_14 | card-mto | 21 | 51.7116 | 51.5874 | 56.5674 |
| 3 | BB_144_14_14 | no-card | 21 | 49.0029 | 48.8988 | 53.4698 |
| 3 | GB_144_12_12 | card-mto | 24 | 106.4605 | 106.2974 | 116.1613 |
| 3 | GB_144_12_12 | no-card | 24 | 66.2305 | 65.9917 | 72.6734 |
| 2 | LP_442_68_10 | card-mto | 9 | 20.6901 | 20.6265 | 21.2572 |
| 2 | LP_442_68_10 | no-card | 9 | 32.637 | 32.5148 | 32.8602 |
| 3 | LP_544_80_12 | card-mto | 12 | 50.9969 | 50.8745 | 55.7626 |
| 3 | LP_544_80_12 | no-card | 9 | 220.5567 | 219.9041 | 241.7144 |
| 3 | TN_144_2_13 | card-mto | 9 | 160.7049 | 160.5322 | 160.8308 |
| 3 | TN_144_2_13 | no-card | 12 | 71.6527 | 71.4534 | 73.427 |
| 4 | TN_250_10_15 | no-card | 3 | 1090.786 | 1090.437 | 1090.836 |
| 4 | TN_250_10_15 | card-mto | 3 | 991.028 | 990.953 | 991.276 |
| 4 | BB_288_12_18 | no-card | 3 | 617.692 | 617.464 | 617.738 |
| 4 | BB_288_12_18 | card-mto | 3 | 707.937 | 706.455 | 708.436 |
| 5 | LP_714_100_16 | no-card | 3 | 1409.568 | 1407.366 | 1410.67 |
| 5 | LP_714_100_16 | card-mto | 3 | 1408.853 | 1407.719 | 1409.049 |
| 0 | BB_72_12_6 | no-card | 3 | 0.0177 | 0.0176 | 0.0181 |
| 0 | BB_72_12_6 | card-mto | 3 | 0.0176 | 0.0175 | 0.0177 |
| 0 | LP_34_20_2 | no-card | 3 | 0.0176 | 0.0144 | 0.0176 |
| 0 | LP_34_20_2 | card-mto | 3 | 0.0178 | 0.0175 | 0.0178 |
| 0 | LP_136_32_4 | no-card | 3 | 0.0629 | 0.0627 | 0.0629 |
| 0 | LP_136_32_4 | card-mto | 3 | 0.0476 | 0.0474 | 0.0478 |
| 0 | TN_36_8_3 | no-card | 3 | 0.0176 | 0.0173 | 0.0176 |
| 0 | TN_36_8_3 | card-mto | 3 | 0.0176 | 0.0175 | 0.0176 |
| 0 | TN_36_8_4 | no-card | 3 | 0.0174 | 0.0173 | 0.0175 |
| 0 | TN_36_8_4 | card-mto | 3 | 0.0173 | 0.0172 | 0.0175 |
| 0 | TN_54_11_4 | no-card | 3 | 0.0175 | 0.0173 | 0.0175 |
| 0 | TN_54_11_4 | card-mto | 3 | 0.0175 | 0.0136 | 0.0177 |
| 0 | TN_72_14_4 | no-card | 3 | 0.0176 | 0.0174 | 0.0177 |
| 0 | TN_72_14_4 | card-mto | 3 | 0.0326 | 0.0326 | 0.0327 |
| 0 | TN_72_8_8 | no-card | 3 | 0.2049 | 0.1982 | 0.209 |
| 0 | TN_72_8_8 | card-mto | 3 | 0.3187 | 0.3183 | 0.3276 |
| 2 | TN_108_2_12 | no-card | 3 | 9.3271 | 9.3197 | 9.3564 |
| 2 | TN_108_2_12 | card-mto | 3 | 10.7224 | 10.7083 | 10.7646 |
| 3 | TN_200_10_10 | no-card | 3 | 13.3596 | 13.2865 | 13.3816 |
| 3 | TN_200_10_10 | card-mto | 3 | 10.396 | 10.3658 | 10.4086 |

Notes:
- Session-to-session drift reaches ~10% on some cells (e.g. GB_144_12_12 no-card median 66.2 s, one batch at 72.6 s), so every cached
  comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a
  full AB/BA/AB comparison for that cell.
- Tier 4 rows: 3 serial runs each (2026-10-11/12), limit 2000 s; spread within 0.5%. LP_714_100_16 (~1409 s) was moved to tier5 on 2026-10-12 (server timeout at 5000 s); its rows are kept with tier 5.
- Tier 5 is not in this table: it needs the dedicated server (25 codes x 2 modes x up to 6 h); the Mac probes so far were parallel runs.
- **Refresh rule (PI 2026-10-13):** whenever a PR that can change solver behaviour or speed is merged into main, re-record main's
  tier0-5 times as the new basis (this Mac table: tiers 0-4; SERVER.md: tiers 0-4 and tier5) and re-check tier placement.
- Rebuild this table whenever main's solver or the host changes. Server (yfclab2) times are a separate table.
