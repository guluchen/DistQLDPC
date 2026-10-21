# Recorded main baseline times (PI 2026-10-11: record main's times instead of re-running main every time)

Host: Mac (Apple M6, 12 CPUs), macOS. Baseline binary: main cbb0642 (GH-130 adopted: -frontier=auto default), sha256 `aab6704cf7279b960620a2d5f7daa8ba83d08038457bc4ae035d8eea71ed9d3c`. Collected 2026-10-19.

Method: runner/mac_jobs.py + runner/mac_serial.py: 3 serial runs per case/mode under caffeinate -i -s, 2 GB cap, >=2 cores free; default flags (frontier auto); limits tier0 600 s, tier1-3 1800 s, tier4 2000 s. Column "vs 398054e" = this median / the main 398054e median (2026-10-14 table, git history).

| Tier | Case | Mode | Runs | Median s | Min s | Max s | 398054e median s | vs 398054e |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 0 | BB_72_12_6 | card-mto | 3 | 0.0174 | 0.0173 | 0.0179 | 0.0177 | 0.983 |
| 0 | BB_72_12_6 | no-card | 3 | 0.019 | 0.0187 | 0.0203 | 0.0178 | 1.067 |
| 0 | BB_90_8_10 | card-mto | 3 | 0.0323 | 0.0314 | 0.0457 | 0.0628 | 0.514 |
| 0 | BB_90_8_10 | no-card | 3 | 0.033 | 0.0311 | 0.0331 | 0.0906 | 0.364 |
| 0 | GB_144_12_8 | card-mto | 3 | 0.0473 | 0.0464 | 0.0475 | 0.0479 | 0.988 |
| 0 | GB_144_12_8 | no-card | 3 | 0.0454 | 0.0439 | 0.0479 | 0.0626 | 0.725 |
| 0 | LP_136_32_4 | card-mto | 3 | 0.0475 | 0.0473 | 0.0605 | 0.0477 | 0.996 |
| 0 | LP_136_32_4 | no-card | 3 | 0.0629 | 0.0629 | 0.0631 | 0.0601 | 1.047 |
| 0 | LP_34_20_2 | card-mto | 3 | 0.0172 | 0.0172 | 0.0176 | 0.0178 | 0.966 |
| 0 | LP_34_20_2 | no-card | 3 | 0.0179 | 0.0157 | 0.0181 | 0.0176 | 1.017 |
| 0 | TN_36_8_3 | card-mto | 3 | 0.0174 | 0.0172 | 0.0175 | 0.018 | 0.967 |
| 0 | TN_36_8_3 | no-card | 3 | 0.0175 | 0.0175 | 0.018 | 0.0179 | 0.978 |
| 0 | TN_36_8_4 | card-mto | 3 | 0.0173 | 0.0171 | 0.0174 | 0.0178 | 0.972 |
| 0 | TN_36_8_4 | no-card | 3 | 0.0176 | 0.0175 | 0.0177 | 0.0177 | 0.994 |
| 0 | TN_54_11_4 | card-mto | 3 | 0.017 | 0.0169 | 0.0173 | 0.0174 | 0.977 |
| 0 | TN_54_11_4 | no-card | 3 | 0.0174 | 0.0154 | 0.0177 | 0.0175 | 0.994 |
| 0 | TN_72_14_4 | card-mto | 3 | 0.0322 | 0.0302 | 0.0324 | 0.0325 | 0.991 |
| 0 | TN_72_14_4 | no-card | 3 | 0.0178 | 0.0175 | 0.0292 | 0.0179 | 0.994 |
| 0 | TN_72_8_8 | card-mto | 3 | 0.3365 | 0.3275 | 0.3373 | 0.3186 | 1.056 |
| 0 | TN_72_8_8 | no-card | 3 | 0.2078 | 0.2049 | 0.2086 | 0.1981 | 1.049 |
| 0 | BB_108_8_10 | card-mto | 3 | 0.1075 | 0.1041 | 0.1076 | 0.3877 | 0.277 |
| 0 | BB_108_8_10 | no-card | 3 | 0.1074 | 0.1054 | 0.1086 | 0.2847 | 0.377 |
| 0 | BB_144_12_12 | card-mto | 3 | 0.1081 | 0.1077 | 0.1204 | 0.5496 | 0.197 |
| 0 | BB_144_12_12 | no-card | 3 | 0.107 | 0.1068 | 0.1081 | 0.2516 | 0.425 |
| 0 | LP_238_44_6 | card-mto | 3 | 0.3307 | 0.3265 | 0.338 | 0.3761 | 0.879 |
| 0 | LP_238_44_6 | no-card | 3 | 0.2956 | 0.2858 | 0.304 | 0.3949 | 0.749 |
| 1 | LP_340_56_8 | card-mto | 3 | 1.1929 | 1.1723 | 1.1935 | 1.563 | 0.763 |
| 1 | LP_340_56_8 | no-card | 3 | 0.7703 | 0.7648 | 0.7786 | 1.4836 | 0.519 |
| 2 | BB_144_14_14 | card-mto | 3 | 7.124 | 7.091 | 7.1427 | 28.1921 | 0.253 |
| 2 | BB_144_14_14 | no-card | 3 | 6.9609 | 6.8992 | 6.9813 | 30.2756 | 0.23 |
| 2 | LP_442_68_10 | card-mto | 3 | 9.3396 | 9.2931 | 9.3826 | 20.5178 | 0.455 |
| 2 | LP_442_68_10 | no-card | 3 | 11.1619 | 11.0686 | 11.1634 | 32.1846 | 0.347 |
| 2 | TN_108_2_12 | card-mto | 3 | 11.1002 | 11.0725 | 11.1023 | 11.0157 | 1.008 |
| 2 | TN_108_2_12 | no-card | 3 | 9.6786 | 9.6545 | 9.7044 | 9.5874 | 1.01 |
| 3 | BB_288_12_18 | card-mto | 3 | 79.2298 | 79.2037 | 79.3079 | 377.6117 | 0.21 |
| 3 | BB_288_12_18 | no-card | 3 | 100.7872 | 100.7062 | 100.8397 | 303.8057 | 0.332 |
| 2 | GB_144_12_12 | card-mto | 3 | 9.7464 | 9.7372 | 9.7527 | 100.6553 | 0.097 |
| 2 | GB_144_12_12 | no-card | 3 | 24.3163 | 24.2837 | 24.3464 | 60.1825 | 0.404 |
| 2 | LP_544_80_12 | card-mto | 3 | 19.0907 | 19.0856 | 19.1222 | 50.755 | 0.376 |
| 2 | LP_544_80_12 | no-card | 3 | 19.16 | 19.1574 | 19.17 | 219.4915 | 0.087 |
| 3 | TN_144_2_13 | card-mto | 3 | 159.1957 | 159.047 | 159.3078 | 158.7232 | 1.003 |
| 3 | TN_144_2_13 | no-card | 3 | 71.0081 | 70.8932 | 71.0483 | 70.6652 | 1.005 |
| 2 | TN_200_10_10 | card-mto | 3 | 10.6025 | 10.5989 | 10.6063 | 10.5733 | 1.003 |
| 2 | TN_200_10_10 | no-card | 3 | 13.6784 | 13.6657 | 13.6838 | 13.6329 | 1.003 |
| 4 | TN_250_10_15 | card-mto | 3 | 987.2325 | 985.6268 | 990.3781 | 985.0892 | 1.002 |
| 4 | TN_250_10_15 | no-card | 3 | 1086.9182 | 1085.9132 | 1089.1859 | 1082.4894 | 1.004 |

