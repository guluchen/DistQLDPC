# GH-102 Tier3-equivalent on the Mac (preregistered before timing; PI approved Mac Tier3 as a special case, 2026-10-10)
Cases with a verified XZ-dual map (checked with -dualskip-report): BB_144_12_12, GB_144_12_12, BB_144_14_14; modes no-card,
card-mto; AB/BA/AB 3+3; limit 1800 s, watchdog 1815 s; per-case timing lock; tier1_mac_dist.py + memlimit (2 GB cap).
Baseline main 7eadd54 (frozen-main7e); candidate frozen102/cand (e1801a58…).
TN_144_2_13, LP_442_68_10, LP_544_80_12 (and TN_250_10_15) have no dual map: GH-102 runs GH-89's search there, so GH-89's
Mac Tier3 (TIER3_MAC_PLAN.md on experiment/gh-89-mac-symbreak-inc) is the evidence for those cells.
PASS rule as GH-85 TIER3_PLAN; the combined GH-102 Tier3 verdict = these 6 cells + GH-89's non-dual-map cells.
