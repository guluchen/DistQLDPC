# GH-20 static audit and prepared checks

No local compilation, test or diagnostic execution. Host slot NONE; Windows
remains reserved for GH16. This record is source inspection, not Tier0 PASS.

Only two suffix loops inside propagateForLK change. i and j initially identify
the same watch-array element; movement only advances i, so j<=i. A tail copy
starts after the conflicting watch has been retained. If i==j, every original
assignment has identical source/destination; after the loop both pointers equal
end. Watcher consists of integer CRef and Lit, whose only data is integer x;
neither has a custom assignment or volatile field. Therefore direct i=j=end
preserves fields, final shrink count and loop termination. For i!=j the complete
original loop remains. qhead, return, falseVar and counters stay at their exact
original locations. No callbacks, allocations, GC or output occur in the skipped
tail. This is a static argument, not proof that our compiled candidate is sound.

The prepared subclass fixture uses protected production setup/inspection, no
production test hooks or copied propagation algorithm. It invokes the original
and candidate propagateForLK and traces every live long/binary watch, assignment,
reason/level, trail/qhead, returned conflict, falseVar, flags, counter, clause
literals and circular-scan position. 120 scenarios cover hard/soft exits,
zero/one/two moved prefix watches, retained blocker prefix, lazy deletion and
tail lengths0/1/2/7/23. Separate assertions check expected return, soft implication,
tail count/order, moved destination and propagation count.

Setup deliberately initializes lk_propagations, normally initialized by solve,
and uses valid independently allocated long clauses with lastPoint=2. It does
not claim to exercise garbage relocation. Add/verify actual relocation and tiny
exact scientific/timeout checks in the assigned Tier0 run, plus hosted cross-repo.
No performance conclusion from fixture output size or correctness.

Before timings, separately count actual identity-tail occurrences/store lengths
on an instrumented immutable baseline and inspect ordinary O3 code generation;
compiler elimination and negligible tails remain possible. Instrumented timings
are not performance evidence. No diagnostics/profiles from other methods reused
as a measured GH20 benefit. Candidate/default compiler flags remain unchanged.
