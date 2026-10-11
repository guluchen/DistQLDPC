# GH-106 timing result (coordinator, Mac) — postsol: big gains, ONE real regression (TN_144 no-card 1.74x) => Tier3 FAIL;
# feasfresh: FAIL (TN_144 card-mto 1.35x, small Tier1 regressions)
Mac, per-step timing lock, 2 GB cap, main 7eadd54 (frozen-main7e) vs frozen106 (820145fb…); all runs correct (status o).
## postsol (default)
| Case | no-card | card-mto |
|---|---:|---:|
| BB_144_12_12 | 1.006 | 0.437 |
| GB_144_12_12 | 0.438 | 0.454 |
| BB_144_14_14 | 0.792 | 0.843 |
| LP_442_68_10 | 0.316 | 1.002 (20.66 -> 20.71 s; non-overlapping by 0.2%) |
| LP_544_80_12 | 0.958 | 0.656 |
| TN_144_2_13 | **1.740 (71.6 -> 124.7 s, regression)** | 0.537 |
Tier3 geomean 0.754 / 0.624. Tier1: 0.32-0.84 in all 8 cells (BB_108 0.32/0.39). LP340 0.777 / 0.643.
vs GH-89 the large-code regressions shrink: TN_144 no-card 3.23 -> 1.74, LP_442 MTO 1.76 -> 1.00, LP_544 MTO 1.35 -> 0.66,
BB_144_14_14 no-card 1.18 -> 0.79, BB_144_12_12 no-card 1.11 -> 1.01.
## feasfresh (wrapper, -inc-policy=feasfresh)
Tier3 geomean 0.751 / 0.876, but TN_144_2_13 card-mto 1.345 and BB_144_14_14 no-card 1.033 non-overlapping regressions;
Tier1 ~1.0 (GB_144_12_8 OFF 1.022, BB_90 MTO 1.014 flagged); LP340 1.00.
## Verdict
Neither policy passes the strict Tier3 rule. postsol is the strongest candidate measured so far on aggregate (Tier3 geomean
0.754 / 0.624, Tier1 ~0.6) with a single real regression cell: TN_144_2_13 no-card, the after-first-solution chain of
at-cap solutions (DIAGNOSIS.md cause 2). Next: target that cell (e.g. a fresh solver for the tie-break/feasibility probe only
when the previous persistent probe returned exactly the cap; or a conflict budget that falls back to a fresh probe).
