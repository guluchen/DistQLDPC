# GH-103 proposal — search-identical speedups of the lookahead bookkeeping

Issue #103 (hub #15). Base: GH-95 restructured engine `ae95b17` (search-identical to main `7eadd54`;
reference binary `frozen95/cand/distqldpc`, sha256 `de88d7ff…`). Branch `experiment/gh-103-lk-bookkeeping`.
Code: `src/engine/Lookahead.cc` (+ `src/solver/mtl/Heap.h` / `src/solver/Solver.h` for the heap type).

## Evidence (main 7eadd54 profiles, GH-98 `profile-main7e`, self samples from the `sample` call graph)

| | GB_144_12_12 no-card | LP_544_80_12 card-mto |
|---|---:|---:|
| propagateForLK | 67.6% | 62.5% |
| lookbackResetTrail | 7.2% | 9.9% |
| pickAuxiVar | 5.3% | 9.1% |
| uncheckedEnqueueForLK | 2.2% | 3.2% |
| `Heap<VarOrderGt>::insert` (not inlined) | 1.3% | 2.2% |
| bumpConflVars / resetConflicts | 0.7% / 0.7% | 0.9% / 0.5% |

Line attribution (old `Solver.cc` lines):
- pickAuxiVar: 74-85% of its samples sit on `v = orderHeapAuxi.removeMin()` (inlined `percolateDown`).
- lookbackResetTrail: the largest single item is `else if (auxiVar(v)) insertAuxiVarOrder(v); assigns[v] = l_Undef;`
  (15-33% of the function), then the `seen[v]` test of the trail walk; the rest is the resolution loop
  (clause literals, `involved`, VSIDS bump) that is real analysis work.
- `Heap::insert`: 89% on `percolateUp`.
- bumpConflVars: 87% on `orderHeapAuxi.increase(v)`.
- uncheckedEnqueueForLK: call prologue/epilogue (line 0, `return true`) ~45%, the soft test
  `auxiVar(v) && value(softLits[v]) == l_False` ~29%.

So the auxiliary-variable heap `orderHeapAuxi` (removeMin + insert + increase) is ~8-12% of runtime by itself
and is the main lever. All arrays involved are L1/L2 resident (2.5k-6k variables); the cost is dependent
loads (`heap[i] -> activityLB[heap[i]]`) and data-dependent branches.

## Hard constraint: the heap operation sequence must not change

`activityLB` starts at 0 for every variable, decays multiplicatively (0 stays 0) and is bumped only for conflict
literals, so ties are the normal case. With ties, the variable returned by `removeMin` depends on the exact heap
shape, which depends on the exact sequence of insert / removeMin / increase / decrease calls. Therefore:
- Not proposed: lazy deletion or skipping the pop of assigned variables in pickAuxiVar, batching reinsertions
  differently, replacing the heap by a scan or a bucket queue, "touched range" tricks that change the order in
  which lookbackResetTrail reinserts variables. Each of these changes tie-breaking.
- lookbackResetTrail already walks exactly the touched range `trail[trailRecord..]` (it must unassign every variable
  there), so there is no full-trail rescan to remove; the walk itself stays.

Every change below keeps the same calls in the same order and the same comparison results; only the
cost of each operation changes.

## Candidate changes (one commit each, kept only if `sample` shows a measured cost drop)

**C1. Keyed heap for orderHeapAuxi (cached activity keys).** New heap class (same algorithm as
`mtl/Heap.h`) that stores, next to each heap slot, a copy of `activityLB[var]`. Comparisons read the cached key
instead of `activityLB[heap[i]]`, removing one dependent load per comparison in percolateUp/percolateDown.
Why identical: every write to `activityLB` (ClauseDB/Cardinality `push(0)` for new variables; the decay loops in
lookahead, lookaheadForRestart, Hardening x2; bumpConflVars) is immediately followed by
`insertAuxiVarOrder(v)` and `decrease(v)`/`increase(v)` (or happens before the variable is ever inserted). The keyed
heap refreshes the cached key in `insert`, `decrease`, `increase`, `update` and `build`, so at every comparison the
cached key equals `activityLB[var]`, and every comparison has the same outcome as before. Between a write and
its fix-up no other heap comparison involves the stale variable (insertAuxiVarOrder only inserts that same
variable, with its new key). `operator<` on the same doubles gives the same results.

