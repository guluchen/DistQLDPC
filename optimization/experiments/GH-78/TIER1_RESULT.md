# GH-78 Tier1 result (coordinator, corrected baseline 72d1fe1) — REJECT
Mac, frozen base 3f2fbc42… vs cand 1bf025c2…, bound-soundness runner, 208/208 correct, timing lock held.
| Case | OFF ratio | MTO ratio | Path |
|---|---:|---:|---|
| BB_90_8_10 | 1.1829 (reg) | 1.4740 (reg) | single-XOR decomposition (r=2) |
| GB_144_12_8 | 0.8579 | 0.4755 | decomposition (r=2) |
| BB_108_8_10 | 1.2546 (reg) | 1.3244 (reg) | decomposition (r=2) |
| LP_238_44_6 | 0.4515 | 0.5609 | fallback to OR half (= GH-73-style split) |
| geomean | 0.8707 | 0.8495 | |
Replication: OFF 0.8737 / MTO 0.8484, same regression flags. Fixed judge: not positive, non-overlapping regressions
on BB90/BB108 in both modes => REJECT. Informational vs GH-73 on the same baseline/host (OFF/MTO): BB90 0.46/0.89,
GB144 0.43/0.29, BB108 0.61/0.46, LP238 0.46/0.51 — the decomposition is slower than the plain halves where it applies.
Learning: replacing the OR over logical parities by several single-XOR subproblems multiplies probes/refutations
(4 parts instead of 2) and each subproblem is not easier enough to pay for it on BB codes.
