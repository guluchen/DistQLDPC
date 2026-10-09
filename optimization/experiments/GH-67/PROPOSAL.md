# GH-67 preregistration: fixed 64-byte code alignment with layout-noise control

Owner/session `mac-align-20261009` (same Mac-host agent; round 3 after #34 INCONCLUSIVE and #60 REJECT; the user asked me to keep running rounds and discuss adoption afterwards). Hub #15. Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`; not stacked on #34/#60. Hypothesis IDs GH-67-A/B/C. Host: Apple M6 Mac mini (arm64, Apple clang 21), user-authorised, sole runner; diagnostic, not controlled.

## Evidence/learning before proposing
- Search-identical micro-changes so far land in a narrow band: #34 literal mirror ~-1%, #21 O2 ~-0.7%, #40 ternary path +1.4..+5% (all disjoint), #50 no codegen change. On a hot loop that is ~70% of runtime and branch/load bound, code placement alone may move results by this much. No experiment has measured the layout noise floor, so a +-1% result cannot currently be separated from layout.
- #60: lookahead work savings that change the iset sequence cause +-30-40% search-path swings; search-changing heuristics need many more cases than Tier1 to judge.
- Baseline counters: only ~3% of conflicts are hard conflicts (e.g. BB108 MTO 1,633 of 48,910), so almost all learnt clauses are bound-dependent.

## Three proposals (ranked)
**A (SELECTED) — fixed 64-byte function and loop alignment, with a layout-noise control.** One build concept: add `-falign-functions=64 -falign-loops=64` to the original CXXFLAGS (all objects), nothing else. Machine-code placement only: search is identical, so byte-identical `-v` traces are the correctness oracle (as #34). Supporting measurement (not a second concept): three baseline relinks that differ ONLY in object link order, timed against the baseline under the same protocol, to estimate the layout noise floor on this host; the candidate is then judged by the unchanged GH16 rule AND reported relative to that floor. Ordinary compiler engineering (no paper). Risks: code-size growth/i-cache, flag semantics differ between clang/arm64 and GCC/x86 (no cross-host claim), effect may be within noise.
**B (unselected) — keep bound-independent learnt clauses across failing UB phases**, re-admitting a learnt only if it is RUP w.r.t. hard clauses after `removeLearntClauses()` (sound without provenance tracking). Measured blocker: ~97% of conflicts are soft/bound conflicts, so few clauses would survive; failing phases are 15-41% of conflicts. Engineering idea.
**C (unselected, needs PI approval) — static symmetry breaking from code automorphisms.** Codes like BB/GB/LP have large automorphism groups; lex-leader / structure-based constraints in the style of M. Anders, S. Brenner, G. Rattan, "Satsuma: Structure-Based Symmetry Breaking in SAT", SAT 2024, LIPIcs 305, 4:1–4:23, DOI 10.4230/LIPIcs.SAT.2024.4 (extended JAIR 85:6, 2026) could prune equivalent logical operators while preserving the optimum. This changes the MaxSAT encoding, so per AGENTS.md it is escalated for a PI decision and not implemented here.

## Scope / exclusions
Makefile CXXFLAGS gains the two alignment flags; no source, linker, other flag, heuristic or encoding change. Relink controls are measurement-only binaries, never candidates.

## Validation and gates (preregistered in PROPOSAL.md)
Tier0: build/smoke; `-v` trace identity (stdout+stderr byte-identical for completed runs, child-prefix-consistent for timeouts, corrected comparator from #34) on all 50 codes x 4 modes at 60 s; LP340 timeout outputs; hosted CI + cross-repo.
Tier1: 4 cases x OFF/MTO, 3+3 AB/BA/AB + 10 replication pairs, unchanged GH16 judge, 180/195 s, frozen binaries. Noise control: each of 3 relink variants vs baseline, 3+3 AB/BA/AB per case/mode (144 solves), reported as per-cell |log ratio| distribution. Interpretation fixed now: a candidate cell counts as "beyond layout noise" only if its |median ratio - 1| exceeds the largest |median ratio - 1| of the relink variants in that cell. Tier2 LP340 only via the gate or the recorded standing exploratory instruction. No Tier3.

## Exact parameters (fixed before implementation)
- Candidate: Makefile `CXXFLAGS` += `-falign-functions=64 -falign-loops=64`; built clean with
  `make CXX="c++ -Wno-reserved-user-defined-literal"`; frozen read-only copy.
- Baseline: GH-34/GH-60 frozen baseline binary (sha256 ac43af52…6eb26).
- Relink controls R1–R3: the baseline's own object files (`../base/build/*.o`, from the same
  baseline build) linked with the original link command but object order
  R1 = System Options Solver SimpSolver, R2 = Options SimpSolver System Solver,
  R3 = Solver System SimpSolver Options (baseline order: SimpSolver Solver Options System).
  Each must pass smoke and BB_90 OFF `-v` trace identity with the baseline before timing.
- Tier0 trace identity: GH-34 `tier0_trace_identity.py` at `--limit 60`, judged with the
  corrected `rejudge_trace_identity.py` (declared now, before running).
- Tier1 order: candidate gate+replication (`tier1_mac.py`, unchanged), then R1, R2, R3 each
  3+3 vs baseline (`tier1_mac.py --replicate 0`), all on the same host session.
