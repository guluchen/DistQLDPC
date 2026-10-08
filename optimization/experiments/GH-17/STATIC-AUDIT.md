# GH-17-A static lifetime audit and implementation plan

Issue: https://github.com/guluchen/DistQLDPC/issues/17
Agent: independent-brain-20261008. Baseline24572d6.
Research only; no candidate, correctness result or performance result.

Inspected preserved baseline source package:
`E004-windows-tier2-02/E004-server-package/baseline/`.
Before implementation verify its source against Git24572d6 in the new worktree.
Local byte hashes (preserved package newline format):

- Solver.cc SHA25647047cd1e2cb9c71eef570c01b22d2e004a436bed641a0fa00ccb4dffdad7015
- Solver.h SHA256f85bcb8ea4cb204ad502eb62cc7623c26977e0d56b3a9c80ba9d259d8349fe6c
- mtl/Vec.h SHA2563585058b7f6b439d89f99ff81cc85422282e44432fab632e20aeae50811ebf58

## Observed ownership and calls

setConflict is declared once in Solver.h611 and defined in Solver.cc4240.
Exactly three source calls:3439 in lookaheadForRestart (starts3332),4931/4949
in lookahead (starts4802). Local oldset declaration is4247; issue's initial
approximate4248 reference is only a source locator, not a diff claim.
It contains integer subIset identifiers, never Clause references.
Its only accesses are clear, push, size, indexed reads into existing isets.
No pointer/reference to oldset is retained. No call to setConflict/its callers
inside setConflict. Solver.h625--635 lock/getLockedVar helpers are inline
index accesses/updates, with no recursive callbacks. Remaining container calls
are ordinary vector init/grow/push/clear/shrink, not solver-control calls.

lookahead has several early returns before declaring out_learnt4878 and before
the core loop. Put caller-local vec<int> oldset alongside out_learnt after
these fast returns. lookaheadForRestart out_learnt/ps declaration3359 is before
its core loop. Reset paths return or continue with nbIsets=0; scratch must clear
on every setConflict call, independent of nbIsets/reset paths.
Stack ownership naturally releases capacity on normal/early caller returns and
unwinding, isolates separate Solver instances, and avoids global static reuse.

## Exact conceptual diff planned

1. Extend setConflict signature to (int& nbIsets, vec<int>& oldset).
2. Remove only its local vec<int> oldset declaration; keep oldset.clear() at
   the same point relative to unlock updates and every existing push/read.
3. Declare one local scratch in each of the two callers and pass it at all3
   call sites. No pre-reserve, shrink tuning, algorithm-state change or pooling.
4. Supporting tests and downstream MODIFICATIONS/NOTICE only as required.

Expected final source diff is small, but no diff has been made. Leave original
seen reset, merge order, lock calculations, finalIset updates and nbIsets++
untouched. Vec.h itself must remain untouched in final candidate.

## Allocation diagnostic before any benefit claim

Instrument a separate baseline-only diagnostic snapshot, outside final candidate.
For each caller distinguish restart/main and caller instance, record number of
setConflict calls, oldset peak size per call, actual reallocations inferred from
capacity crossings around original pushes, and oldset peak allocated bytes.
Replay exactly Vec.h capacity growth on each caller's size sequence to calculate
how many allocations reuse could avoid; record dry replay as a predicted count,
not a measured time. Multiple empty calls do not demonstrate opportunity.
Emit one aggregate diagnostic at caller exit (RAII diagnostic object or explicit
scope-safe aggregator) to stderr with a unique prefix; include early returns.
Do not add production flush/_exit hooks or modify final output/timeout semantics.
Bounded four120s diagnostic solves require host assignment/capacity accounting.
Do not put diagnostic instrumentation into baseline/candidate timed binaries.

If buffers are empty or cannot save allocations, reject the mechanism locally
without performance tiers and retain diagnostic. If opportunity exists, sample
allocation time if the host provides a trustworthy profiler; do not equate
allocation frequency with whole-solve dominance. No diagnostic run yet.

## Tests required for isolated implementation

- Compare original fresh-vector and caller-reused production setConflict paths
  on nonempty overlap, disjoint/empty, repeated merges with varying cardinality,
  reset nbIsets to0 and repeated caller lifetimes; compare all touched core state.
- Validate early return/exception destruction and separate Solver instances;
  ensure stale entries are cleared before each merge.
- Existing brute-force MaxSAT/CSS fixtures, smoke OFF/MTO, exact initial WCNF,
  bound/result consistency and forced timeout behavior.
- Required hosted ordinary and QDistSAT cross-repo checks on pinned candidate;
  shared-runner timing informational.
- In separately retained diagnostic logs compare deterministic search/core
  counters where meaningful; phase-specific counters remain phase-specific.

No call-graph soundness escalation currently identified, but correctness is
NOT established until those tests and independent review succeed. Increased
retained peak memory until caller return must be recorded; RSS claim unmeasured.

## Source provenance

General engineering technique supported by inspected source lifecycle. No paper
claim and no BibTeX entry required/invented. Unselected prefetch proposal source:
https://gcc.gnu.org/onlinedocs/gcc-12.2.0/gcc/Other-Builtins.html (official GCC).
Existing unselected H011/H005 overlap disclosed; do not treat names as novelty.
