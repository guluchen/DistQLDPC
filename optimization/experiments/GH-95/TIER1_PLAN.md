# GH-95 Tier1 plan (coordinator, preregistered before timing)
Pure restructure: every function's machine code identical to 7eadd54, __text size identical, 96 functions at moved addresses.
Expected effect: layout noise only. Mac, timing lock, tier1_mac_dist.py, base frozen-main7e (6bdcaa25…) vs frozen95/cand (de88d7ff…).
- 4 Tier1 cases x no-card/card-mto, 3+3 AB/BA/AB + 10 replication pairs; plus LP_340_56_8 (600/615 s) 3+3.
Decision rule: NEUTRAL (acceptable as a refactor) if every cell median ratio is within the GH-67 layout-noise floor
(|ratio-1| <= 2.1% for GB_144 OFF, <= 1% elsewhere) or the replication geomean per mode is within [0.99, 1.01];
a non-overlapping regression beyond the floor => investigate before merge. A gain is not claimed (layout only).
