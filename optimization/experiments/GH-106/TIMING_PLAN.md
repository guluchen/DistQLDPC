# GH-106 timing plan (coordinator, preregistered; Mac Tier3-equivalent approved by the PI as a special case)
Mac, per-step timing lock, tier1_mac_dist.py + memlimit (2 GB). Base main 7eadd54 (frozen-main7e 6bdcaa25…).
Candidates: P1 = frozen106/cand (820145fb…, default -inc-policy=postsol); P2 = frozen106/feasfresh (wrapper script that execs
the same binary with -inc-policy=feasfresh; one extra exec per run, negligible on the Tier3 cases, visible on Tier1).
For each of P1, P2: Tier3-equivalent 6 cases (TN_144_2_13, LP_442_68_10, LP_544_80_12, BB_144_14_14, BB_144_12_12, GB_144_12_12)
x no-card/card-mto, 3+3, limit 1800/1815; then Tier1 3+3 and LP_340_56_8 3+3.
PASS rule (Tier3, GH-85): every cell median <= main with no non-overlapping regression, per-mode geomean < 1, all correct.