**C2. Bottom-up (Floyd) removeMin with tie-exact sift-up.** Standard percolateDown compares the two children and
then the min child with the moved last element at every level. Bottom-up: move the hole down along the same
min-child path (same child rule `lt(right,left) ? right : left`) to a leaf, then sift the last element up while
`!lt(parent, x)` (parent key >= x). Why identical: the heap property (`!lt(child,parent)`) always holds (decrease is
only called after a key decrease, increase after an increase — rounding cannot invert these:
`fl((1-s)a) <= a`, `fl(a + fl((1-a)s)) >= a` for a in [0,1], s in [0,1]), so keys along the min-child path are
non-decreasing; standard places x at the first path position whose old occupant's key is >= x, and the sift-up that
moves x above every path element with key >= x stops at exactly that position. Same final array, same indices.

**C3. Cheaper insertAuxiVarOrder / Heap insert.** Inline the insert fast path (the out-of-line
`Heap::insert` costs a call per reinserted variable), drop the per-insert `indices.growTo` by sizing the index
array when variables are created, and in lookbackResetTrail / the reset loops call the heap insert directly
after `auxiVar(v)` is already known (no second `auxiVar` test). Same inserts in the same order.

**C4. uncheckedEnqueueForLK soft test with one compare; cold slow path.** `softLits[v]` is either `lit_Undef` or
a literal of `v` itself (`softLits[var(l)] = l` at its only writers, Preprocessing.cc), and `assigns[v]` was just set
so that `p` is true; hence `auxiVar(v) && value(softLits[v]) == l_False` is exactly `softLits[v] == ~p`. The rarely
taken iset-unlock branch moves to an out-of-line helper. Same return values, same side effects in the same order.

**C5 (optional, judged by measurement).** Force-inline the uncheckedEnqueueForLK fast path into propagateForLK
(removes a call per LK enqueue). Changes propagateForLK code layout, so it is kept only if the propagateForLK
share itself does not grow.

resetConflicts, resetConflicts_, bumpConflVars and the decay loops benefit from C1-C3 without own changes.
cancelUntilTrailRecord* are not on the hot path in these profiles and stay unchanged.

## Measurement per commit (agent, Mac, under the timing lock)

- Build `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"`.
- Quick trace check: GH-95 `quick.list` (13 runs, `-v -cpu-lim=20`) vs frozen95 traces, GH-95 `cmp_traces.py` rule.
- `sample` 60 s of the solving child on GB_144_12_12 no-card and LP_544_80_12 card-mto, plus the full-run user CPU
  (both runs complete; search identical, so CPU per run is directly comparable). Primary per-function metric:
  self samples of f divided by self samples of propagateForLK (unchanged code doing identical work, so this is a
  work-normalised cost); secondary: per-function shares and total CPU.
- Keep a change only if it lowers the targeted functions' normalised cost and does not raise total CPU; otherwise
  revert and record in ATTEMPTS.md.

## Tier0 (TIER0_RESULT.md)

smoke; `python3 -B scripts/test_partition_soft_literals.py`; tests/test_partition_soft_literals.cc oracle (cases=80);
full trace identity vs frozen95 on 50 codes x {default,-no-card,-card-sinz,-card-mto} with `-v -cpu-lim=20`
(GH-95 rule; frozen95 traces from GH-95 `raw/traces.tar.gz` `cand/` are the frozen95 binary's output and are reused;
reruns at -cpu-lim=30 if the candidate gets less far); maxcdcl identical output on the 6 GH-95 instances;
cross-repo branch `ci/xrepo-gh103` (candidate tree, parent 7eadd54) + QDistSAT cross-repo benchmark.
All solver processes run under the 2 GB cap (coord/memlimit.py).
