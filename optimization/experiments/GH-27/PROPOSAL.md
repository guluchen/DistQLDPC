# GH-27 — independent Brain round 2

Issue: https://github.com/guluchen/DistQLDPC/issues/27

Coordination hub #15; owner/session `review-brain-20261009-round2`. Immutable baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`. Status PROPOSED / UNTESTED; source/metadata work only, no host assignment. Independent of GH16 PGO, GH20 tail skipping, GH21 O2 and GH22 symmetric VSIDS.

DistQLDPC embeds a downstream MaxCDCL-derived solver with its own instrumentation/optimizations; QDistSAT is the separate benchmark platform. Preserve attribution, scientific/CSS/Pauli/logical-operator semantics, bounds, output and timeout semantics.

## Fresh three-proposal round

### A — inline the lookahead enqueue prefix, outline soft-violation handling (rank 1, SELECTED)
One performance concept: split `Solver::uncheckedEnqueueForLK` into a small always-inline assignment/trail prefix and an ordinary out-of-line helper containing the ORIGINAL soft-violation handling. The prefix retains assertion, Var extraction, assigns update, reason, decisionLevel()+1, trail.push_ and the SAME auxiVar/soft-literal-false guard in the SAME order. Only guarded soft violation invokes the helper; unchanged helper returns false for an unlocked soft variable, otherwise performs original core-lock decrement, unLockedVars push, zero-lock heap insertions, and returns true.

Implement GNU always_inline on the declared-inline prefix (standard inline fallback outside GNU-compatible compilers); no cold/noinline attribute, branch hint, other inlining, whole-program flag, allocator/data-layout, lookup caching or heuristic change. Other enqueue/ordinary/simple propagators unchanged. Default/explicit CRef semantics and all four existing call sites remain unchanged. Ordinary compilers may still choose to inline the slow helper; do not assert otherwise without assembly evidence.

Opportunity: GH16 fixed LP34/LP136 OFF/MTO training coverage reports 2,997,305 uncheckedEnqueueForLK entries, versus 345,993 propagateForLK calls. These are specific training execution counts, NOT time-share, Tier1 evidence or a speedup prediction. GH20 retained actual default-O3 baseline assembly contains two calls to the out-of-line function in propagateForLK. Splitting aims to remove frequent call boundaries without duplicating the entire locking/core iteration body. Actual soft-violation frequency and code size are still unmeasured.

Expected affected cases: workloads dominated by lookahead enqueues whose soft-false guard is not entered; no predicted family gain or percentage. Prerequisite bounded pinned-baseline diagnostics count total enqueue entries versus soft-false unlocked/locked paths on four fixed LP34/LP136 OFF/MTO cases,120/135s limits after assignment. Inspect actual production assembly to verify generated prefix/call placement and record code size. Diagnostics are not comparative timing. A compiler that already implements the intended prefix split, or measured absence of a meaningful fast-path opportunity, permits shelving with no speed claim.

Risks: code-size/instruction-cache growth, register pressure, inlining portability/build failures, inline ODR/linkage mistakes, subtly changing the pre-existing early return/lock mapping/state order. Assertions/debug and release configurations must compile. No new correctness assumption such as canonical-root idempotence is introduced.

Scope: Solver.h/Solver.cc and focused tests, MODIFICATIONS.md/NOTICE; no Makefile change. Engineering estimate1–2days; correctness first, no broad profile/sweeps.

### B — demand watch cleanup only during lookahead (rank 2, UNSELECTED)
Disclosed re-ranking of unselected GH17-B / GH20-C, not a novelty claim. ONE concept: propagateForLK cleans only lists it reaches through existing OccLists.lookup(p), rather than global watches/watches_bin.cleanAll(). Other propagation untouched. Existing dirty queue semantics remain unchanged.
Potential benefit requires dirty-but-unused lists; 345,993 lookahead calls alone do not prove cleaning cost. Risks: deleted CRefs, append ordering, GC relocation, deferred queue duplication/growth and other raw consumers. Existing lookup does not remove entries from the dirties queue. If safety/bounded lifetime needs a wider container redesign, withdraw this narrow proposal rather than bundle it. Expect2–3days and lifecycle tests. Not implemented.

