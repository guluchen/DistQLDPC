# GH-98 Tier1/Tier2 plan (coordinator, preregistered before timing)
Mac, timing lock, tier1_mac_dist.py; base frozen-main7e (main 7eadd54, 6bdcaa25…) vs frozen98/cand (2cf4d512…, XOR on by default).
Search changes, so medians over AB/BA/AB 3+3 with the GH16 judge.
1. Tier1: 4 cases x no-card/card-mto, 3+3 + 10 replication pairs.
2. Medium/large (limit 600/615 s unless noted): GB_144_12_12 no-card+card-mto; BB_144_14_14 no-card+card-mto;
   TN_144_2_13 no-card (limit 900/915); LP_544_80_12 card-mto (limit 900/915).
3. Tier2: LP_340_56_8 no-card+card-mto.
Decision: positive if the medium/large cells' geomean < 1 per mode with no non-overlapping regression, and Tier1/Tier2 show
no non-overlapping regression beyond the noise floor. Tier3 on yfclab2 once the server is healthy.
