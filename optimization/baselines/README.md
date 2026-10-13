# Recorded main baseline times (PI 2026-10-11: record main's times instead of re-running main every time)

Host: Mac (Apple M6, 12 CPUs), macOS. Baseline binary: main 398054e (GH-107 adopted), sha256 `2c9e33b443f724ed6fc7902eda8cc41a4687c9c66c52d2a7d66f890d1df584d3`. Collected 2026-10-14.

Method: record_main_mac.py: 3 serial runs per case/mode under caffeinate -i -s, 2 GB cap, >=2 cores free; limits tier0 600 s, tier1-3 1800 s, tier4 2000 s.

| Tier | Case | Mode | Runs | Median s | Min s | Max s |
|---:|---|---|---:|---:|---:|---:|
| 0 | BB_72_12_6 | card-mto | 3 | 0.0177 | 0.0175 | 0.018 |
| 0 | BB_72_12_6 | no-card | 3 | 0.0178 | 0.0175 | 0.0183 |
| 0 | BB_90_8_10 | card-mto | 3 | 0.0628 | 0.0626 | 0.074 |
| 0 | BB_90_8_10 | no-card | 3 | 0.0906 | 0.0906 | 0.0927 |
| 0 | GB_144_12_8 | card-mto | 3 | 0.0479 | 0.0469 | 0.0485 |
| 0 | GB_144_12_8 | no-card | 3 | 0.0626 | 0.0601 | 0.0629 |
| 0 | LP_136_32_4 | card-mto | 3 | 0.0477 | 0.0475 | 0.0478 |
| 0 | LP_136_32_4 | no-card | 3 | 0.0601 | 0.0586 | 0.0633 |
| 0 | LP_34_20_2 | card-mto | 3 | 0.0178 | 0.0178 | 0.0178 |
| 0 | LP_34_20_2 | no-card | 3 | 0.0176 | 0.0174 | 0.0178 |
| 0 | TN_36_8_3 | card-mto | 3 | 0.018 | 0.0179 | 0.018 |
| 0 | TN_36_8_3 | no-card | 3 | 0.0179 | 0.0177 | 0.0182 |
| 0 | TN_36_8_4 | card-mto | 3 | 0.0178 | 0.0175 | 0.0179 |
| 0 | TN_36_8_4 | no-card | 3 | 0.0177 | 0.0176 | 0.0179 |
| 0 | TN_54_11_4 | card-mto | 3 | 0.0174 | 0.0174 | 0.0176 |
| 0 | TN_54_11_4 | no-card | 3 | 0.0175 | 0.0175 | 0.0181 |
| 0 | TN_72_14_4 | card-mto | 3 | 0.0325 | 0.0325 | 0.0326 |
| 0 | TN_72_14_4 | no-card | 3 | 0.0179 | 0.0177 | 0.0182 |
| 0 | TN_72_8_8 | card-mto | 3 | 0.3186 | 0.317 | 0.3187 |
| 0 | TN_72_8_8 | no-card | 3 | 0.1981 | 0.198 | 0.2054 |
| 1 | BB_108_8_10 | card-mto | 3 | 0.3877 | 0.375 | 0.3883 |
| 1 | BB_108_8_10 | no-card | 3 | 0.2847 | 0.2847 | 0.2849 |
| 1 | BB_144_12_12 | card-mto | 3 | 0.5496 | 0.5429 | 0.5517 |
| 1 | BB_144_12_12 | no-card | 3 | 0.2516 | 0.2464 | 0.253 |
| 1 | LP_238_44_6 | card-mto | 3 | 0.3761 | 0.3751 | 0.3856 |
| 1 | LP_238_44_6 | no-card | 3 | 0.3949 | 0.3919 | 0.4007 |
| 1 | LP_340_56_8 | card-mto | 3 | 1.563 | 1.5622 | 1.5699 |
| 1 | LP_340_56_8 | no-card | 3 | 1.4836 | 1.4804 | 1.4844 |
| 2 | LP_442_68_10 | card-mto | 3 | 20.5178 | 20.4937 | 20.5289 |
| 2 | LP_442_68_10 | no-card | 3 | 32.1846 | 31.7241 | 32.2025 |
| 2 | TN_108_2_12 | card-mto | 3 | 11.0157 | 11.0108 | 11.0182 |
| 2 | TN_108_2_12 | no-card | 3 | 9.5874 | 9.5842 | 9.5922 |
| 3 | BB_144_14_14 | card-mto | 3 | 28.1921 | 28.1299 | 28.1952 |
| 3 | BB_144_14_14 | no-card | 3 | 30.2756 | 30.2543 | 30.2842 |
| 3 | GB_144_12_12 | card-mto | 3 | 100.6553 | 100.6262 | 100.6571 |
| 3 | GB_144_12_12 | no-card | 3 | 60.1825 | 60.1636 | 60.2222 |
| 3 | LP_544_80_12 | card-mto | 3 | 50.755 | 50.7045 | 50.7573 |
| 3 | LP_544_80_12 | no-card | 3 | 219.4915 | 219.4605 | 219.736 |
| 3 | TN_144_2_13 | card-mto | 3 | 158.7232 | 158.5818 | 159.021 |
| 3 | TN_144_2_13 | no-card | 3 | 70.6652 | 70.6536 | 70.716 |
| 3 | TN_200_10_10 | card-mto | 3 | 10.5733 | 10.5621 | 10.5758 |
| 3 | TN_200_10_10 | no-card | 3 | 13.6329 | 13.6163 | 13.6457 |
| 4 | BB_288_12_18 | card-mto | 3 | 377.6117 | 377.5122 | 377.6555 |
| 4 | BB_288_12_18 | no-card | 3 | 303.8057 | 303.6885 | 303.9141 |
| 4 | TN_250_10_15 | card-mto | 3 | 985.0892 | 984.2891 | 985.7636 |
| 4 | TN_250_10_15 | no-card | 3 | 1082.4894 | 1082.3075 | 1082.7601 |

Notes:
- Replaces the main 7eadd54 table (2026-10-11) after GH-107 (PR #120) was merged; old table is in git history.
- vs main 7eadd54 (median ratios): codes with a verified XZ-dual map are faster (BB_144_12_12 0.48/0.49, BB_144_14_14 0.55/0.62, BB_288_12_18 0.53/0.49, BB_90_8_10 0.46/0.61, GB_144_12_8 0.62/0.68, GB_144_12_12 0.95/0.91, BB_108_8_10 0.84/0.79); all other cells within +-3%.
- Every cached comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a full AB/BA/AB comparison for that cell.
- Tier 5 is not in this table: it needs the dedicated server (see SERVER.md).
- **Refresh rule (PI 2026-10-13):** whenever a PR that can change solver behaviour or speed is merged into main, re-record main's tier0-5 times as the new basis (this Mac table: tiers 0-4; SERVER.md: tiers 0-5) and re-check tier placement.
