# GH-34 exploratory LP_340 Tier2 result — direction consistent, effect small

Preregistered in TIER2_EXPLORATORY.md (standing user instruction to advance one tier
when evidence does not justify rejection). Same host, frozen binaries (hashes
re-verified after), inputs re-verified, 1-min load 1.41–2.82 before each solve.
Raw: `raw/tier2-exploratory-01/`. Single attempt.

Science: 12/12 solves rc 0, `o 8`, identical emitted progress/bound lines; no timeouts.

| Mode | Baseline s (AB/BA/AB order) | Candidate s | Median ratio | Envelope max(c)/min(b) | Ranges |
|---|---|---|---:|---:|---|
| no-card | 86.228, 86.400, 86.449 | 85.922, 85.963, 86.309 | 0.9949 | 1.0009 | overlap slightly |
| card-mto | 59.919, 60.019, 60.004 | 59.843, 59.818, 59.853 | 0.9973 | 0.9989 | all candidate < all baseline |

Interpretation fixed in advance: candidate median lower in both modes and no
non-overlapping regression => **exploratory direction consistent** with Tier1.
The effect on LP_340 (-0.51% OFF, -0.27% MTO) is about half the Tier1 size even
though lookahead propagation is ~70% of LP_340 profile samples. So the per-check
saving is real but small, and part of the Tier1 ~1% may come from other factors
(e.g. code layout). This is not a PASS and does not authorise Tier3 or merge.
