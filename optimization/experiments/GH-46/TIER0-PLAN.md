# Preregistered correctness and mechanism checks

This plan precedes implementation of the test instrumentation. Production remains
51509debe2e09a44bc3accdaf1b1857a6c30e53f, with one capacity-reuse change.
No build, solver, allocation diagnostic, or timing has run locally for GH46.

## Meaningful storage lifetime checks

Use separate baseline and candidate **test source snapshots**, derived from the
exact source commits. Their production binaries remain uninstrumented. A test-only
observer will trace actual calls to `Solver::lookahead()` reached by the original
standalone Main and search, rather than reproducing the algorithm in a fixture.
Both snapshots receive identical observer edits. No copied lookahead implementation,
replacement solver semantics, forced search threshold, seed change, or heuristic
fix is permitted.

Generate small unit-weight WCNF instances with exhaustive assignment oracles,
including disjoint conflicting soft pairs, implication chains, larger hard clauses,
and varying optimum/upper-bound transitions. Run the original Main in fresh
processes for each case, retaining its actual default BOTH mode (it has no mode
CLI). Test the five modes through the actual application CSS CLI instead. Compare relevant
observer output between the two builds. Each emitted optimum must equal the oracle;
original Main may return 10/SAT or 20/UNSAT according to its final failed-bound
proof. Validate the actual return/status relationship, not a fabricated SAT-only
requirement. Fresh processes preserve identical initial function-static lookahead
state without modifying that original state.

Trace all actual lookahead entries/exits and actual lookback resets. Include
assignments, reasons/levels, trail and qhead, seen/involved flags, involved literals,
unlocked variables, conflict ownership/representatives/locks, core contents,
activities, relevant heaps and flags/counters, and populated explanation literals.
Reserved UIP slot zero must be compared only when production actually assigns it;
do not read its uninitialized placeholder. Record branch coverage and require
multiple substantive calls on the same Solver with populated output and repeated
upper-bound transitions before claiming this lifetime check passed. If bounded
cases fail to exercise this mechanism, record an engineering coverage gap and stop
before timing, rather than calling an irrelevant fixture sufficient.

Explicit exclusions from trace equality: scratch capacity/address, allocator
addresses, timing/resource statistics, and unused/uninitialized storage. These
are storage observations, not scientific state. This is a relevant state trace,
not an unsupported assertion that every byte of Solver is meaningful/equal.

## Separate allocation opportunity diagnostic

Instrument only the selected lookahead vector in a separate original-baseline
snapshot. A per-Solver counter record and an RAII active-vector pointer restrict
generic Vec hooks to that exact buffer. Restore the previous pointer at every
return. Count actual growth reallocations and requested allocation bytes; observe
every push's logical size, not just baseline growth events. This is necessary:
reused capacity can lie between two baseline growth steps, so growth-event-only
simulation could miss a candidate growth inside an existing baseline capacity.

Simulate persistent capacity using the exact original Vec growth rule, resetting
logical size per call while retaining predicted capacity per Solver. Record
substantive calls, populated calls, baseline reallocations, predicted reallocations,
peak logical size/capacity, and peak retained bytes. Compare predicted versus actual
candidate growth on the bounded correctness fixtures. Emit counters separately
from scientific output and never link this support into production/timed binaries.
To avoid flooding traces, report only the first and every 512th cumulative call as
`complete:false`, and one final `complete:true` record while the Solver is live.
The application already destroys its local Solver before `_exit`; original
NDEBUG standalone Main uses `exit` without destruction, so its **test snapshot only**
adds an explicit report immediately before that unchanged exit/status expression.
A killed diagnostic's prefix is incomplete and cannot support a complete-count
conclusion. Consumers take the last record per Solver, never sum cumulative rows.

After Tier 0 passes, perform four baseline-only diagnostics: LP_34_20_2 and
LP_136_32_4, each OFF/MTO, with internal 110-second and external 120-second watchdogs.
Validate every scientific result/bound against ground truth. Instrumented wall time
is not performance evidence; allocation counts are not a time-share estimate.
If opportunity is negligible, preserve measured counts and shelve without claiming
a zero mechanism or a universal rejection of buffer reuse.

## Full Tier 0 and host gate

Clean serial GCC -O3 builds of exact baseline/candidate, default Makefile unchanged;
small CSS exhaustive-distance oracles and identical WCNF dumps with explicit modes;
unit-weight standalone Main oracles; original smoke cases; all five encoding modes;
actual supported timeout/UNKNOWN paths and every emitted LB/UB/d/objective field.
Any established scientific mismatch/crash rejects the experiment immediately.
Watchdog, resource, provenance, compilation, or coverage failures are engineering
INCONCLUSIVE until established otherwise, and do not authorize timing.

The reviewed Windows one-CPU Job guard, fresh global spare >50% and <=half-spare
constraint, active telemetry, owned-PID recheck before cleanup, bounded waits,
strict source/runtime/input/binary/helper/support pins, final identity checks,
all four restoration booleans and independently confirmed process absence are
required. Run only after a fresh named assignment. Retain all raw streams and exact
hashes. Hosted CI/cross-repository source/artifact checks are correctness evidence
only. No Tier 1 is authorized by this source-only plan.

Implementation of support adds no production flag or source concept. Fixed
GCC14's original GNU++17 default is used by the C++17 inline observer globals;
there is no language-mode override in production or test builds. A separate
4097-sequence test compares the capacity prediction against actual original Vec
push/clear behavior, including the 5->7 inter-growth boundary. This validates the
diagnostic math, not Solver correctness. `populated_calls` in the raw counters
means a call with a nonempty logical vector (including its reserved slot); actual
meaningful explanation coverage is checked independently from populated reset
slots, across at least two distinct calls on the same Solver and a UB transition.

The driver is disabled until its assignment placeholder is replaced and committed.
It retains source preparation failures, has a 3600-second aggregate limit and a
64-MiB per-stream stop without trimming raw bytes. Original-runtime inventory
9cc9c3db6dc0d72dbd90597058e165ee933affa6c9288a5abf7d804faed33db4
is retained unmodified from GH38's published original-runtime snapshot; all 10,216
original files are checked before and after through the assigned Job, including
compiler internals, GNU headers, libraries and DLLs. This experiment uses the
original E004 runtime directly, with no Clang overlay or package installation.
