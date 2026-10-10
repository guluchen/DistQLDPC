# GH-103 timing result (coordinator) — POSITIVE (small, safe): 1-3% faster, search identical, no regression
Mac, timing lock, 2 GB cap, frozen95/cand (GH-95, timing-neutral vs main) vs frozen103/cand (4fd05e20…), all runs correct.
| Cell | base -> cand (s, median) | ratio | ranges |
|---|---|---:|---|
| LP_544_80_12 card-mto | 51.50 -> 49.80 | 0.967 | non-overlapping gain |
| LP_340_56_8 no-card / card-mto | 1.537 -> 1.509 / 1.639 -> 1.587 | 0.982 / 0.968 | non-overlapping gains |
| GB_144_12_12 no-card / card-mto | 70.79 -> 70.38 / 114.84 -> 113.35 | 0.994 / 0.987 | overlap |
| Tier1 gate geomean | | 0.980 / 0.974 | BB_108 OFF non-overlapping gain |
| Tier1 replication geomean | | 0.990 / 0.955 | overlap |
Worst cell: Tier1 replication BB_90 no-card 1.020 (0.15 s, overlapping). No non-overlapping regression anywhere.
Agrees with the agent's sample-based CPU measurements (-1.7% GB_144 OFF, -3.2% LP_544 MTO).
Decision: POSITIVE — small but search-identical (no trajectory risk). Adoption requires GH-95 (#97) first, since GH-103 is built on it.
