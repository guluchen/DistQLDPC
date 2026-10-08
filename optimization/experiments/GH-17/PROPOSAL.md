Coordination hub: #15. Owner/session: `independent-brain-20261008`. Baseline: `24572d6d09cce9a4a5faa58300a89e0feba9da6a`. State: PROPOSED / UNTESTED. Research-only initial phase; no worktree, builds, profiles or benchmarks launched.

DistQLDPC is the downstream application with a MaxCDCL-derived engine; QDistSAT is its benchmark platform. Neither is identical to upstream MaxCDCL. Preserve CSS/QECC distance, Pauli weight, logical operators, ground truth, sound bounds, timeout/result/output semantics and upstream notices.

## Three independently ranked engineering proposals

### A — caller-owned core-merge scratch buffer (SELECTED; rank 1)
Mechanism: keep only `setConflict`'s `vec<int> oldset` capacity across successive cores inside ONE invocation of `lookahead` or `lookaheadForRestart`. Pass caller-local scratch by reference, call clear per use, destroy at caller return. No global/Solver-lifetime scratch, general pool, order/heuristic/CNF/compiler changes.

Actual pinned-baseline sites: Solver.cc setConflict at4240, local oldset4248; callers3439 (lookaheadForRestart),4931/4949 (lookahead); declaration Solver.h611. Vec.h destructor clear(true) frees storage, clear(false) keeps capacity. Oldset indices are copied into isets; no observed escape, no setConflict recursion in body. Finish complete call/alias audit before implementation.

Expected cases: OFF/MTO cases with repeated populated core merges within a caller; benefit not measured. Concrete allocation lifecycle differs from E003's construction-only XOR buffer. This matches the shared UNSELECTED H011 opportunity; we independently choose it after code inspection, without claiming novelty. Primary issue16 selects PGO, so no active selected-method duplicate.

Prerequisite: bounded baseline instrumentation (not in final candidate) counts setConflict calls, populated oldset sizes, reallocations and repeated nonempty uses per caller. Reject mechanism if no repeated population / saved allocation opportunity; do not claim a bottleneck solely from call counts. Preserve raw diagnostic separately from comparative timing. First diagnostic budget: small smoke/LP136, at most four serial solves,120s each; instrument original Vec allocation only at this buffer or allocation wrapper, never alter solver choices.

Risks: stale entries, accidental alias, inner lifetime, retained peak memory. Exact operations/order must remain identical. Tier0 tests empty/populated/overlapping merge groups, repeated use, early returns, restart resets and multiple Solver instances; compare exact CNF/science and deterministic search/core counters; cross-repo required checks before timing. One-source concept touches Solver.cc/.h plus directly related tests and MODIFICATIONS/NOTICE. Engineering estimate 1 day, no predicted speed percentage.

### B — demand cleanup in lookahead propagation (rank 3)
Mechanism: in propagateForLK ONLY, replace initial global watches.cleanAll()/watches_bin.cleanAll() with lookup(p) on actually propagated watch lists. OccLists already supplies lookup and stable clean; ordinary/simple propagation and GC cleanup remain unchanged. This is NOT new binary watches or circular clause scans, already present.
Expected: many dirty watched lists but few reached by a lookahead. Measure dirty-list count/reached fraction before implementation.
Scope: Solver.cc propagateForLK3933; OccLists implementation SolverTypes.h329–383 inspected.
Risks: pending deleted CRefs, list appends while dirty, dirty queue duplicate growth, other raw consumers, GC relocation. Must audit every cross-path use and preserve eventual global cleanup; if this requires broad container redesign, withdraw this narrow proposal. Higher semantic/lifecycle risk than A, so unselected. Estimated2–3 days plus targeted deleted-watch/GC tests and common tiers. No new paper attribution.

### C — one-watcher-ahead clause prefetch in lookahead (rank 2)
Mechanism: fixed distance1, read prefetch locality1 of the next LONG watcher clause header in propagateForLK, with next-pointer bounds guard and valid CRef-address evaluation. No tuning sweep, prefetch in other paths, alternate watch representation or search changes.
Expected: propagation-dominated cases if dependent clause loads miss cache; not established. E006 phase counters motivate investigation, not proof of memory stalls.
Scope: Solver.cc propagateForLK long-watch loop only, existing ClauseAllocator address accessor.
Risks: blocker hits cause unnecessary cache traffic; distance1 may be too short; invalid address-expression evaluation and GC lifetime; target-dependent/no-op codegen. Hardware miss/stall evidence would be a prerequisite. This revisits historical untested H005 as a concrete fixed configuration, not a failed experiment or invented novel family.
Primary engineering source: [GCC __builtin_prefetch documentation](https://gcc.gnu.org/onlinedocs/gcc-12.2.0/gcc/Other-Builtins.html); current GCC14.4 page fetch failed, so do not claim it was read. Address expression must be valid even when prefetch itself does not fault. Estimated1–2 days with bounds/GC tests and common tiers. No academic paper or fabricated BibTeX.

## Why A
Lowest algorithmic risk; exact storage ownership change, visible repeated-use sites, independent of selected PGO. Prior E003 did NOT establish allocator dominance. Diagnose saved allocations before spending Tier1. B has deleted-reference/lifetime risks; C lacks measured cache bottleneck. All three are ordinary program optimizations; BibTeX: NOT APPLICABLE. If a later method is learned from a paper, record exact paper/version/section and BibTeX before implementation.

## Shared gates / budget / coordination
Research may proceed in parallel, but initial scope excludes all builds/training/diagnostics/benchmarks until ownership/host assignment. Start isolated branch/worktree from baseline; preregister PROPOSAL before editing candidate. No edits to primary checkout/STATE/HYPOTHESES.
Request host slot through #15; no RUN_ASSIGNMENT means no timed work. Team aggregate global spare>50%, at most half spare, one runner per host, baseline/candidate serial same CPU.
Tier0 correctness/build/smoke and required hosted cross-repo; any mismatch/crash/output regression stops and REJECTS.
Tier1 four cases BB90,GB144,BB108,LP238; OFF/MTO; three/version/case/mode,48 solves, original180/195s limits, raw medians/variability/science/telemetry retained. Worst watchdog budget156minutes.
Tier2 LP340 only positive reproducible Tier1/no serious regression:12 solves600/615s, worst123minutes. No Tier3 from this initial phase. Shared CI timing informational; unavailable controlled resource produces INCONCLUSIVE, never an invented gain.

## Prior learning
E001/E002 smaller encoding did not predict speed; E003 allocation hotspot unproved; E004 LTO shelved; E005 fixed SLS returned no verified caps; E006 generic BDD replacement rejected locally with repeated LP238/LP340 regressions, dedicated corroboration pending. Do not reject these entire method families. Retain every unsuccessful round; next round proposes exactly3 fresh/re-ranked methods before selecting1.

Candidate SHA / PR / raw timing: NONE. Tier0/1/2: NOT RUN. Next: assign isolated implementation ownership, count actual reuse opportunity and perform caller/alias audit; no performance conclusion.

