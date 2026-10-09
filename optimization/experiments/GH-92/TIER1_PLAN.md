# GH-92 Tier1/Tier2 plan (coordinator, preregistered before any timing)
Mac, timing lock, tier1_mac_dist.py (GH-60 runner with bound-soundness checks).
- Gate (decides Tier1): 72d1fe1 `frozen73n/base` (3f2fbc42…) vs `frozen92/cand` (49e37dee…), 4 Tier1 cases x no-card/card-mto, 3+3 AB/BA/AB + 10 replication pairs, GH16 judge.
- Primary attribution (preregistered in PROPOSAL): GH-85 `frozen85/cand` (1c6f028a…) vs GH-92, same cases, 3+3.
  Hypothesis: < 1 on BB/GB (dual map), ~1 on LP_238 (no dual map; identical search except one log line).
- Tier2 only if the gate is positive in both modes: LP_340_56_8, 600/615 s, vs 72d1fe1 and vs GH-85.
