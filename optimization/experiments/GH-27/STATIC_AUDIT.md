# Static audit — UNEXECUTED

Preregistration11d7dd906a6c617d188f3a3e792cd3e7d1c39fd1 predates this source patch.
Independent baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a; no other experimental code is present.
Hub reread after registration identifies GH22 as current Windows owner6064232111;
GH21 is queued for exploratory Tier2. GH26 cap2-FLA is distinct from GH27.
No local builds, fixtures, solvers, diagnostics or timing have run for GH27.

The original prefix through trail.push_ is transferred verbatim from Solver.cc
to an inline Solver.h definition (only transferred line endings match that header).
The original auxiVar/soft-false guard executes after exactly those same writes.
If false, the original return true is retained. If true, control enters the
ordinary helper, whose original inner body and return true are unchanged.
The original unlocked-soft branch still returns false after assignment/trail;
locked branches retain their indexes, decrement, push, zero-lock check and
core/heap iteration order. No canonical-root equality is assumed beyond original assertions.
All four original call sites and the CRef_Undef default remain unchanged.
Helper is a nonvirtual member; no new state/data member, allocation or heuristic.
GNU-compatible builds force the declared-inline prefix; fallback is standard inline.
Actual debug/release compilation and generated-code inspection are still required.

Source edits start from exact baseline Git blob bytes. Solver.cc baseline is CRLF;
Solver.h/MODIFICATIONS/NOTICE baseline is LF. Unchanged lines retain their original bytes.
The first edit helper stopped on its header line-ending assertion, before staging;
it was repaired to honor each original file's line endings and rerun from baseline.
This was source preparation, no build/test attempt or scientific result.
Upstream notices are preserved; downstream patch documentation describes this unadopted experiment.

Prepared fixture test_enqueue_prefix.cc exercises240 combinations:
hard/satisfied-soft/falsified-NON/falsified-zero-lock/lock1/lock2;
both literal signs; decision depths0/1/2; explicit real allocated reason versus default;
direct/aliased incoming core representative; empty/two-member core lists for unlocked
cases, two-member lists for locked cases (do not invent empty locked cores).
Core lists contain repeated undefined aux, assigned aux and an existing heap entry.
Calls actual production method and compares state/returns/heap ordering via original/candidate
traces, plus outcome assertions. This does not establish pipeline-level correctness;
GC/propagation/tiny MaxSAT/CSS/WCNF/original smoke/timeouts and cross-repo remain required.
Fixture source is UNCOMPILED/UNRUN, not a PASS or proof that synthetic states fully cover real lifetimes.
