# GH-99 Tier1/Tier2 plan (coordinator, preregistered before timing)
S0-exact (build default) is search-identical to main 7eadd54 (Tier0: 200/200 trace checks), so timing measures only the engine
cost/saving of skipping base-satisfied lookahead watchers. Mac, timing lock, tier1_mac_dist.py,
base frozen-main7e (6bdcaa25…) vs frozen99/exact (2ed8f23c…).
- Tier1: 4 cases x no-card/card-mto, 3+3 AB/BA/AB + 10 replication pairs, GH16 judge.
- Medium case (main now solves Tier1 in < 0.5 s): GB_144_12_12 no-card/card-mto, 3+3, limit 600/615 s.
- Tier2: LP_340_56_8, 3+3, 600/615 s.
Decision: positive if GB_144_12_12 and Tier1 replication geomeans are < 1 in both modes with no non-overlapping
regression anywhere; S0-fast is timed only if exact shows a gain. Tier3 on yfclab2 only once the server is healthy again.
