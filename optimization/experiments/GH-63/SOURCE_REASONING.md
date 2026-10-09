# GH63 source reasoning — UNCOMPILED / UNTESTED

Baseline source B002/72d1fe18, not a certified executable. Prerecord commit
45817d3 precedes the production header edit. Exactly one concept: expand the
two iterations of `computeLBD` only when its actual container size is two.

Actual call containers are `vec<Lit>` and `Clause`; their `size` and indexing
read the stored length/literal, with no solver mutation. `level(var(lit))` reads
the existing variable data. Both expanded bodies retain the original condition
and conditional stamp assignment/increment. Index0 executes before index1.
There is one original `counter++` before dispatch, and the other-size generic
loop is unchanged. No survivor ordering, backtrack, LBD threshold, cleanup,
heuristic, clauses, objective, bounds or representation is altered.

Equal nonzero levels illustrate why the second stamp test cannot be omitted:
the first write makes the second test false. Zero levels must not access a
stamp. Preexisting stamps can equal the newly incremented counter, including
uint64 wrap to zero; the original behavior, even in those corner cases, must
remain identical. `seen2` also marks variables for binary minimization, so
comparing only the returned LBD is insufficient. No old wrap behavior is fixed
or assumed impossible in this experiment.

Tier0 needs actual compiled `vec<Lit>` and `Clause` instantiations, whole-array
stamp/counter/return equality and later consumers across repeated mixed sizes.
This note is a source argument, not that execution proof or universal solver
correctness certification. Keep all mandatory corrected-baseline regressions,
PMS/CSS/cardinality/WCNF/bounds/status/timeout and cross-repo gates.

The hypothesized improvement is removal of loop-control work. The compiler may
already remove it; the added dispatch may regress larger clauses. Inspect
actual production call-site codegen and separately observed size2-call counts
before timing. Artificial wrappers or source line counts alone are insufficient.
No profiling, compilation, solver, timing or speed result exists for GH63 yet.

Original Git header bytes use LF; the Windows checkout initially expanded them
to CRLF. The edited header was written with the original LF bytes, and removing
only the 17-line expansion reconstructs the original Git blob exactly. No
upstream attribution/header changes or prior experimental patch is included.
General program optimization; no paper-derived method or invented BibTeX.
