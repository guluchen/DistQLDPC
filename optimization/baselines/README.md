# Recorded main baseline times (PI 2026-10-11: record main's times instead of re-running main every time)

Host: Mac (Apple M6, 12 CPUs), macOS. Baseline binary: main cbb0642 (GH-130 adopted: -frontier=auto default), sha256 `aab6704cf7279b960620a2d5f7daa8ba83d08038457bc4ae035d8eea71ed9d3c`. Collected 2026-10-18.

Method: runner/mac_jobs.py + runner/mac_serial.py: 3 serial runs per case/mode under caffeinate -i -s, 2 GB cap, >=2 cores free; default flags (frontier auto); limits tier0 600 s, tier1-3 1800 s, tier4 2000 s. Column "vs 398054e" = this median / the main 398054e median (2026-10-14 table, git history).

| Tier | Case | Mode | Runs | Median s | Min s | Max s | 398054e median s | vs 398054e |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 0 | BB_72_12_6 | card-mto | 3 | 0.0174 | 0.0172 | 0.0175 | 0.0177 | 0.983 |
| 0 | BB_72_12_6 | no-card | 3 | 0.0183 | 0.0182 | 0.0183 | 0.0178 | 1.028 |
| 0 | BB_90_8_10 | card-mto | 3 | 0.0329 | 0.0325 | 0.0472 | 0.0628 | 0.524 |
| 0 | BB_90_8_10 | no-card | 3 | 0.0322 | 0.0311 | 0.0327 | 0.0906 | 0.355 |
| 0 | GB_144_12_8 | card-mto | 3 | 0.0473 | 0.0425 | 0.0478 | 0.0479 | 0.988 |
| 0 | GB_144_12_8 | no-card | 3 | 0.0476 | 0.0472 | 0.0479 | 0.0626 | 0.76 |
| 0 | LP_136_32_4 | card-mto | 3 | 0.0588 | 0.0471 | 0.0623 | 0.0477 | 1.233 |
| 0 | LP_136_32_4 | no-card | 3 | 0.0606 | 0.058 | 0.0625 | 0.0601 | 1.008 |
| 0 | LP_34_20_2 | card-mto | 3 | 0.0173 | 0.0153 | 0.0176 | 0.0178 | 0.972 |
| 0 | LP_34_20_2 | no-card | 3 | 0.0173 | 0.0149 | 0.0173 | 0.0176 | 0.983 |
| 0 | TN_36_8_3 | card-mto | 3 | 0.0172 | 0.0165 | 0.0175 | 0.018 | 0.956 |
| 0 | TN_36_8_3 | no-card | 3 | 0.0172 | 0.0159 | 0.0175 | 0.0179 | 0.961 |
| 0 | TN_36_8_4 | card-mto | 3 | 0.0172 | 0.0149 | 0.0172 | 0.0178 | 0.966 |
| 0 | TN_36_8_4 | no-card | 3 | 0.0175 | 0.0171 | 0.0175 | 0.0177 | 0.989 |
| 0 | TN_54_11_4 | card-mto | 3 | 0.0172 | 0.0171 | 0.0173 | 0.0174 | 0.989 |
| 0 | TN_54_11_4 | no-card | 3 | 0.0171 | 0.0169 | 0.0172 | 0.0175 | 0.977 |
| 0 | TN_72_14_4 | card-mto | 3 | 0.028 | 0.0171 | 0.0325 | 0.0325 | 0.862 |
| 0 | TN_72_14_4 | no-card | 3 | 0.0172 | 0.0137 | 0.0175 | 0.0179 | 0.961 |
| 0 | TN_72_8_8 | card-mto | 3 | 0.3626 | 0.3303 | 0.372 | 0.3186 | 1.138 |
| 0 | TN_72_8_8 | no-card | 3 | 0.2267 | 0.2051 | 0.2306 | 0.1981 | 1.144 |
| 1 | BB_108_8_10 | card-mto | 3 | 0.1153 | 0.1083 | 0.1166 | 0.3877 | 0.297 |
| 1 | BB_108_8_10 | no-card | 3 | 0.1059 | 0.1033 | 0.1078 | 0.2847 | 0.372 |
| 1 | BB_144_12_12 | card-mto | 3 | 0.1223 | 0.104 | 0.1228 | 0.5496 | 0.223 |
| 1 | BB_144_12_12 | no-card | 3 | 0.1204 | 0.1033 | 0.1206 | 0.2516 | 0.478 |
| 1 | LP_238_44_6 | card-mto | 3 | 0.3572 | 0.3254 | 0.3647 | 0.3761 | 0.95 |
| 1 | LP_238_44_6 | no-card | 3 | 0.3186 | 0.2806 | 0.3205 | 0.3949 | 0.807 |
| 1 | LP_340_56_8 | card-mto | 3 | 1.307 | 1.1523 | 1.3138 | 1.563 | 0.836 |
| 1 | LP_340_56_8 | no-card | 3 | 0.8418 | 0.7395 | 0.8465 | 1.4836 | 0.567 |
| 2 | BB_144_14_14 | card-mto | 3 | 7.7811 | 6.9869 | 7.7815 | 28.1921 | 0.276 |
| 2 | BB_144_14_14 | no-card | 3 | 7.587 | 6.9316 | 7.5911 | 30.2756 | 0.251 |
| 2 | LP_442_68_10 | card-mto | 3 | 10.2322 | 9.2042 | 10.8662 | 20.5178 | 0.499 |
| 2 | LP_442_68_10 | no-card | 3 | 12.2385 | 10.936 | 12.2436 | 32.1846 | 0.38 |
| 2 | TN_108_2_12 | card-mto | 3 | 12.0807 | 11.0335 | 12.1142 | 11.0157 | 1.097 |
| 2 | TN_108_2_12 | no-card | 3 | 10.4967 | 9.5662 | 11.3212 | 9.5874 | 1.095 |
| 3 | BB_288_12_18 | card-mto | 3 | 86.2447 | 79.1008 | 86.4923 | 377.6117 | 0.228 |
| 3 | BB_288_12_18 | no-card | 3 | 109.7895 | 100.3734 | 109.919 | 303.8057 | 0.361 |
| 3 | GB_144_12_12 | card-mto | 3 | 10.6213 | 9.746 | 10.6731 | 100.6553 | 0.105 |
| 3 | GB_144_12_12 | no-card | 3 | 26.5492 | 24.3053 | 26.5966 | 60.1825 | 0.441 |
| 3 | LP_544_80_12 | card-mto | 3 | 20.9242 | 19.0632 | 20.9573 | 50.755 | 0.412 |
| 3 | LP_544_80_12 | no-card | 3 | 20.9727 | 19.1284 | 21.0304 | 219.4915 | 0.096 |
| 3 | TN_144_2_13 | card-mto | 3 | 173.6899 | 159.1655 | 173.7628 | 158.7232 | 1.094 |
| 3 | TN_144_2_13 | no-card | 3 | 77.3737 | 70.9009 | 77.6241 | 70.6652 | 1.095 |
| 3 | TN_200_10_10 | card-mto | 3 | 11.5173 | 10.5876 | 11.5333 | 10.5733 | 1.089 |
| 3 | TN_200_10_10 | no-card | 3 | 14.8481 | 13.6674 | 14.8887 | 13.6329 | 1.089 |
| 4 | TN_250_10_15 | card-mto | 3 | 1071.8057 | 1037.6823 | 1071.9626 | 985.0892 | 1.088 |
| 4 | TN_250_10_15 | no-card | 3 | 1180.8066 | 1086.3538 | 1184.2243 | 1082.4894 | 1.091 |

