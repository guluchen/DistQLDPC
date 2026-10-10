# GH-107 timing result (coordinator) — Tier1 POSITIVE, Tier2 neutral (identical search), Mac Tier3-equivalent PASS
Mac, timing lock, 2 GB cap, main 7eadd54 (frozen-main7e 6bdcaa25…) vs frozen107/cand (68338e32…, -dualmode=share). All runs correct.
## Tier1 vs main (3+3; replication 10 pairs)
| Case | OFF | MTO |
|---|---:|---:|
| BB_90_8_10 | 0.608 | 0.570 |
| GB_144_12_8 | 0.677 | 0.615 |
| BB_108_8_10 | 0.813 | 0.860 |
| LP_238_44_6 (no dual map) | 1.005 | 1.008 |
Geomean 0.763 / 0.742 (replication 0.776 / 0.729); no regression flag.
Attribution vs GH-92 (informational): 1.246 / 1.181 — GH-92 is faster on the small dual-map codes (GB_144_12_8 2.4x/1.8x,
BB_108 ~1%), as predicted: share keeps both halves.
## Tier2 LP_340_56_8 (no dual map): 1.000 / 1.005 (search identical to main).
## Tier3-equivalent (PI-approved Mac special case), 3+3, limit 1800 s
| Case | no-card base -> cand (s) | ratio | card-mto base -> cand (s) | ratio |
|---|---|---:|---|---:|
| BB_144_12_12 | 0.51 -> 0.25 | 0.497 | 1.14 -> 0.57 | 0.500 |
| GB_144_12_12 | 66.21 -> 60.35 | 0.911 | 106.45 -> 100.97 | 0.949 |
| BB_144_14_14 | 48.99 -> 30.39 | 0.620 | 51.62 -> 28.25 | 0.547 |
Non-dual Tier3 codes LP_442_68_10, LP_544_80_12, TN_144_2_13, TN_250_10_15: `-v -cpu-lim=30` traces identical to main (8/8,
raw/nondual-identity, only the dual report line differs) => ratio 1 by construction.
Per-mode geomean over the 7 policy cases (non-dual = 1.0): no-card 0.770, card-mto 0.751. Every cell non-worse, no
non-overlapping regression, no timeouts, all correct => PASS under the GH-85 Tier3 rule (Mac substitute; TN_250 by identity).
Recommendation: candidate for the next default (main + verified dual map + bound sharing), pending the PI's decision.
