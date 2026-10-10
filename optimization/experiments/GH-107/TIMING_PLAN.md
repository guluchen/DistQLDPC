# GH-107 timing plan (coordinator, preregistered; PI approved Mac Tier3 as a special case, 2026-10-10)
Mac, timing lock, tier1_mac_dist.py + memlimit (2 GB). Base main 7eadd54 (frozen-main7e 6bdcaa25…), candidate frozen107/cand (68338e32…, -dualmode=share default).
1. Tier1: 4 cases x no-card/card-mto, 3+3 + 10 replication pairs; attribution vs GH-92 (frozen92) 3+3.
2. Tier2: LP_340_56_8 (no dual map: expected identical to main apart from one report line).
3. Tier3-equivalent on the dual-map cases BB_144_12_12, GB_144_12_12, BB_144_14_14, 3+3, limit 1800/1815, per-case lock.
   Non-dual Tier3 codes run main's search (off-path identical; LP default == main except one line in Tier0).
PASS (Tier3, GH-85 rule): no science problem; every cell median <= main with no non-overlapping regression; per-mode geomean < 1.
