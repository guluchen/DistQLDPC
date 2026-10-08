# GH-20 / review-brain-20261008 preregistration

Recorded before implementation on 2026-10-08. Selected GH-20-A; GH-20-B/C unselected.
[Issue20](https://github.com/guluchen/DistQLDPC/issues/20), [coordination hub15](https://github.com/guluchen/DistQLDPC/issues/15).
Independent branch experiment/gh20-watch-tail starts exactly from baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a.
Only this proposal is committed; no candidate source, new test result or timing result.
No local worktree/build/host lease created yet. Latest hub ownership now reserves Windows for primary H010 exploratory Tier2; no significant compute by this agent.

Coordination hub #15; owner/session `review-brain-20261008`. Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`. State PROPOSED / UNTESTED; no host slot, implementation, build, diagnostic or benchmark run.

DistQLDPC's embedded engine derives from MaxCDCL and contains downstream instrumentation/optimizations; QDistSAT is the separate benchmark platform. Preserve scientific/Pauli/CSS/logical-operator, bound, timeout, result and attribution semantics.

## Three proposals, independently ranked before implementation

### A — skip self-copy tails in lookahead propagation (SELECTED, rank 1)
One performance concept: in `Solver::propagateForLK` ONLY, at its two long-watch conflict-tail loops (baseline Solver.cc4027/4034), when input/output pointers are equal (`i == j`) replace the suffix's repeated `*j++ = *i++` with `i = j = end`. When pointers differ, retain the ORIGINAL loop. No memmove, general watch-loop rewrite, prefetch, global cleanup change, allocator reuse, compiler option or heuristic bundle.
Mechanism: an unchanged watch-list suffix copies each Watcher onto itself when preceding entries required no compaction. Skipping those stores leaves the same list contents, i/j/end and final shrink count. Watcher contains CRef/Lit with implicit side-effect-free assignment (Solver.h247); confirm whole relevant assignment/type definition and all pointer uses before editing.
Expected cases: OFF/MTO with long remaining watch lists and frequent lookahead conflicts; benefit and occurrence UNMEASURED. Does not claim propagation counts prove memory stalls.
Prerequisite: separate pinned-baseline diagnostic counts each tail event, i==j events, skipped-length distribution and theoretical skipped Watcher stores. Also inspect optimized code to check whether compiler already skips self-copy tails. Counts measure opportunity, not time saved. A zero/negligible opportunity or existing generated-code shortcut can justify shelving without claiming a timed regression.
Risks: wrong pointer advancement, self-copy assignment assumptions, missing compaction, branch overhead when tails are short or already compacted, runtime/counter equivalence. All nonidentity copies and ordinary/simple propagation remain unchanged.
Tier0: differential ORIGINAL/candidate production propagation fixtures for both hard-conflict and soft-enqueue-failure exits; i==j and i!=j; empty/one/many tail; moved watches, blockers and deleted-list cleanup/GC. Compare complete live watch order/cref/blocker, assignments/trail/qhead/reasons/falseVar/conflict flags, returns and phase counters. Small exact MaxSAT/CSS, original CNF, smoke and timeout/bounds/result checks, plus required hosted cross-repo. No scientific mismatch may proceed.
Scope Solver.cc plus directly related tests/MODIFICATIONS/NOTICE. Expected engineering cost one day; bounded diagnostic four fixed LP34/LP136 OFF/MTO solves,120/135s limits after host assignment. No predicted gain percentage.

### B — symmetric activity for a lookahead binary conflict (rank 2, UNSELECTED)
Actual baseline `lookbackResetTrail` VSIDS path4077/4078 bumps binConfl[0] twice at .1; normal conflict analysis1683/1684 bumps both literals symmetrically at .5. Proposed ONE heuristic change: second lookahead .1 bump targets binConfl[1], keeping the two weights and all other rules unchanged.
Hypothesis: less order bias toward the triggering literal improves VSIDS decisions on cases with frequent binary lookahead conflicts. This observation is NOT proof of a bug or performance loss; orientation may be intentional. LRB-only cases unaffected; applicability needs count audit.
Risks: changed search/restart trajectory and family-dependent regression; scientific answer/bounds must remain exact. Do not require identical counters for this heuristic proposal. Require exhaustive small partial MaxSAT/CSS and timeout result tests. Engineering hours-to-one-day, bounded diagnostic then ordinary filters; greater uncertainty than A. No simultaneous activity rescaling, restart/branch changes or weight tuning.

### C — demand watch cleanup only in lookahead (rank 3, UNSELECTED)
Re-rank disclosed unselected GH17-B, not invented novelty. Replace propagateForLK's global watches.cleanAll()/watches_bin.cleanAll() with existing lookup(p) for only reached lists. OccLists stable-clean and dirty queue at SolverTypes.h329-383 inspected.
Potential savings only when many dirty lists are never reached; count reach/dirty ratio before claiming mechanism. Risks deleted CRefs, pending appends/raw accesses, dirties growth and GC relocation; audit cross-path consumers. If wider container redesign required, withdraw narrow proposal. Engineering2-3days plus lifecycle tests/common tiers. Do not combine with selected A.

## Sources, prior learning and selection rationale
All three derive from inspected pinned downstream code and ordinary engineering/heuristic reasoning. No paper used as origin, BibTeX NOT APPLICABLE; any later paper-derived method must retain exact primary version/section and BibTeX.
A lowest algorithmic risk: same state/order, concrete redundant operation, directly falsifiable opportunity. GH17's9/328 predicted allocation savings/8byte peak did not establish a useful allocator hotspot, motivating a different operation. H010/issue16 active PGO is NOT combined. E001/E002/E006 encoding-size changes altered search and did not guarantee speed; E004 LTO shelved; E005 fixed SLS cap mechanism failed. No universal family rejection.
Read AGENTS/current optimization policy/STATE/HYPOTHESES/Round5 and hub/issue16/17 evidence; open/closed issue search found no selected A duplicate. Reread hub after registration; lower-number issue keeps a concurrently duplicated original concept.

## Preregistration / coordination / gates
Start separate branch/worktree from baseline, write optimization/experiments/GH-<this issue>/PROPOSAL.md before candidate edits. IDs A/B/C local to this issue; do not race-write shared STATE/HYPOTHESES/bibliography.
Host slot NONE. Windows reserved for primary PGO Tier1 at hub comment6062796854; NO builds/tests/diagnostics/timing by this agent while assigned. Source inspection/metadata only now. Team spare>50%, use<=half spare; one assigned runner per host, same-CPU serial versions.
Tier0 first, semantic mismatch/crash/output/bound/timeout regression rejects and stops. Only thereafter Tier1 BB90/GB144/BB108/LP238, OFF/MTO,3/version each,48 serial AB/BA/AB solves,180/195s limits, raw timings/medians/variability/science/identity/telemetry and cleanup durable. Worst watchdog156min. Tier2 LP34012 solves600/615s only by positive reproducible gate/no serious regression or separately scoped explicit user exception. No Tier3 from this prerecord.
Diagnostic vs controlled evidence distinct; CI timing informational. Missing controlled resources remain INCONCLUSIVE with reproducible package. Retain rejected/aborted/uncertain results and learning, not repeat-until-favorable.
Candidate/branch/PR/raw performance: unset. Next: independent static correctness audit and isolated prerecord; request host assignment before any significant compute.

