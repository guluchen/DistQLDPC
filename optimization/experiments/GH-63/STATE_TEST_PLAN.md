# GH63 finite state fixture prerecord — source only

Before adding test code: compile the same test separately against the frozen
baseline and candidate with original Make/O3 objects, under a named host slot.
The fixture invokes actual protected computeLBD through a test-only subclass;
no production test hooks or algorithm changes. A second Solver subclass executes
the exact original loop as an independently retained reference. Both real
vec<Lit> and allocated Clause containers are exercised, including empty/unit
generic cases. No artificial wrapper codegen is treated as production evidence.

Use six counter seeds (0,1,17,UINT64_MAX-2,-1,max), four complete stamp patterns,
all36 level pairs0..5, four literal sign patterns, two actual containers and a
six-call size sequence2,0,1,4,2,1: 41,472 actual calls. Start with size2 so the
max-counter seed reaches wrap in the selected branch itself, and initial
next-counter stamp patterns directly exercise its suppressed writes.
Compare return, counter,
every seen2 entry, level data and input literals after every call. Interleave a
test-only marker write sequence on both states, then compare again; this checks
shared marker state persistence, not actual binRes clause entailment coverage.
It does not establish legal weighted/current-bound caller lifecycle correctness;
mandatory full solver science/regression gates remain separate and required.

Assertions stay active in test code even when original objects use DNDEBUG.
Any mismatch exits1 with a bounded label; successful terminal reports the exact
call count. No solver search or elapsed performance inference. This plan is
recorded before fixture implementation. No compile or execution yet.
