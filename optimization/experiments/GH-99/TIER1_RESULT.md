# GH-99 Tier1/Tier2 result (coordinator) — REJECT (S0-exact slower; S0-fast not timed per plan)
Mac, timing lock, frozen-main7e (6bdcaa25…) vs frozen99/exact (2ed8f23c…); search identical (Tier0), all samples correct.
| Case | OFF ratio | MTO ratio |
|---|---:|---:|
| BB_90_8_10 | 1.020 (repl 0.990) | 1.000 (repl 1.044) |
| GB_144_12_8 | 0.989 (repl 0.989) | 1.000 (repl 1.007) |
| BB_108_8_10 | **1.048 (repl 1.088), non-overlapping** | **1.096 (repl 1.090), non-overlapping** |
| LP_238_44_6 | **1.035 (repl 1.036), non-overlapping** | **1.036** (repl 1.031) |
| GB_144_12_12 (600 s) | **0.969** (66.1 -> 64.1 s), non-overlapping gain | 1.004 (106.3 -> 106.7 s), non-overlapping |
| LP_340_56_8 (Tier2) | **1.058**, non-overlapping | **1.047**, non-overlapping |
Tier1 replication geomean OFF 1.028, MTO 1.041.
Reading: with identical search, the run/level bookkeeping costs more than the skipped watcher visits save, except where
skips are densest (GB_144_12_12 no-card, visits down to 17%: -3%). Skipped visits are cheap (8-byte watcher stream plus an
L1-resident value lookup); lookahead cost sits in clause inspections (random clause-memory loads), which S0 does not reduce.
Decision: REJECT / NOT ADOPTED. Lesson for the next specialization: target clause inspections. In the main-profile
instrumentation, original XOR clauses (size 3 = xor2, size 4 = SatELite-merged xor3) are 61-77% of inspected clauses
(GB_144: learnt 0.31e9 / orig3 0.19e9 / orig4 0.28e9; LP_544: 0.14e9 / 0.19e9 / 0.29e9) => native XOR constraints (#98).
