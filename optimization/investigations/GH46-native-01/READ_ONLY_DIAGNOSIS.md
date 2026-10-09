# Finite source diagnosis: exact cause remains unestablished

Original solver sources were rechecked against immutable baseline24572d6;
`git diff 24572d6 -- src/solver` in GH41-MTO-WITNESS is empty. This investigation
does not use that branch's changed application source as a baseline.
No solver execution, rebuild, repair or candidate test follows from this review.

Authenticated Windows original-baseline output ends after UB=1 fails, with
zero conflicts, no core/tier2/local learnt clauses, one harden invocation and
13 variables fixed by hardening. These are counters, not a backtrace. Native
stdout/stderr are empty: buffered output cannot establish its last reached line.

Two configuration facts constrain possible diagnoses:

1. The exact standalone Main invocation supplies only `-verb=1` and the input.
   Solver.cc defaults phase-saving to2 (line132), initializes phase_saving from
   that option (line159), and no source assignment changes it. In
   cancelUntilBeginning, line5166 uses C++ short-circuit evaluation:
   `phase_saving > 1 || (phase_saving == 1) && c > trail_lim.last()`.
   At the intended default2, the first expression is true, so trail_lim.last()
   is not evaluated. Source inspection therefore does not justify an empty
   trail_lim fix as the explanation of this exact run. This is conditional on
   uncorrupted runtime state; it does not exclude earlier memory corruption.
2. Solver.cc initializes bounds_pipe_w to-1 (line248); standalone Main never
   calls setBoundsPipe. emitBoundsUpdate returns immediately for a negative
   descriptor (line5196). The application does configure pipes, but that is a
   different executable/call path. There is no evidence supporting a bounds-pipe
   write failure as the cause of this standalone reproduction.

After UB1 failure, source order is cancelUntilBeginning (6752), bound update,
removeLearntClauses (6764), rebuildOrderHeap (6765), then the next iteration.
No retained evidence distinguishes a fault in this transition from a later
search fault. Zero learnt-clause counters do not prove all deletion/GC lists
empty, and hardening counters do not identify a faulty instruction.

Conclusion: finite read-only source investigation cannot establish the cause.
No stack/core is retained. A separately approved bounded original-baseline
backtrace investigation would provide the next useful evidence; a diagnostic
build, repair or new baseline would require its own provenance and validation.
No optimization correctness/performance promotion may bypass this known valid
fixture. User scientific-anomaly direction remains pending.
