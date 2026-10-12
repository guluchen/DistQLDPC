# GH-106 v2 (-inc-policy=budgettot, K=3) — Mac timing + answers vs recorded main (coordinator, 2026-10-12)
Runner tier_cached_mac.py (3 candidate runs + 1 main drift sample per cell, stem-based answer checks on every run), 2 GB cap,
frozen106/v2 (b3f4e3e4…) vs recorded frozen-main7e baseline (optimization/baselines/main_mac_reference.json). Raw: raw/timing-v2/.
All answers consistent with the stems in every tier; no drift outside the recorded range (except two sub-0.1 s tier0 cells).
| Tier | no-card geomean | card-mto geomean | Verdict |
|---|---:|---:|---|
| tier0 (10 small codes) | 0.939 | 0.914 | PASS (PI rule: correctness / severe slowdown only; worst TN_108_2_12 no-card 1.37x at ~15 s) |
| tier1-3 (11 cases) | 0.657 | 0.636 | PASS — no cell slower than main (BB_108 0.30/0.40, LP_442 no-card 0.31, GB_144_12_12 0.43/0.45, TN_144 0.89/0.53) |
| tier4 (3 cases, 2000 s) | 1.024 | 0.961 | **FAIL** — LP_714_100_16 1.166 / 1.164 and BB_288_12_18 no-card 1.028 are non-overlapping regressions |
tier4 cells: TN_250_10_15 0.895 / 0.794; BB_288_12_18 1.028 / 0.962; LP_714_100_16 1.166 / 1.164 (1409 -> 1644 s).
Reading: the budgeted incremental policy removes GH-89's Tier 3 regressions and is strongly positive on tiers 1-3, but on the
largest solved LP code the persistent solver still costs ~16%. Tier 5 (yfclab2, 100 processes, 6 h) is running and will show
whether the pattern holds on the open set. Not adoptable as is; next: inspect LP_714's per-probe trace (which probes the
budget did not catch) or restrict persistence to codes below a size threshold.