Notes:
- Replaces the main 398054e table (2026-10-14) after GH-130 (PR #131, `-frontier=auto` default) was merged; old table is in git history.
- vs main 398054e, geomean of per-cell median ratios: tier0 no-card 0.887 tier0 card-mto 0.926 tier1 no-card 0.500 tier1 card-mto 0.437 tier2 no-card 0.432 tier2 card-mto 0.488 tier3 no-card 0.411 tier3 card-mto 0.378 tier4 no-card 1.004 tier4 card-mto 1.002.
- Cells faster than 0.90x: BB_90_8_10 card-mto 0.51, BB_90_8_10 no-card 0.36, GB_144_12_8 no-card 0.73, BB_108_8_10 card-mto 0.28, BB_108_8_10 no-card 0.38, BB_144_12_12 card-mto 0.20, BB_144_12_12 no-card 0.43, LP_238_44_6 card-mto 0.88, LP_238_44_6 no-card 0.75, LP_340_56_8 card-mto 0.76, LP_340_56_8 no-card 0.52, BB_144_14_14 card-mto 0.25, BB_144_14_14 no-card 0.23, LP_442_68_10 card-mto 0.46, LP_442_68_10 no-card 0.35, BB_288_12_18 card-mto 0.21, BB_288_12_18 no-card 0.33, GB_144_12_12 card-mto 0.10, GB_144_12_12 no-card 0.40, LP_544_80_12 card-mto 0.38, LP_544_80_12 no-card 0.09. Cells slower than 1.10x: none. `-frontier=auto` turns frontier branching on for every BB/GB/LP half of tiers 1-4 and off for every TN half (TN cells run the 398054e search unchanged; their ratios are host noise).
- Correctness: 138 runs, every answer equals the stem distance; no run problems.
- Quiet-host batch (raw/main-cbb0642/mac_results.tsv, 2026-10-19 05:57-08:08): a load sampler (raw/main-cbb0642/mac_load_samples.txt, every 20 s) saw no other solver process on the host during the whole batch; max/min over the 3 runs of a cell is <= 1.8% (tiers 2-4 <= 1.2%). TN cells run the 398054e search unchanged and reproduce its times (TN_250_10_15 1.00/1.00, TN_144_2_13 1.00/1.00), so the ratios of BB/GB/LP cells are the solver change alone. An earlier batch taken 2026-10-18 (raw/main-cbb0642/mac_batch1_results.tsv, git history e37bd78) is kept for reference only: from 18:16 another session ran two solver processes on this host and its runs 1-2 came out 9-18% slower than its quiet run 0.
- Every cached comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a full AB/BA/AB comparison for that cell.
- Tier 5 is not in this table: it needs the dedicated server (see SERVER.md).
- **Refresh rule (PI 2026-10-13):** whenever a PR that can change solver behaviour or speed is merged into main, re-record main's tier0-5 times as the new basis (this Mac table: tiers 0-4; SERVER.md: tiers 0-5) and re-check tier placement.
