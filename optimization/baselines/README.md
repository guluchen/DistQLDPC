# Recorded main baseline times (PI 2026-10-11: record main's times instead of re-running main every time)

Host: Mac (Apple M6, 12 CPUs), macOS. Baseline binary: main 12b3e05 (PR #147: -ub-pre=on default on the split MaxSAT path, -ub-search=on default in the optional CC engine; LP_442_68_10 -> tier1, BB_288_12_18 -> tier2, LP_714_100_16 -> tier3), sha256 `03032d9a55ca4f13f88fbc9c1ef98909199e63697f2cd29cf52e41315f3f1997`. Collected 2026-10-23.

Method: runner/mac_jobs.py + runner/mac_serial.py: 3 serial runs per case/mode under caffeinate -i -s, 2 GB cap, >=2 cores free, quiet-host gate before every run (runner/mac_gated.py); default flags (frontier auto, oddcap-skip on, ub-pre on); limits tier0 600 s, tier1-3 1800 s, tier4 2000 s. Column "vs c914ef5" = this median / the main c914ef5 median (2026-10-22 table, git history; tier column = current tiers). Column "First ub" = the first `c d_ub` of each run (with the default `-ub-pre` it is the verified pre-pass word).

| Tier | Case | Mode | Runs | Median s | Min s | Max s | First ub | c914ef5 median s | vs c914ef5 |
|---:|---|---|---:|---:|---:|---:|---|---:|---:|
| 0 | BB_108_8_10 | card-mto | 3 | 0.0179 | 0.0178 | 0.0181 | 10 | 0.033 | 0.542 |
| 0 | BB_108_8_10 | no-card | 3 | 0.0185 | 0.0184 | 0.0202 | 10 | 0.0344 | 0.538 |
| 0 | BB_144_12_12 | card-mto | 3 | 0.063 | 0.0626 | 0.0631 | 12 | 0.108 | 0.583 |
| 0 | BB_144_12_12 | no-card | 3 | 0.0622 | 0.0607 | 0.0638 | 12 | 0.1125 | 0.553 |
| 0 | BB_72_12_6 | card-mto | 3 | 0.0181 | 0.0178 | 0.0184 | 6 | 0.0177 | 1.023 |
| 0 | BB_72_12_6 | no-card | 3 | 0.0205 | 0.0201 | 0.0205 | 6 | 0.0221 | 0.928 |
| 0 | BB_90_8_10 | card-mto | 3 | 0.0177 | 0.0164 | 0.0181 | 10 | 0.0179 | 0.989 |
| 0 | BB_90_8_10 | no-card | 3 | 0.0194 | 0.015 | 0.0202 | 10 | 0.022 | 0.882 |
| 0 | GB_144_12_8 | card-mto | 3 | 0.0328 | 0.0281 | 0.0331 | 8 | 0.048 | 0.683 |
| 0 | GB_144_12_8 | no-card | 3 | 0.0206 | 0.0206 | 0.0214 | 8 | 0.0505 | 0.408 |
| 0 | LP_136_32_4 | card-mto | 3 | 0.0179 | 0.0177 | 0.0204 | 4 | 0.033 | 0.542 |
| 0 | LP_136_32_4 | no-card | 3 | 0.0218 | 0.0159 | 0.0219 | 4 | 0.0337 | 0.647 |
| 0 | LP_238_44_6 | card-mto | 3 | 0.108 | 0.1033 | 0.109 | 6 | 0.1381 | 0.782 |
| 0 | LP_238_44_6 | no-card | 3 | 0.094 | 0.0924 | 0.094 | 6 | 0.1355 | 0.694 |
| 0 | LP_34_20_2 | card-mto | 3 | 0.0176 | 0.0163 | 0.02 | 2 | 0.0196 | 0.898 |
| 0 | LP_34_20_2 | no-card | 3 | 0.0202 | 0.0198 | 0.0206 | 2 | 0.0203 | 0.995 |
| 0 | TN_36_8_3 | card-mto | 3 | 0.0169 | 0.013 | 0.0178 | 3 | 0.0182 | 0.929 |
| 0 | TN_36_8_3 | no-card | 3 | 0.0201 | 0.02 | 0.0204 | 3 | 0.0206 | 0.976 |
| 0 | TN_36_8_4 | card-mto | 3 | 0.0179 | 0.0176 | 0.018 | 4 | 0.0177 | 1.011 |
| 0 | TN_36_8_4 | no-card | 3 | 0.02 | 0.0186 | 0.0204 | 4 | 0.0218 | 0.917 |
| 0 | TN_54_11_4 | card-mto | 3 | 0.0179 | 0.0178 | 0.0184 | 4 | 0.0178 | 1.006 |
| 0 | TN_54_11_4 | no-card | 3 | 0.0202 | 0.0183 | 0.0202 | 4 | 0.0217 | 0.931 |
| 0 | TN_72_14_4 | card-mto | 3 | 0.0179 | 0.0177 | 0.0207 | 4 | 0.0328 | 0.546 |
| 0 | TN_72_14_4 | no-card | 3 | 0.0207 | 0.0183 | 0.021 | 4 | 0.0204 | 1.015 |
| 0 | TN_72_8_8 | card-mto | 3 | 0.3003 | 0.2941 | 0.3019 | 8 | 0.3224 | 0.931 |
| 0 | TN_72_8_8 | no-card | 3 | 0.2111 | 0.1986 | 0.2119 | 8 | 0.21 | 1.005 |
| 1 | LP_340_56_8 | card-mto | 3 | 0.7308 | 0.7221 | 0.733 | 8 | 0.7564 | 0.966 |
| 1 | LP_340_56_8 | no-card | 3 | 0.5778 | 0.5676 | 0.5802 | 8 | 0.6207 | 0.931 |
| 1 | LP_442_68_10 | card-mto | 3 | 1.812 | 1.8057 | 1.8158 | 10 | 2.7333 | 0.663 |
| 1 | LP_442_68_10 | no-card | 3 | 1.2145 | 1.2116 | 1.2209 | 10 | 2.7334 | 0.444 |
| 2 | BB_144_14_14 | card-mto | 3 | 5.6636 | 5.637 | 5.706 | 14 | 6.9595 | 0.814 |
| 2 | BB_144_14_14 | no-card | 3 | 5.5352 | 5.5019 | 5.5934 | 14 | 6.7264 | 0.823 |
| 2 | BB_288_12_18 | card-mto | 3 | 20.6485 | 20.6341 | 20.9167 | 18 | 20.9681 | 0.985 |
| 2 | BB_288_12_18 | no-card | 3 | 19.9497 | 19.8073 | 20.4485 | 18 | 20.237 | 0.986 |
| 2 | GB_144_12_12 | card-mto | 3 | 0.4425 | 0.4398 | 0.4457 | 12 | 9.5881 | 0.046 |
| 2 | GB_144_12_12 | no-card | 3 | 0.446 | 0.4457 | 0.4504 | 12 | 23.9764 | 0.019 |
| 2 | LP_544_80_12 | card-mto | 3 | 7.0894 | 6.9779 | 7.1004 | 12 | 18.0815 | 0.392 |
| 2 | LP_544_80_12 | no-card | 3 | 7.1291 | 7.0348 | 7.1877 | 12 | 18.301 | 0.39 |
| 2 | TN_108_2_12 | card-mto | 3 | 8.3615 | 8.2538 | 8.3947 | 12 | 10.9869 | 0.761 |
| 2 | TN_108_2_12 | no-card | 3 | 9.417 | 9.3085 | 9.4672 | 12 | 9.5927 | 0.982 |
| 2 | TN_200_10_10 | card-mto | 3 | 5.4729 | 5.4116 | 5.4738 | 10 | 10.4687 | 0.523 |
| 2 | TN_200_10_10 | no-card | 3 | 5.2026 | 5.1581 | 5.2303 | 10 | 13.5218 | 0.385 |
| 3 | LP_714_100_16 | card-mto | 3 | 178.0497 | 177.9677 | 178.4903 | 16 | 179.3682 | 0.993 |
| 3 | LP_714_100_16 | no-card | 3 | 209.4385 | 209.3761 | 210.4016 | 16 | 210.5637 | 0.995 |
| 3 | TN_144_2_13 | card-mto | 3 | 31.9608 | 31.9023 | 31.981 | 13 | 158.8647 | 0.201 |
| 3 | TN_144_2_13 | no-card | 3 | 31.593 | 31.5481 | 31.7215 | 13 | 70.6932 | 0.447 |
| 4 | TN_250_10_15 | card-mto | 3 | 634.483 | 634.0706 | 635.3365 | 15 | 982.8257 | 0.646 |
| 4 | TN_250_10_15 | no-card | 3 | 603.4646 | 603.0481 | 604.0122 | 15 | 1087.2025 | 0.555 |

Notes:
- Replaces the main c914ef5 table (2026-10-22) after PR #147 (`-ub-pre=on` default on the split MaxSAT path; `-ub-search=on` default inside the optional CC engine, which the default `-engine=maxsat` runs here do not use) was merged; old table is in git history. PR #147 also re-tiered LP_442_68_10 -> tier1, BB_288_12_18 -> tier2, LP_714_100_16 -> tier3 (tier column = current tiers; comparisons by stem).
- vs main c914ef5, geomean of per-cell median ratios (current tiers): tier0 no-card 0.777 tier0 card-mto 0.781 tier1 no-card 0.643 tier1 card-mto 0.800 tier2 no-card 0.361 tier2 card-mto 0.424 tier3 no-card 0.667 tier3 card-mto 0.447 tier4 no-card 0.555 tier4 card-mto 0.646.
- Cells faster than 0.90x: BB_108_8_10 card-mto 0.54, BB_108_8_10 no-card 0.54, BB_144_12_12 card-mto 0.58, BB_144_12_12 no-card 0.55, BB_90_8_10 no-card 0.88, GB_144_12_8 card-mto 0.68, GB_144_12_8 no-card 0.41, LP_136_32_4 card-mto 0.54, LP_136_32_4 no-card 0.65, LP_238_44_6 card-mto 0.78, LP_238_44_6 no-card 0.69, LP_34_20_2 card-mto 0.90, TN_72_14_4 card-mto 0.55, LP_442_68_10 card-mto 0.66, LP_442_68_10 no-card 0.44, BB_144_14_14 card-mto 0.81, BB_144_14_14 no-card 0.82, GB_144_12_12 card-mto 0.05, GB_144_12_12 no-card 0.02, LP_544_80_12 card-mto 0.39, LP_544_80_12 no-card 0.39, TN_108_2_12 card-mto 0.76, TN_200_10_10 card-mto 0.52, TN_200_10_10 no-card 0.38, TN_144_2_13 card-mto 0.20, TN_144_2_13 no-card 0.45, TN_250_10_15 card-mto 0.65, TN_250_10_15 no-card 0.56. Cells slower than 1.10x: none. `-ub-pre=on` runs a verified randomized low-weight-logical pre-pass (at most 60 s, a half stops earlier after 16 re-hits or a plateau) on every split MaxSAT run, so every cell (all families, both modes) runs a changed search; on small codes the pre-pass cost is part of the start-up time.
- Correctness: 144 runs, every answer equals the stem distance, no lb/ub crosses it, and the first `c d_ub` of every run (the `-ub-pre` word) is a valid upper bound (>= stem d); no run problems.
- Collection 2026-10-23 03:43 to 06:27 (+0800), frozen binary frozen-main-12b3e05/distqldpc (make clean && make CXX="c++ -Wno-reserved-user-defined-literal"). runner/mac_gated.py logged foreign load every 20 s (raw/main-12b3e05/mac_load_samples.txt; run windows in mac_joblog.txt). Eleven runs overlapped foreign samples (macOS services, other apps' renderers) or the window 04:12-04:22 in which the coordinator reported another agent's in-browser WASM tests (~20 s at 100% of one core; it overlapped TN_250_10_15 card-mto r0 and BB_108_8_10 no-card r1); all eleven were re-run on the quiet host (no foreign sample during the re-run round; raw/main-12b3e05/mac_rerun_results.tsv) and the table uses the re-runs. Re-run / first-run ratios: 0.997-1.004 for every run > 1 s, so the overlaps had no measurable effect. First batch: raw/main-12b3e05/mac_batch1_results.tsv. No sleep entries in pmset -g log during the collection.
- Run spread (max/min over the 3 runs of a cell): tiers 1-4 <= 3.3%; tier 0 cells (< 0.31 s) are start-up dominated.
- **Basis (PI 2026-10-23):** no baseline will be recorded for main e52d15b (PR #149: finder default -ub-isd=stern, tier 5 stems renamed to {lb}to{ub}); these main 12b3e05 tables remain the official comparison basis. Tier 5 upper bounds after e52d15b are in optimization/experiments/GH-146/REPORT.md.
- Every cached comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a full AB/BA/AB comparison for that cell.
- Tier 5 is not in this table: it needs the dedicated server (see SERVER.md).
- **Refresh rule (PI 2026-10-13):** whenever a PR that can change solver behaviour or speed is merged into main, re-record main's tier0-5 times as the new basis (this Mac table: tiers 0-4; SERVER.md: tiers 0-5) and re-check tier placement.
