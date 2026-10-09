# GH-85 result — Tier1 + Tier2 PASS on corrected baseline 72d1fe1 (Mac diagnostic); strongest candidate so far
Interaction experiment GH-73 (interleaved CSS split) x GH-75 (symmetry breaking), per-half orbit clauses.
Agent mac-split-symbreak-20261009 (implementation, Tier0) + coordinator (Tier1/Tier2). Issue #85, draft PR #86.
Tier0 PASS (Mac + Linux regressions, -joint/-no-symbreak identities, 200/200 server sweep with 17 candidate-only
completions, independent GF(2) check, cross-repo YES). Tier1 OFF 0.159 / MTO 0.145 (all 8 cells improved,
replicated). Tier2 LP340 OFF 85.4 -> 1.53 s (56x), MTO 59.4 -> 1.62 s (37x).
Caveats: Mac host not controlled; TN_200_10_10 no-card (no symmetry; GH-73 behaviour) slower in a parallel sweep;
independent code review requested. Adoption (default vs flag), Tier3/controlled runs: PI/integrator decision.
