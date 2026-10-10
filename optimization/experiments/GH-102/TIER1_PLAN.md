# GH-102 Tier1/Tier2 plan (coordinator, preregistered before timing)
Mac, timing lock, tier1_mac_dist.py + memlimit.py (2 GB cap). Candidate frozen102/cand (e1801a58…, variant A default).
- Gate: main 7eadd54 (frozen-main7e 6bdcaa25…) vs GH-102, 4 Tier1 cases x no-card/card-mto, 3+3 + 10 replication pairs.
- Attribution (informational): vs GH-89 (frozen89, primary — does sharing help without the GH-94 BB_108 regression?) and vs GH-94 (frozen94).
- Tier2: LP_340_56_8 vs main (no dual map: expected = GH-89).
Positive if gate positive in both modes; GH-102 is preferred over GH-89 only if vs-GH-89 has no non-overlapping regression.
