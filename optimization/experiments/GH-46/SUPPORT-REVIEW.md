# Prepared validation package; execution disabled

Preregistered before support implementation: acd46e7. Production source remains
51509debe2e09a44bc3accdaf1b1857a6c30e53f. No compiler flag or other production
source changed while preparing these tests.

`windows_assigned_runner.py` has an unassigned URL placeholder and refuses to run.
Its `--candidate-sha` argument refers to the actual frozen support HEAD, while its
separate PRODUCTION constant pins the unchanged selected source. Root review and
a named assignment precede replacing that URL and publishing the new support SHA.

The prepared scope is clean serial original-GCC builds of baseline/candidate,
all-five-mode CSS/WCNF/smoke/timeout checks, original standalone Main oracles,
separate observer snapshots and twelve new exhaustive PMS oracles, relevant
lookahead/reset state comparisons, and 4097 actual-Vec prediction checks. Original
Main stays in its actual BOTH default; mode selection is exercised via the actual
application CLI. Only after these pass: four baseline-only allocation diagnostics,
LP34/LP136 OFF/MTO, internal 110 / external 120 seconds each. No performance tier,
sweep, seed/threshold manipulation, heuristic correction, or automatic queue.

The same disclosed test-only unsupported `memUsedPeak` statistic shim is linked
only into both standalone oracle binaries. Production application builds and
Makefiles have no shim or observer. Observer Main additionally reports counters
immediately before its original NDEBUG exit expression, preserving that expression
and return/status relationship. Application Solver destruction occurs before its
worker `_exit`, so it reports the genuine final counters normally. Periodic rows
are explicitly incomplete, and only final rows count as complete observations.

Source preparation was actually performed for both variants, without compilation,
in workspace `independent-brain-records/GH46-static-{baseline,candidate}-observer-03`.
The resulting Solver.cc pair differs only in the selected local-versus-reused
declaration/clear; Solver.h differs only by the selected scratch member. Vec/Main
and observer helpers are identical. Earlier static snapshots 01/02 predate the final
report/coverage support and are superseded, not runtime evidence.

Eight Python files passed AST parsing. Helper bytes remain exactly reviewed SHA
ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2.
Runtime inventory is an unmodified copy of GH38's already published original E004
snapshot, SHA 9cc9c3db6dc0d72dbd90597058e165ee933affa6c9288a5abf7d804faed33db4.
This gate checks 10,216 original files, not the Clang overlay. No package download
or installation is required.

The supervisor pins support before imports, enforces the original one-CPU Job and
fresh/active capacity guard, distinguishes native DLL PATH from POSIX make PATH,
has per-command/aggregate/output bounds, rechecks owned Job membership immediately
before PID cleanup, preserves scientific REJECT through cleanup failures, validates
final identities, and requires all four restorations plus no owned descendants.
Actual process absence still needs an independent successful post-exit check.

These are source-preparation findings. C++ API validity, fixture coverage, original
runtime equality now, science, allocation counts and cleanup are UNTESTED until the
assigned execution; no runtime correctness or optimization benefit is claimed.
