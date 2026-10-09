# GH64 observer engineering repair prerecord

2026-10-09. [Public prerecord before implementation](https://github.com/guluchen/DistQLDPC/issues/64#issuecomment-6077428127).
This amends only measurement-tool validation for the same GH64 guarded-prefetch
candidate. The original native scientific Tier 1 prerecord, candidate/baseline,
numeric judge, results, sample order and acceptance gates are unchanged.

The prior acquired validation completed four short scenarios, but a fifth local
three-second window expired before launch. Its total driver elapsed56.7215sec
was below60sec. Recorded natural exit brackets were about0.69sec. Source shows
a complete process-tree scan between successive direct-child reaps, suggesting
avoidable observer delay; no counterfactual improvement has been measured.
Each separate test Guard also overwrote the shared resource file; retain each
scenario's own telemetry in the repaired test driver instead of reconstructing
missing old data. Preserve the incomplete original attempt and original bytes.

Exact authorized engineering scope:

- Remove only the redundant `self.owned()` call from the hot no-reap polling
  loop. Each reap still authenticates the direct child's birth, UID, group,
  session, affinity and cgroup. Retain full ownership scans before launch,
  before signals, throughout cleanup and in restoration proofs.
- Keep all seven validation concepts. The remaining-budget scenario uses an
  eight-second local window, twenty-second nominal cap and thirty-second sleep,
  exercising the same effective `min(nominal, remaining)` after real preflight.
  Other scenario thresholds and the original output cap stay unchanged.
- Retain per-scenario resource arrays in separate files, including error paths.
- Engineering aggregate:120sec driver,126sec controller, original TERM3/KILL5
  owned cleanup. Completion is not guaranteed; partial outcomes remain failures
  of validation, not a seven-scenario PASS.
- Use a new source and output namespace; reset assignment/runtime/review
  sentinels until independent source review and root literal freeze.

No OS identity or resource-usage mocks, omitted scenario, smaller output cap,
solver workload, new optimization, changed scientific timeout, or favorable
performance retry is introduced. Original `wait4` kernel status/rusage,
conservative lower/upper exit timestamps, science-first result validation and
separate actual release proof remain required. Validate repaired observer and
all seven scenarios plus release before collecting scientific samples.

Cost: at most the new engineering aggregate plus bounded cleanup and raw
retention; the output-cap case still produces about65MiB public repetitive
bytes. Research literature: not applicable; this is measurement engineering.
