# GH-92 Tier3-equivalent on the Mac (preregistered before timing; PI approved Mac Tier3 as a special case, 2026-10-10)
Why now: GH-89's Mac Tier3 (interim) shows non-overlapping regressions vs main from the incremental half solver on codes
without a dual map (TN_144_2_13 no-card 3.23x, LP_442_68_10 card-mto 1.76x, BB_144_14_14 no-card 1.18x); GH-102 inherits
them on non-dual codes. GH-92 = main (GH-73+GH-85) + dual-half elimination, no incremental solver: on codes without a
verified dual map its search is identical to main (Tier0: default == GH-85 traces except one report line), so the only cells
that can change are the dual-map codes.
Cases (verified dual map): BB_144_12_12, GB_144_12_12, BB_144_14_14; modes no-card, card-mto; AB/BA/AB 3+3; limit 1800 s,
watchdog 1815 s; per-case timing lock; tier1_mac_dist.py + memlimit (2 GB). Baseline main 7eadd54 (frozen-main7e 6bdcaa25…),
candidate frozen92/cand (49e37dee…). Non-dual Tier3 codes (LP_442, LP_544, TN_144, TN_250): identical search to main by
construction (to be spot-checked by trace identity, not timed).
PASS rule as GH-85 TIER3_PLAN.
