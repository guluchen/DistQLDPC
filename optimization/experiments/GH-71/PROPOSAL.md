# GH-71 preregistration: CSS X/Z split (PI-approved encoding change)

Owner/session `mac-csssplit-20261009` (same Mac-host agent, round 5). Hub #15. Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`; not stacked on #34/#60/#67/#69. Hypothesis IDs GH-71-A/B/C. Host: Apple M6 Mac (user-authorised, sole runner); diagnostic, not controlled.

**PI approval for an encoding change**: on 2026-10-09 the user/PI answered "可以改" to my escalation listing (i) CSS X/Z split and (ii) code-automorphism symmetry breaking (#67-C, #69). Per AGENTS.md these change the MaxSAT encoding/formulation; they are run as separate single-concept experiments. This issue is (i).

## Scientific basis (no change to the distance definition)
For a CSS code, any nontrivial logical (x, z) has x a nontrivial X-type logical or z a nontrivial Z-type logical, and |x|, |z| <= |(x, z)|; conversely every pure X or Z logical is a Pauli logical. Hence d = min(dX, dZ) with
- X half: minimise |x| s.t. Hz x = 0 and OR_j (Gx_j . x) = 1;
- Z half: minimise |z| s.t. Hx z = 0 and OR_j (Gz_j . z) = 1.
This is the same nontriviality test the joint encoding uses (`a_j` parities over Gx with x and Gz with z), restricted to one Pauli type; Pauli weight, logical-operator and distance semantics are unchanged.

## Evidence before proposing (scratch WCNF generator + standalone `maxcdcl`, single diagnostic runs, not timing evidence)
- Correctness spot check: min(dX, dZ) equals the named distance on LP34, LP136, TN36(3), TN36(4), TN54, TN72(4), TN72(8), BB72.
- Joint vs X+Z wall: BB90 2.53 vs 0.54+0.54 s; GB144 0.87 vs 0.23+0.61; BB108 3.79 vs 0.76+0.52; LP238 1.39 vs 0.14+0.21; LP340 174.3 vs 4.8+16.3.

## Three proposals (ranked)
**A (SELECTED) — CSS X/Z split in the MaxCDCL solve path.** The child builds and solves the X half, then the Z half (two SimpSolver instances, same card mode/options), reports d = min. Bounds stay sound: during the first half only UB is forwarded (any solution is a valid global UB; its LB is not a global LB); during the second half LB_out = min(LB_Z, dX) and UB_out = min(UB_Z, dX) via a small cap/hide option in `emitBoundsUpdate`; one final RESULT. Halves with no logical rows are skipped. Output format, timeout handling, `-dump-*`/RoundingSat paths unchanged (still joint). A `-joint` flag keeps the original solve path for comparison.
**B (unselected) — split plus second-half pruning**: run the second half with an initial UB so it only proves whether dZ < dX. Needs a careful audit of `initUB`/`providedUB` loop termination; follow-up if A holds.
**C (unselected, PI-approved, separate experiment) — code-automorphism symmetry breaking** (Satsuma, SAT 2024, DOI 10.4230/LIPIcs.SAT.2024.4).

## Validation (preregistered in PROPOSAL.md)
Tier0: build/smoke; science sweep over all 50 codes x 4 modes at 60 s: completed values equal named distances and equal baseline completed values; every emitted d_lb <= d <= every emitted d_ub; per-half dX/dZ logged in -v and min checked; LP340 timeout behaviour (TIMEOUT/UNKNOWN, sound bounds); hosted CI + QDistSAT cross-repo (semantic match required). Tier1: bound-soundness runner (#60), 3+3 AB/BA/AB + 10 replication pairs, unchanged GH16 judge. Tier2 LP340 by gate. No Tier3.

## Exact parameters
- Frozen binaries outside build trees; harness: GH-60 tier0_science.py and tier1_mac_dist.py copied unchanged.
- Science sweep 60 s, 4 jobs; candidate run in default (split) mode; -joint mode also smoke-tested to match baseline traces on BB90.
