# GH-89 Tier1/Tier2 plan (coordinator, preregistered before any timing)
Mac, timing lock, harness tier1_mac_dist.py (GH-60 runner with bound-soundness checks, copied from GH-87).
- Gate (decides Tier1): frozen 72d1fe1 base `frozen73n/base` (3f2fbc42…) vs `frozen89/cand` (fb6846d0…),
  BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6 x no-card/card-mto, 3+3 AB/BA/AB + replication.
  GH16 judge: per mode all medians non-worse and envelope geomean < 1 => positive; non-overlapping regression flagged.
- Attribution (informational, does not gate): `frozen85/cand` (GH-85, 1c6f028a…) as "base" vs GH-89 cand, same cases.
  Question: does the incremental half solver add speed on top of per-half symmetry breaking?
- Tier2 if gate positive: LP_340_56_8, 600/615 s, vs 72d1fe1 base, plus the same attribution vs GH-85.
