Coordination hub #15. Agent/session `fable-triwatch-20261008` (Claude Fable 5.1 session on a macOS host, independent of the Codex primary/independent/review agents). Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`; history read from `experiment/h001-logical-row-xor` (docs commit bc9c470), none of its H001 source used. State: **PROPOSED / preregistered, implementation starting; UNTESTED, no host slot.**

Preregistration (written before any candidate edit, with raw baseline profiles and diagnostic counts): [`optimization/experiments/GH-fable-triwatch/PROPOSAL.md` on branch `experiment/fable-triwatch-20261008`](https://github.com/guluchen/DistQLDPC/blob/experiment/fable-triwatch-20261008/optimization/experiments/GH-fable-triwatch/PROPOSAL.md). The directory is renamed to `GH-<this issue>` after registration.

## Evidence that motivated this round (diagnostic only)
Function-level sampling of the pinned baseline (GCC 16.2 -O3, Apple M3 Max) on the four Tier 1 cases, OFF and MTO: **63–71% of solver time is `Solver::propagateForLK`** (lookahead unit propagation, baseline `Solver.cc:3932`); `lookbackResetTrail` 7–11%, `pickAuxiVar` 5–8%, ordinary `propagate` 2–5%. An instrumented copy (counters only, never in the candidate) shows in BB_90 OFF 315.9M long-watch visits, 79% skipped by the blocking literal, 65.3M clause dereferences of which 34% are size-3 clauses and 30% size-4 (post-preprocessing instances are mostly 3/4-literal clauses). Size-3 share of dereferences: LP_238 MTO 20%, GB_144 OFF 35%, BB_108 MTO 37%. Counts quantify an opportunity, not a time share or a speedup.

## Three proposals, ranked
| ID | Mechanism | Source | Expected cases | Risk / cost | Rank |
|---|---|---|---|---|---|
| **GH-<n>-A (SELECTED)** | **Tri-watch**: size-3 clauses watched on all three literals; each watcher carries the other two literals (`{CRef,Lit,Lit}`), so lookahead/main propagation decides satisfied/unit/conflict for ternary clauses without touching clause memory and never moves their watches. Binary inline watches and the ≥4-literal circular scan are unchanged. | Engineering; precedent Chu/Harwood/Stuckey JSAT 2009 (blocking literals, inlined binaries; DOI 10.3233/SAT190064), Z3 SAT core had and later removed ternary watches (negative precedent, noted) | OFF and MTO, all Tier 1 + LP340 | Watcher-value consistency on in-place clause rewrites, size-transition paths, `c[0]`-implied invariant, +50% ternary watcher visits, trajectory change; 2–3 days | 1 |
| GH-<n>-B | Proximity literal ordering of the MTO totalizer inputs (`allSoftLitsForCardC`, baseline `Solver.cc:6195/6275`): BFS co-occurrence score over hard clauses, encoding unchanged | Reeves, Filipe, Hsu, Martins, Heule, AAAI 2025, DOI 10.1609/aaai.v39i11.33232 (full text read; "Literal Sorting Methods", Table 1) | MTO mode only | Semantics-preserving, ~1 day; benefit via learning quality, unmeasured here | 2 |
| GH-<n>-C | `used` bit set in conflict analysis, honoured by `reduceDB()` (baseline `Solver.cc:2658`), small clauses kept unconditionally | Gstrein, Pollitt, Schidler, Fleury, Biere, SAT 2025, DOI 10.4230/LIPIcs.SAT.2025.14 (full text read; Alg. 1, §6) | both modes | <1 day; may slow lookahead by retaining more clauses; SAT-competition evidence only | 3 |

BibTeX for all three in `references.bib` beside the proposal. Not re-proposed: prefetch (GH-17-C/H005), demand watch cleanup (GH-17-B/GH-20-C), self-copy skip (GH-20-A, active), PGO (GH-16), scratch reuse (GH-17-A), LTO/SLS/BDD/encoding changes (E001–E006). A attacks the same loop as GH-17-C/GH-20-A by a different mechanism (fewer dereferences) and is not combined with them.

## Why A
It is the only candidate whose target was measured this round. B and C change search through learning quality with evidence from other workloads.

## Scope / exclusions
Solver.h/Solver.cc (+ SimpSolver cleanup of the new lists), MODIFICATIONS/NOTICE. No heuristic, restart, clause-DB, cardinality, preprocessing, encoding, timeout, output or compiler-flag change. Propagation closure must be identical; implication order within one literal changes (binary → ternary → longer), so trajectories may differ; distance/objective/bounds/WCNF must not.

## Gates, budget, resources
Tier 0: identical WCNF exports (7 instances), test-only propagation-closure differential harness (random partial assignments, sorted implied sets + conflict flag identical to baseline for `propagate` and `propagateForLK`), tiny CSS brute-force oracles, end-to-end exact results on LP34/LP136/BB90/GB144/BB108/LP238/LP340 both modes, smoke, six `-cpu-lim=1` timeout checks, hosted CI + required QDistSAT cross-repo check. Any mismatch → REJECT.
Tier 1: BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6; OFF/MTO; 3 baseline + 3 candidate each, serial AB/BA/AB, 48 solves, 180/195 s; preregistered rule: per mode G = geomean of candidate/baseline median ratios, V = geomean of baseline max/min; PASS iff G<1, G·V<1 and no disjoint per-case regression; REJECT if a disjoint regression >2% with G≥1; else INCONCLUSIVE. Tier 2 LP340 (12 solves, 600/615 s) only on PASS or explicit PI exception; no Tier 3.
Host: this agent's own Apple M3 Max macOS machine (not used by any other agent). `RUN_REQUEST` will be posted in #15 before any timed solve; nothing timed starts without an assignment. Team spare-capacity rules respected (no load on yfclab2 or the Windows host).

## Current record
candidate SHA / PR: unset. Tier0/1/2: NOT RUN. Result: UNTESTED.
