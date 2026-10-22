# Recorded main baseline times (PI 2026-10-11: record main's times instead of re-running main every time)

Host: Mac (Apple M6, 12 CPUs), macOS. Baseline binary: main c914ef5 (PR #137: -oddcap-skip=on default; PR #136 re-tier), sha256 `ffc82da9560288d7df2c5ff0501fb6f813c0239d7bc5b6885fb4f1382670e2e7`. Collected 2026-10-22.

Method: runner/mac_jobs.py + runner/mac_serial.py: 3 serial runs per case/mode under caffeinate -i -s, 2 GB cap, >=2 cores free, quiet-host gate before every run (runner/mac_gated.py); default flags (frontier auto, oddcap-skip on); limits tier0 600 s, tier1-3 1800 s, tier4 2000 s. Column "vs cbb0642" = this median / the main cbb0642 median (2026-10-19 table, git history; tier column = current tiers).

| Tier | Case | Mode | Runs | Median s | Min s | Max s | cbb0642 median s | vs cbb0642 |
|---:|---|---|---:|---:|---:|---:|---:|---:|
| 0 | BB_108_8_10 | card-mto | 3 | 0.033 | 0.033 | 0.0354 | 0.1075 | 0.307 |
| 0 | BB_108_8_10 | no-card | 3 | 0.0344 | 0.034 | 0.035 | 0.1074 | 0.32 |
| 0 | BB_144_12_12 | card-mto | 3 | 0.108 | 0.1073 | 0.1123 | 0.1081 | 0.999 |
| 0 | BB_144_12_12 | no-card | 3 | 0.1125 | 0.1094 | 0.1136 | 0.107 | 1.051 |
| 0 | BB_72_12_6 | card-mto | 3 | 0.0177 | 0.0134 | 0.0179 | 0.0174 | 1.017 |
| 0 | BB_72_12_6 | no-card | 3 | 0.0221 | 0.0197 | 0.0222 | 0.019 | 1.163 |
| 0 | BB_90_8_10 | card-mto | 3 | 0.0179 | 0.0179 | 0.018 | 0.0323 | 0.554 |
| 0 | BB_90_8_10 | no-card | 3 | 0.022 | 0.0219 | 0.0227 | 0.033 | 0.667 |
| 0 | GB_144_12_8 | card-mto | 3 | 0.048 | 0.0433 | 0.0502 | 0.0473 | 1.015 |
| 0 | GB_144_12_8 | no-card | 3 | 0.0505 | 0.0503 | 0.0506 | 0.0454 | 1.112 |
| 0 | LP_136_32_4 | card-mto | 3 | 0.033 | 0.0326 | 0.0331 | 0.0475 | 0.695 |
| 0 | LP_136_32_4 | no-card | 3 | 0.0337 | 0.0313 | 0.0369 | 0.0629 | 0.536 |
| 0 | LP_238_44_6 | card-mto | 3 | 0.1381 | 0.1345 | 0.1381 | 0.3307 | 0.418 |
| 0 | LP_238_44_6 | no-card | 3 | 0.1355 | 0.1354 | 0.1415 | 0.2956 | 0.458 |
| 0 | LP_34_20_2 | card-mto | 3 | 0.0196 | 0.018 | 0.0201 | 0.0172 | 1.139 |
| 0 | LP_34_20_2 | no-card | 3 | 0.0203 | 0.0202 | 0.0205 | 0.0179 | 1.134 |
| 0 | TN_36_8_3 | card-mto | 3 | 0.0182 | 0.0177 | 0.0183 | 0.0174 | 1.046 |
| 0 | TN_36_8_3 | no-card | 3 | 0.0206 | 0.0181 | 0.0216 | 0.0175 | 1.177 |
| 0 | TN_36_8_4 | card-mto | 3 | 0.0177 | 0.0153 | 0.0181 | 0.0173 | 1.023 |
| 0 | TN_36_8_4 | no-card | 3 | 0.0218 | 0.0194 | 0.0222 | 0.0176 | 1.239 |
| 0 | TN_54_11_4 | card-mto | 3 | 0.0178 | 0.0161 | 0.0179 | 0.017 | 1.047 |
| 0 | TN_54_11_4 | no-card | 3 | 0.0217 | 0.0205 | 0.0219 | 0.0174 | 1.247 |
| 0 | TN_72_14_4 | card-mto | 3 | 0.0328 | 0.0178 | 0.0335 | 0.0322 | 1.019 |
| 0 | TN_72_14_4 | no-card | 3 | 0.0204 | 0.0185 | 0.0221 | 0.0178 | 1.146 |
| 0 | TN_72_8_8 | card-mto | 3 | 0.3224 | 0.3198 | 0.3263 | 0.3365 | 0.958 |
| 0 | TN_72_8_8 | no-card | 3 | 0.21 | 0.2022 | 0.2146 | 0.2078 | 1.011 |
| 1 | LP_340_56_8 | card-mto | 3 | 0.7564 | 0.7507 | 0.7628 | 1.1929 | 0.634 |
| 1 | LP_340_56_8 | no-card | 3 | 0.6207 | 0.6123 | 0.6251 | 0.7703 | 0.806 |
| 2 | BB_144_14_14 | card-mto | 3 | 6.9595 | 6.9301 | 6.9708 | 7.124 | 0.977 |
| 2 | BB_144_14_14 | no-card | 3 | 6.7264 | 6.689 | 6.7575 | 6.9609 | 0.966 |
| 2 | GB_144_12_12 | card-mto | 3 | 9.5881 | 9.5752 | 9.7889 | 9.7464 | 0.984 |
| 2 | GB_144_12_12 | no-card | 3 | 23.9764 | 23.7719 | 24.1074 | 24.3163 | 0.986 |
| 2 | LP_442_68_10 | card-mto | 3 | 2.7333 | 2.7221 | 2.7683 | 9.3396 | 0.293 |
| 2 | LP_442_68_10 | no-card | 3 | 2.7334 | 2.7278 | 2.7588 | 11.1619 | 0.245 |
| 2 | LP_544_80_12 | card-mto | 3 | 18.0815 | 17.989 | 18.0949 | 19.0907 | 0.947 |
| 2 | LP_544_80_12 | no-card | 3 | 18.301 | 18.1748 | 18.5062 | 19.16 | 0.955 |
| 2 | TN_108_2_12 | card-mto | 3 | 10.9869 | 10.8367 | 10.9898 | 11.1002 | 0.99 |
| 2 | TN_108_2_12 | no-card | 3 | 9.5927 | 9.5574 | 9.6099 | 9.6786 | 0.991 |
| 2 | TN_200_10_10 | card-mto | 3 | 10.4687 | 10.4179 | 10.4857 | 10.6025 | 0.987 |
| 2 | TN_200_10_10 | no-card | 3 | 13.5218 | 13.4083 | 13.5393 | 13.6784 | 0.989 |
| 3 | BB_288_12_18 | card-mto | 3 | 20.9681 | 20.9052 | 20.9941 | 79.2298 | 0.265 |
| 3 | BB_288_12_18 | no-card | 3 | 20.237 | 20.17 | 20.2584 | 100.7872 | 0.201 |
| 3 | TN_144_2_13 | card-mto | 3 | 158.8647 | 158.0501 | 159.3354 | 159.1957 | 0.998 |
| 3 | TN_144_2_13 | no-card | 3 | 70.6932 | 70.4584 | 70.7347 | 71.0081 | 0.996 |
| 4 | LP_714_100_16 | card-mto | 3 | 179.3682 | 178.4919 | 181.9375 | - | - |
| 4 | LP_714_100_16 | no-card | 3 | 210.5637 | 209.7181 | 210.6637 | - | - |
| 4 | TN_250_10_15 | card-mto | 3 | 982.8257 | 982.2675 | 985.4011 | 987.2325 | 0.996 |
| 4 | TN_250_10_15 | no-card | 3 | 1087.2025 | 1083.4516 | 1088.0505 | 1086.9182 | 1 |

Notes:
- Replaces the main cbb0642 table (2026-10-19) after PR #137 (`-oddcap-skip=on` default) was merged; old table is in git history. PR #136 re-tiered the codes (tier column = current tiers; the cbb0642 Mac table had no LP_714_100_16 row, it was tier 5 then).
- vs main cbb0642, geomean of per-cell median ratios (current tiers): tier0 no-card 0.873 tier0 card-mto 0.809 tier1 no-card 0.806 tier1 card-mto 0.634 tier2 no-card 0.776 tier2 card-mto 0.799 tier3 no-card 0.447 tier3 card-mto 0.514 tier4 no-card 1.000 tier4 card-mto 0.996.
- Cells faster than 0.90x: BB_108_8_10 card-mto 0.31, BB_108_8_10 no-card 0.32, BB_90_8_10 card-mto 0.55, BB_90_8_10 no-card 0.67, LP_136_32_4 card-mto 0.69, LP_136_32_4 no-card 0.54, LP_238_44_6 card-mto 0.42, LP_238_44_6 no-card 0.46, LP_340_56_8 card-mto 0.63, LP_340_56_8 no-card 0.81, LP_442_68_10 card-mto 0.29, LP_442_68_10 no-card 0.24, BB_288_12_18 card-mto 0.26, BB_288_12_18 no-card 0.20. Cells slower than 1.10x: BB_72_12_6 no-card 1.16, GB_144_12_8 no-card 1.11, LP_34_20_2 card-mto 1.14, LP_34_20_2 no-card 1.13, TN_36_8_3 no-card 1.18, TN_36_8_4 no-card 1.24, TN_54_11_4 no-card 1.25, TN_72_14_4 no-card 1.15. `-oddcap-skip=on` changes the bound search only on halves whose parity matrix has only odd column weights (all bundled BB and LP codes); TN and GB cells run the cbb0642 search unchanged, so their ratios are host noise.
- Correctness: 144 runs, every answer equals the stem distance; no run problems.
- The tier 4 geomeans cover TN_250_10_15 only (unchanged TN search): LP_714_100_16 has no cbb0642 Mac row; on the Mac it now takes 179 s (card-mto) / 211 s (no-card), on yfclab2 626 / 584 s (5-seed medians, SERVER.md) vs one cbb0642 default-seed run of 2663 / 2670 s.
- Collection 2026-10-21 20:41 to 2026-10-22 11:07: runner/mac_gated.py waited before every run until no foreign process used > 50% CPU (two checks 10 s apart) and logged foreign load every 20 s (raw/main-c914ef5/mac_load_samples.txt; run windows in mac_joblog.txt). Another session's 2-process Mac batch (GH-138 S0) held the gate closed from 21:22 to 06:33. Twelve runs overlapped foreign load (another session's solver processes, a short MaxSAT identity check by another agent at ~07:50 reported by the coordinator, or macOS background services) and were re-run on the quiet host (raw/main-c914ef5/mac_rerun_results.tsv); three of those re-runs overlapped single 20-s samples of macOS services and were run a third time; the table uses the last run of each. The re-runs changed TN_144_2_13 card-mto r0 173.4 -> 158.1 s and LP_714_100_16 no-card r0 226.5 -> 209.7 s (both had overlapped another session's solvers); every other tier 2-4 re-run agreed with its first run within 2.1%. The first batch is kept in raw/main-c914ef5/mac_batch1_results.tsv.
- Run spread (max/min over the 3 runs of a cell): tiers 1-4 <= 2.2%; tier 0 cells are all < 0.4 s and their spread (up to 88% on a 0.02 s cell) is process start-up noise. TN and GB cells (search unchanged) reproduce the cbb0642 table at 0.96-1.01x in tiers 0 (> 0.1 s) to 4.
- The answers of every run (first batch and both re-run rounds, 144 + 12 + 3 logs) equal the stem distance and no lb/ub crosses it.
- Every cached comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a full AB/BA/AB comparison for that cell.
- Tier 5 is not in this table: it needs the dedicated server (see SERVER.md).
- **Refresh rule (PI 2026-10-13):** whenever a PR that can change solver behaviour or speed is merged into main, re-record main's tier0-5 times as the new basis (this Mac table: tiers 0-4; SERVER.md: tiers 0-5) and re-check tier placement.
