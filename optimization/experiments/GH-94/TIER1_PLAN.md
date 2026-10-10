# GH-94 Tier1/Tier2 plan (coordinator, preregistered before any timing)
Mac, timing lock, tier1_mac_dist.py. Candidate frozen94/cand (4a15a105…).
- Gate (decides Tier1): current main 7eadd54 (GH-73 + GH-85 default since PR #90), Mac build `frozen-main7e/distqldpc` (6bdcaa25…),
  4 Tier1 cases x no-card/card-mto, 3+3 AB/BA/AB + 10 replication pairs, GH16 judge.
- Attribution (PROPOSAL primary/secondary, informational): vs GH-89 `frozen89/cand` (fb6846d0…) and vs GH-92 `frozen92/cand` (49e37dee…), 3+3.
- Tier2 only if the gate is positive in both modes: LP_340_56_8, 600/615 s, vs main 7eadd54 and vs GH-89.
