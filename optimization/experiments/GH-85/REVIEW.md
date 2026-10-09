# GH-85 independent review (subagent, read-only, pure-Python checks) — no BLOCKER, no MAJOR
OK: per-half symmetry argument proved (pi preserving rs(Hpar) and rs([Hpar;Glog]) preserves ker(Hpar) and
ker([Hpar;Glog]), hence the feasible set F = ker(Hpar) \ ker([Hpar;Glog]) and weight); every call type (capped
feasibility, refutation, optimisation, initLB reuse) keeps identical answers because for every weight w a solution
exists with the clause iff without it; orbit-chain CNF exhaustively checked equal to first-orbit semantics;
helper vars may be eliminated (sat-preserving, never in cost); unit-clause offset handled (path unused on the
bundled set); kept permutations re-verified independently (kernel route + rowspace route + 200 random feasibility
samples) for BB90/LP238/TN108/LP340; Tier1/Tier2/Tier0 numbers and science fields recomputed and match.
MINOR: (1) candidate maps not runtime-checked for bijectivity (all families bijective by construction; add an
assert in future edits); (2) leading "OR of representatives" clause redundant; (3) attribution: gates measure
GH-73+GH-85 together vs the joint baseline; the "~3x on top of the split" comes from separate runs (Tier2 ~2.2x) —
a same-session GH-73 vs GH-85 head-to-head is scheduled as informational evidence.
Note: TN_200_10_10 no-card (no symmetry; GH-73 behaviour) did not finish in 60 s in the parallel sweep.