### C — reuse representative-array lookups within locked-soft enqueue handling (rank 3, UNSELECTED)
ONE concept: retain exact original indexes but reuse repeated finalIset/inConflicts loads within the same locked-soft branch. No inlining or cross-call cache.
Original unLockedSoftVarForLK checks inConflicts[v]==NON before getIsetLock; getLockedVarIsetForLK then accesses finalIset[inConflicts[v]], and decrement/get-lock map finalIset[iset] again. Do NOT collapse the two mappings using unproved canonical-root assumptions; do NOT reuse a pre-decrement lock value for the post-decrement test. Need prove cached arrays/representatives cannot change across the intervening original operations; otherwise withdraw. Compiler may already eliminate these loads, requiring actual generated-code inspection. Smaller opportunity and greater alias/lifetime proof burden than A. Estimate1–2days plus focused state tests. Not implemented.

## Selection, prior learning and provenance
A targets millions of repeated call boundaries instead of GH20's much smaller tail-store opportunity. GH20 Tier0 passed, its standard48 Tier1 solves were scientifically identical and validly cleaned up, but ALL8 medians were slower (+1.180% OFF/+1.221% MTO geometric means); formal INCONCLUSIVE because Windows was not an exclusive controlled window, local SHELVED / NOT ADOPTED. No Tier2/3. Actual compiler retained GH20 loops, yet operation removal did not ensure a speedup. A still needs an independent filter.
GH17 caller-owned scratch had only9/328 predicted allocations,8-byte peak and no timing; GH16 PGO exploratory Tier2 did not show robust gain. GH21 O2 and GH22 VSIDS currently own/queue host slots; no conceptual overlap or stacked candidate.

All three are code-derived engineering hypotheses. No academic paper is used as origin; BibTeX NOT APPLICABLE. If later paper-derived work is proposed, retain primary paper/version/section and Bib entry before implementation.
Primary implementation reference: [GCC14.3 common function attributes](https://gcc.gnu.org/onlinedocs/gcc-14.3.0/gcc/Common-Function-Attributes.html#always_inline), read2026-10-09. GNU always_inline on declared-inline functions forces direct-call inlining and diagnoses failure; our current Windows GCC14.4 is a different minor version, so actual build/assembly must verify applicability. This documentation is not evidence of benefit.

Read repository AGENTS/README/MODIFICATIONS/NOTICE/cross-repo/policy, prior Brain/state/history, current hub and active issue bodies. Open/closed enqueue/inline searches found no selected A duplicate; closed search empty. GitHub searches can lag, so reread hub after registration; lower-number issue owns concurrent duplicates. Shared STATE/HYPOTHESES remain integrator-owned.

## Preregistration, validation and progression
Create an independent branch/worktree from baseline and commit this proposal before edits. Keep raw/** -text, explicitly retain ignored raw archives, and verify committed Git-blob hashes. Candidate/source/binary/compiler/input/parser/profile(if any) identities, exact diff and all attempts durable; no expiry-only artifacts.

Tier0: compare original/candidate protected-method fixtures for hard variables, satisfied aux soft literal, falsified unlocked and locked aux variables, locks reaching0 versus remainingpositive, core lists/undefined versus assigned literals, explicit/default reasons, nonzero decision levels, assignment/trail/reason/level/lock/heap state and return. Preserve assertions and caller-owned preconditions; do not invent unsupported states. Compare complete production traces/counters/order, actual GC relocation fixtures, tiny exact MaxSAT/CSS/WCNF, original smoke, genuine rc1 UNKNOWN timeouts and every interim/final bound. Required ordinary CI and QDistSAT cross-repo check; archive actual executed source/artifact and science. Any scientific mismatch/crash/bound/timeout/result regression => REJECT and stop, report anomaly.

Only after Tier0 and separately assigned resources: Tier1 BB90/GB144/BB108/LP238, OFF/MTO,3/version,48 serial AB/BA/AB solves180/195s using immutable exact binaries/inputs and reviewed full-science parser. Same assignedCPU/priority, capacity>50% spare/use<=half spare,2s telemetry,bounded owned-job cleanup/restoration, retain invalid attempts. Report8 medians/ranges and separate-mode geometric means; do not average away case regression. Promote only consistent overall positive direction beyond baseline variability with no material regression. All-mode negative local direction shelves; uncontrolled or overlapping evidence remains formally INCONCLUSIVE, not accepted or universal rejection. No repeat-until-favorable.
Tier2 LP34012 solves600/615 only after positive reproducible Tier1 or a distinct explicitly authorized exploratory exception; expensive runs belong on dedicated server. No Tier3 in this prerecord.
Current host slot NONE; GH21 Windows Tier1 owns hub6064121965, GH22 queued. No local build/test/diagnostic/timing until fresh RUN_ASSIGNMENT. Research/source/metadata only. Never use shared CI timing for research conclusions.
