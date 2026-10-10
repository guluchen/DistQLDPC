# GH-98 Tier1/Tier2 result (coordinator) — MIXED: preregistered rule FAILS (non-overlapping regressions); NOT ADOPTED as is
Mac, timing lock, frozen-main7e (6bdcaa25…) vs frozen98/cand (2cf4d512…, XOR on), all samples correct (o = d).
Disclosure: one ~1 s memory-cap test run (BB_90 + BB_144_14_14 capped at 40 MB) overlapped this batch during the BB_144_14_14 cell.
| Case | OFF base -> cand (s) | OFF ratio | MTO base -> cand (s) | MTO ratio |
|---|---|---:|---|---:|
| GB_144_12_12 | 66.3 -> 58.4 | **0.881** | 106.5 -> 53.7 | **0.504** |
| TN_144_2_13 (900 s) | 71.8 -> 52.1 | **0.726** | — | — |
| BB_144_14_14 | 49.1 -> 77.4 | **1.578 (regression)** | 51.7 -> 67.9 | **1.311 (regression)** |
| LP_544_80_12 (900 s) | — | — | 51.4 -> 138.1 | **2.689 (regression)** |
| LP_340_56_8 (Tier2) | 1.54 -> 1.48 | 0.960 | 1.65 -> 1.44 | 0.875 |
| Tier1 geomean (3+3 / 10-pair repl) | | 0.960 / 0.955 | | 0.812 / 0.812 |
Tier1 cells: BB_108 0.91/0.57, BB_90 1.00/0.91, GB_144_12_8 1.12 (non-overlapping)/1.00, LP_238 0.82/0.83.
Reading: the XOR propagator changes the propagation order (binary -> XOR -> long) and with it the search trajectory, so
outcomes swing by case: large wins on GB_144_12_12 MTO (2x), TN_144 (1.4x), LP_238/LP340, large losses on LP_544 MTO (2.7x)
and BB_144_14_14 (1.3-1.6x). Work-count evidence (Tier0) showed lookahead progress per second roughly unchanged, so the
swings are trajectory effects, not engine speed. Decision: NOT ADOPTED as is (rule requires no non-overlapping regression).
Follow-ups worth testing: (a) order variant (long clauses before XOR, or XOR clause visits in original watch order) to keep the
trajectory closer to main; (b) combine with a trajectory-independent gain so the speed effect is not masked; (c) Gauss-Jordan
reasoning, which adds inference strength rather than only reordering.
