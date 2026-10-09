# Source-only feasibility, not a correctness PASS

One five-line production insertion in propagateForLK, after the original
current-blocker true skip and before the original current-clause load.
No other executable source or build flags change. Guards: GNU-compatible
compiler; end-i>1; next-blocker != true. Prefetch read/locality1.

## Address provenance and lifetimes

attachClause installs actual ca-allocated Clause-start CRefs and valid literals,
and routes clauses of size2 to watches_bin, larger clauses to watches.
Moved watches in propagateForLK copy the same valid cref and a literal from
the actual clause. This patch assumes those existing invariants; ca.size bounds
alone cannot prove Clause-start provenance. No repair to that invariant is
claimed.

removeClause smudges lists via detachClause before marking/free accounting.
OccLists cleanAll/clean filters marked Clause references before this routine
enters its propagation loop. The existing routine makes both cleanAll calls;
they remain unchanged. RegionAllocator free only accounts wasted words; GC
relocAll cleans watches then relocates every surviving cref before moveTo.
The patch retains no address beyond the prefetch instruction.

propagateForLK and uncheckedEnqueueForLK do not call ClauseAllocator alloc/free,
checkGarbage, garbageCollect or removeClause. Enqueue can grow trail/unlock
vectors and heaps; those do not relocate ca. No recursive propagation call
occurs. The target therefore remains valid when the hint address is evaluated.

i and end refer to the existing watch vector. end-i>1 authenticates (i+1)
inside that vector, so the final watcher never accesses next. j<=i compaction
does not overwrite the next unprocessed watcher. Current relocation pushes to
the list indexed by an undefined candidate literal's negation; that cannot
be the current propagated p (true), so the current watch vector is not grown
by that operation. This is an existing loop invariant, not new narrowing.

value(next.blocker) reads existing assigns only; it has no state or counters
to modify. No ca dereference occurs in the added code, only lea computes the
address. GCC documentation requires that address expression be valid. Non-GNU
compilers omit the insertion, preserving original operations. Clang provides
this GNU-compatible builtin; actual compiler support/codegen must be verified
on the assigned host, no compiler ran during source preparation.

## Semantic argument and limits

The new branch governs only a cache hint. Every original branch, clause/watch
write, enqueue, counter, return, falseVar, qhead, conflict and suffix-copy
operation remains in its original order. No scalar scientific field is written
by the added expression. Instruction layout/extra loads may affect timing;
timeout timing can move naturally but reported bounds and partial results must
remain sound under original semantics.

No cache-miss profile or memory-stall bottleneck is established. Prefetch can
increase traffic or arrive too late. Installed codegen must establish a real
instruction before48 timing; source modification is not emitted-code proof.
The routine's null empty-vector pointer arithmetic is inherited unchanged;
this patch does not claim to repair every unrelated baseline UB.

Required future checks: identical full watch/trail/reason/assignment/clause
snapshots and returns for baseline/candidate; current true, next true/false/
undefined, last/empty watcher, relocated/retained prefixes, hard/soft exits,
lazy-deleted adjacent watches and GC followed by propagation. Original crash
opt5 and adjacent81, full scientific corpus and crossrepo must pass on freshly
authenticated corrected source binaries. No baseline old245 binary reuse.
All executable checks NOT_RUN. No host assignment, performance result or
adoption claim. GCC reference: https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html
