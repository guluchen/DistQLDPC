# GH-71 result — Tier2 PASS (local diagnostic), NOT ADOPTED as-is; follow-up required

| Field | Value |
|---|---|
| Agent / issue / PR | mac-csssplit-20261009 / #71 / draft #72 |
| Hypothesis | GH-71-A CSS X/Z split, d = min(dX,dZ) (PI-approved formulation change, 2026-10-09) |
| Baseline / candidate | 24572d6 / src 6805148 |
| Tier0 | PASS: 50x4 science sweep 200/200, -joint identity, hosted cross-repo match YES |
| Tier1 | numerically positive: OFF 0.452 / MTO 0.439 geomean, all 8 cells non-overlapping improvements |
| Tier2 | PASS: LP340 85.5->15.0 s OFF (0.176), 59.4->21.7 s MTO (0.365) |
| Review | no blocker; MAJOR timeout lower-bound loss; asymmetric-code regression (TN_200) |
| Disposition | **PROMISING / NOT ADOPTED as-is** (gates passed on a diagnostic host; known regressions in bound reporting on timeouts and on asymmetric codes) |

## Learning
- The joint symplectic encoding is the dominant cost for symmetric CSS families (BB/GB/LP): solving
  the X and Z halves separately is 2–6x faster on Tier1/Tier2 with identical distances.
- Sequential halves break the anytime lower bound and lose on asymmetric codes where the first half
  has the larger distance. A deployable version must interleave the halves (global LB = min(LB_X, LB_Z)),
  cap the second half by the first value, stop when LB >= UB, and reset per-instance solver state.
## Next: GH-71-B (separate experiment) implements those fixes and is re-gated against the baseline.
