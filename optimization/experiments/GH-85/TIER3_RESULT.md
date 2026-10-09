# GH-85 Tier3 result — PASS (preregistered rule in TIER3_PLAN.md, single attempt)
yfclab2, base 72d1fe1 (b943c2c9…) vs GH-85 (beb1b72d…), 14 case/mode workers pinned on NUMA node 1, AB/BA/AB 3+3,
limit 1800 s (timeouts censored at 1800 s, so ratios with a timed-out baseline are upper bounds on the true ratio).
Binary and input sha256 unchanged after all runs; no resource-guard stop.
| Case | Mode | Baseline s (3) | Candidate s (3) | Median ratio |
|---|---|---|---|---:|
| BB_144_12_12 | no-card | 36.1, 36.2, 36.4 | 1.1, 1.1, 1.1 | 0.0310 |
| BB_144_12_12 | card-mto | 43.2, 43.5, 43.4 | 2.4, 2.3, 2.4 | 0.0542 |
| GB_144_12_12 | no-card | 662.3, 716.8, 671.9 | 124.4, 125.0, 123.3 | 0.1852 |
| GB_144_12_12 | card-mto | 639.3, 641.0, 635.3 | 56.6, 56.5, 56.4 | 0.0884 |
| BB_144_14_14 | no-card | TO x3 (d_lb 8) | 103.5, 103.5, 104.2 | <= 0.0575 |
| BB_144_14_14 | card-mto | TO x3 (d_lb 8) | 100.9, 100.8, 101.7 | <= 0.0560 |
| LP_442_68_10 | no-card | 429.0, 439.8, 483.3 | 33.8, 33.8, 35.3 | 0.0768 |
| LP_442_68_10 | card-mto | 227.2, 220.3, 220.5 | 39.0, 38.9, 39.4 | 0.1769 |
| LP_544_80_12 | no-card | TO x3 (d_lb 8) | 501.1, 497.1, 536.7 | <= 0.2784 |
| LP_544_80_12 | card-mto | TO x3 (d_lb 8) | 318.4, 319.6, 342.6 | <= 0.1775 |
| TN_144_2_13 | no-card | 808.0, 798.8, 794.9 | 348.8, 347.3, 345.6 | 0.4348 |
| TN_144_2_13 | card-mto | 988.1, 1038.0, 1037.2 | 337.8, 337.6, 327.0 | 0.3255 |
| TN_250_10_15 | no-card | TO x3 (d_lb 8, d_ub 15) | TO x3 (d_lb 9, d_ub 15) | 1.0 (censored) |
| TN_250_10_15 | card-mto | TO x3 (d_lb 8) | TO x3 (d_lb 9) | 1.0 (censored) |
Per-mode geomean of median ratios: no-card 0.1631, card-mto 0.1605.
Rule check: (i) science: every completed run has rc 0 and o = named d; every timeout has sound bounds — OK.
(ii) candidate median <= baseline median in all 14, no non-overlapping regression — OK. (iii) no candidate timeout
where the baseline completes — OK. (iv) both geomeans < 1 — OK. => Tier3 PASS.
Contention: before each run global idle >= 0.70 and pinned CPU idle >= 0.82; during runs global idle min 0.666
(median 0.731); SMT sibling busy (< 0.9 idle) in 0.54% of 5 s samples. Other users' load was present but moderate.
TN_250_10_15: neither binary completes in 1800 s; the candidate proves a stronger lower bound (9 vs 8).
Raw: raw/tier3/<case>.<mode>/ (samples.json with 5 s telemetry, result.json, per-run stdout/stderr).
Per the PI decision (2026-10-09) the adoption PR #90 is merged as the default.