Notes:
- Replaces the main 398054e table (2026-10-14) after GH-130 (PR #131, `-frontier=auto` default) was merged; old table is in git history.
- vs main 398054e, geomean of per-cell median ratios: tier0 no-card 0.881 tier0 card-mto 0.941 tier1 no-card 0.534 tier1 card-mto 0.479 tier2 no-card 0.471 tier2 card-mto 0.532 tier3 no-card 0.449 tier3 card-mto 0.412 tier4 no-card 1.091 tier4 card-mto 1.088.
- Cells faster than 0.90x: BB_90_8_10 card-mto 0.52, BB_90_8_10 no-card 0.36, GB_144_12_8 no-card 0.76, TN_72_14_4 card-mto 0.86, BB_108_8_10 card-mto 0.30, BB_108_8_10 no-card 0.37, BB_144_12_12 card-mto 0.22, BB_144_12_12 no-card 0.48, LP_238_44_6 no-card 0.81, LP_340_56_8 card-mto 0.84, LP_340_56_8 no-card 0.57, BB_144_14_14 card-mto 0.28, BB_144_14_14 no-card 0.25, LP_442_68_10 card-mto 0.50, LP_442_68_10 no-card 0.38, BB_288_12_18 card-mto 0.23, BB_288_12_18 no-card 0.36, GB_144_12_12 card-mto 0.11, GB_144_12_12 no-card 0.44, LP_544_80_12 card-mto 0.41, LP_544_80_12 no-card 0.10. Cells slower than 1.10x: LP_136_32_4 card-mto 1.23, TN_72_8_8 card-mto 1.14, TN_72_8_8 no-card 1.14. `-frontier=auto` turns frontier branching on for every BB/GB/LP half of tiers 1-4 and off for every TN half (TN cells run the 398054e search unchanged; their ratios are host noise).
- Correctness: 138 runs, every answer equals the stem distance; no run problems.
- INTERIM (batch 1, raw/main-cbb0642/mac_batch1_results.tsv): run 0 of every cell was taken on a quiet Mac (17:41-18:16), but from 18:16 another session ran two concurrent solver processes on this host, so runs 1-2 of every cell (and run 0 of TN_250_10_15 card-mto in part) are 9-18% slower than run 0 (TN cells run the 398054e search unchanged and show the same inflation). The table is to be replaced by a full quiet re-run (batch 2) before use as a +-3% drift basis; the tier 1-3 ratios vs 398054e are unaffected in direction (0.2-0.75x on BB/GB/LP cells).
- Every cached comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a full AB/BA/AB comparison for that cell.
- Tier 5 is not in this table: it needs the dedicated server (see SERVER.md).
- **Refresh rule (PI 2026-10-13):** whenever a PR that can change solver behaviour or speed is merged into main, re-record main's tier0-5 times as the new basis (this Mac table: tiers 0-4; SERVER.md: tiers 0-5) and re-check tier placement.
