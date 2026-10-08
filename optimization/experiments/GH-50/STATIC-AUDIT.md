# GH50 static equivalence scope

Source baseline24572d6; prerecordd9ec8bc precedes implementation.
Only propagateForLK binary loop changed: compute one const lbool after existing
imp extraction; use it in both original comparisons. The two original if blocks,
binConfl writes/return, enqueue call and soft-failure falseVar/return unchanged.

Original inline value(Lit) reads assigns[var(p)] XOR sign(p). Before the second
comparison, the first comparison either exits immediately (false) or performs
no assignment/call/mutation. Hence the second evaluation sees the same state.
On undefined, enqueue occurs only AFTER the second comparison; the cached value
is unused afterwards and fresh on next watcher. True skips both blocks exactly.
No const-folding/volatile/concurrency assumptions introduced: original assigns
has ordinary Solver-local storage and original value is const/nonvolatile.
No source change to ordinary/simple propagation, helper bodies, watch cleanup,
long clauses, activities/cores/bounds/timeout/output/compiler/allocators.

Original source CRLF retained outside byte patch. Existing copyright/header bytes
unchanged; MODIFICATIONS/NOTICE separately document downstream experiment.
Static reasoning is not actual GCC codegen or complete scientific acceptance.
Known GH46 valid baseline anomaly remains visible and blocks silent certification.
Installed GCC may already CSE; require original-codegen mechanism evidence before
performance. No compiler/solver/test/diagnostic/disassembly executed.
