# GH40 source equivalence obligation (uncompiled)

Exact baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a. Prerecord79ef965
preceded editing Solver.cc. This is DistQLDPC's downstream MaxCDCL-derived
engine, not upstream MaxCDCL. No other candidate is stacked.

At the specialization site c[1]==~p, c.size()>=3, lastPoint>=2. The original
normalization resets lastPoint>size to2; the new branch follows it unchanged.
For size3 the normalized cursor is2 or3. Cursor2 scans index2 in the first
loop and nothing in the second. Cursor3 scans nothing in the first loop and
index2 in the second. Thus both evaluate exactly index2 once, in the same order.

| index2 value | Original effect (cursor2 or3) | Direct effect |
|---|---|---|
| undefined | swap c[1]/c[2]; append original watcher to watches[~c[1]]; increment i; lastPoint3; goto | identical ordered statements |
| true | blocker=c[2]; copy current watcher to j; increment i/j; lastPoint2; goto | identical ordered statements |
| false | neither loop finds a watch; retain normalized cursor; common unit/conflict path | same common path |

value(Lit) is a pure assigns read plus sign; no assignment occurs between
the original undefined/true comparisons. Caching its tri-state result within
this single evaluation introduces no state transition. Original blocker and
first-value exits precede the branch, including stale-blocker update. The
original >=4 loops are byte-for-byte retained, inside else. No additional
clause access occurs before the original clause-load gate.

Original qhead/trail/reasons/falseVar, suffix compaction, soft-enqueue handling,
lk_propagations, conflict return and watch relocation code remain unchanged.
The moved literal is undefined, hence differs from the currently false watched
literal; its destination is not this same active watch list. Existing allocator,
deleted-list cleanup and GC rules are unchanged; ClauseAllocator::reloc copies
lastPoint (SolverTypes.h313), so the above cursor proof applies after relocation.

This source argument is not a compiled PASS. Exhaustive actual-production
fixture traces must agree before scientific smoke and performance. Newly
prepared test_ternary.cc has5184 cases: size3/4/5, cursor2/3/>size, first/tail
false/true/undefined, orientation/stale-blocker/sign/deletion/GC/soft flags.
Independent return/falseVar/cursor/propagation oracles supplement byte comparison.
The unchanged GH27 test_watch_tail and test_watch_tail_gc fixtures provide
120+120 conflict-suffix/soft-failure/watch-compaction cases per version/build.
Release and assertion-enabled objects must both be exercised. Extra binary
conflict and soft-lock coverage and a bounded guarded driver remain to prepare.

No compilation/test/profiling/performance run yet; named host slot required.
