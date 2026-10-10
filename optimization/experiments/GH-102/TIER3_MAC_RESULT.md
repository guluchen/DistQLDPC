# GH-102 Mac Tier3-equivalent (dual-map cases) — FAIL (one non-overlapping regression; non-dual cells inherit GH-89's)
Mac, per-case timing lock, 2 GB cap, main 7eadd54 (frozen-main7e) vs frozen102/cand, 3+3, limit 1800 s; all runs correct, no timeouts.
| Case | no-card base -> cand (s) | ratio | card-mto base -> cand (s) | ratio |
|---|---|---:|---|---:|
| BB_144_12_12 | 0.5 -> 0.2 | 0.449 | 1.1 -> 0.2 | 0.213 |
| GB_144_12_12 | 66.4 -> 25.6 | 0.387 | 107.3 -> 143.9 | **1.341 (non-overlapping regression)** |
| BB_144_14_14 | 49.6 -> 40.1 | 0.810 | 52.3 -> 32.1 | 0.613 |
Non-dual Tier3 cells run GH-89's search; GH-89's Mac Tier3 (interim) has non-overlapping regressions on TN_144_2_13 no-card
(3.23x) and LP_442_68_10 card-mto (1.76x). Verdict: Tier3 FAIL under the GH-85 rule. GB_144_12_12 card-mto is notable:
GH-89 alone was 0.45 there, so bound sharing changed that trajectory for the worse (shared LB alters which probes run).
Strong cells (GB no-card 2.6x, BB_144_12_12 2-5x, BB_144_14_14 1.2-1.6x) motivate keeping the idea once the incremental
regressions are fixed (issue #106).
