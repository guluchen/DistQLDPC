# GH-95 Tier1 neutrality result — NEUTRAL (preregistered rule met)
Mac, timing lock, frozen-main7e (6bdcaa25…) vs frozen95/cand (de88d7ff…), all samples correct, no flags.
| Cell | gate ratio (3+3) | replication ratio (10+10) |
|---|---:|---:|
| BB_90_8_10 OFF / MTO | 1.0073 / 1.0000 | 0.9786 / 1.0037 |
| GB_144_12_8 OFF / MTO | 1.0000 / 1.0000 | 1.0000 / 1.0130 |
| BB_108_8_10 OFF / MTO | 0.9694 / 0.9658 | 1.0245 / 0.9989 |
| LP_238_44_6 OFF / MTO | 1.0227 / 1.0052 | 1.0000 / 0.9974 |
Gate geomean OFF 0.9989, MTO 0.9933; replication geomean OFF 1.0007, MTO 1.0008 (inside [0.99, 1.01]).
Every cell's candidate and baseline ranges overlap; cells beyond ±1% flip sign between gate and replication
(e.g. BB_108 OFF 0.969 -> 1.025), i.e. noise at 0.03–0.47 s run times with 1 ms timer resolution.
LP_340_56_8 (3+3): OFF 1.0020, MTO 1.0019 (1.510 vs 1.513 s; 1.594 vs 1.597 s).
Conclusion: the restructure is performance-neutral within the layout-noise floor, as expected from identical per-function code.
