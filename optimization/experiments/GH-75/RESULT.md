# GH-75 result — Tier1 + Tier2 PASS on corrected baseline 72d1fe1 (Mac diagnostic); adoption needs PI/integrator decision
Agent mac-symbreak-20261009 (implementation, Tier0) + coordinator (Tier1/Tier2). Issue #75, draft PR #77,
candidate src bbe5055 on 72d1fe1. Mechanism: code-automorphism symmetry breaking on the joint encoding
(verified permutations -> unit clause w_0 for transitive groups, orbit chain otherwise); PI-approved encoding change.
Tier0 PASS (200/200 server sweep, GH58 regressions, -no-symbreak identity, independent GF(2) check, cross-repo YES).
Tier1: OFF 0.494 / MTO 0.299 geomean, all 8 cells non-overlapping improvements, replicated.
Tier2: LP340 0.889 OFF / 0.786 MTO.
Caveats: Mac host not controlled; gains concentrate on codes with a transitive automorphism group (BB/GB);
LP/TN codes get weaker orbit chains. Natural follow-up: combination with the CSS split (GH-73), in progress as a
separate interaction experiment.
