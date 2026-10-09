# GH-73 result — Tier1 + Tier2 PASS on the corrected baseline (local diagnostic); recommended for adoption review

| Field | Value |
|---|---|
| Agent / issue / PR | mac-cssinterleave-20261009 / #73 / draft #74 |
| Mechanism | CSS split d = min(dX,dZ) via global bound search over X/Z halves (PI-approved formulation change) |
| Baseline / candidate | corrected 72d1fe1 / branch experiment/gh-73-mac-cssinterleave-72d (src = a1585b4) |
| Tier0 | PASS: mandatory regressions (Mac+Linux), -joint identity, 200/200 science sweep on yfclab2, anytime LB restored (135/136 better final LB on both-timeout runs), cross-repo match YES, code review no blocker/major |
| Tier1 | positive: OFF 0.485 / MTO 0.498 geomean, all 8 cells non-overlapping improvements, replicated |
| Tier2 | PASS: LP340 85.5->3.33 s OFF (25.6x), 59.5->3.39 s MTO (17.6x) |
| Known caveats | Mac diagnostic host (not controlled); TN_200_10_10 no-card slower in the 4-way-parallel server sweep (base 35.9 s, cand > 60 s); design iterated on informal runs incl. LP340 (disclosed); `-dump-wcnf` ignored on split path; Tier3 not run |
| Disposition | **PASS through Tier2; adoption needs PI/integrator decision (default vs flag, Tier3/controlled runs)** |
