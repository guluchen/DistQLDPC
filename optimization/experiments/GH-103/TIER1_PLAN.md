# GH-103 timing plan (coordinator, preregistered)
Search identical to GH-95/main (Tier0 200/200). Mac, timing lock, tier1_mac_dist.py + memlimit (2 GB).
Base frozen95/cand (GH-95, de88d7ff…; timing-neutral vs main), candidate frozen103/cand (4fd05e20…).
Cells: GB_144_12_12 no-card/card-mto and LP_544_80_12 card-mto (limit 900/915), LP_340_56_8 no-card/card-mto (600/615), 3+3 AB/BA/AB;
plus Tier1 4 cases 3+3 + 10 replication pairs.
Decision: positive if the large cells' median ratios are < 1 with non-overlapping ranges in the expected direction and no
non-overlapping regression anywhere beyond the GH-67 noise floor.
