# GH-71 independent review (subagent, files/data only, no runs) — no BLOCKER

OK: d = min(dX,dZ) holds as an identity between the joint encoding's exact constraints and the two
halves (matrix roles correct; nonzero clause redundant); every LB/UB line the child can emit is a valid
global bound (also checked on all 200 Tier0 runs: no unsound/crossing bound, monotone sequences);
single final RESULT; weight extraction correct; Tier1/Tier2 numbers recompute exactly; harness
byte-identical to GH-60; frozen hashes match; TN_200 dX=14/dZ=10 supported (X ~605k conflicts vs Z ~55k).

MAJOR (accepted): **timed-out runs lose their lower bound.** 136/138 candidate Tier0 timeouts emit no
d_lb (still in the first half, whose LB is not global); baseline had LB 2–8 there. Affects every
"unknown"-distance research code (BB_288, BB_360, LP_714, LP_1768, PK_31, xu_*, large TN). UB improved
in 14 runs (e.g. GB_144_12_12 12 vs 15). Inherent to sequential halves.
MINOR (accepted): asymmetric codes (TN_200 regresses in all 4 modes; no TN code in the gates; X is
always solved first); no early stop once LB_Z >= dX; function-local `static` solver state (search
prevUB, addCardinalityConstraints prevUB, lookahead thres/prevConflicts/maxSuccLB) leaks from the
X-half instance into the Z-half instance (soundness unaffected, timing/heuristics confounded); an
infeasible half with rows would make the child die -> UNKNOWN; `-dump-wcnf` ignored in split solves;
banner text; preregistered -joint identity and per-half spot checks lacked raw evidence (now saved in
`raw/tier0-spotchecks/`: -joint byte-identical to baseline, per-half dX/dZ on 12 runs).
