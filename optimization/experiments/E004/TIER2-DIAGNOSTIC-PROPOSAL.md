# E004: user-requested Tier 2 diagnostic, preregistered 2026-10-07

The user explicitly clarified "LTO Tier 2: LP_340_56_8" after the Tier 1
INCONCLUSIVE report. This authorizes the additional medium-case diagnostic
despite the original gate. It does not retroactively pass Tier 1, establish a
controlled environment, authorize Tier 3, or change acceptance criteria.

One unchanged hypothesis: LTO only. Reuse original baseline 24572d6 and tested
candidate 5b13a2c binaries (final PR 2efbdc1 has identical Makefile/src/data).
Baseline SHA256 055e973e88cc0bb47dfeea236799b02c05d8f2d19b7a50a049125f9057223c0f;
candidate SHA256 9923009bb57c1f5ce5c5bfdede9af1b490f944e94f0a1731e0a85da5f0af9cca.
Reverify the 156-file package manifest, binary hashes and prior Tier 0 PASS before
running. No rebuild/source modification, new optimization or duplicated Tier 1.

LP_340_56_8 only; OFF/MTO separately. Three baseline and three candidate runs per
mode, AB/BA/AB: 12 executions total. Internal wall timeout 600s, external watchdog
615s, matching the existing controlled Tier 2 plan. Total maximum internal budget
120 minutes; stop at the first incomplete/timeout sample or capacity failure.
Retain partial outputs, exit codes, bounds and abort reason, never silently retry.

Scientific checks: complete results must have exact distance/objective/LB/UB 8,
and baseline/candidate semantic tuples must match. The benchmark's retained
expected value is a checker only and never supplied to the solver. Any incorrect
distance/bound, crash or malformed result stops/rejects; partial timeout bounds
must still contain 8, and no timeout is called an exact solve.

Use yfclab2 and one freshly observed eligible logical CPU; record its SMT sibling.
Enforce global idle >50% and allocation <= half spare capacity before and every
two seconds during active commands. Core/sibling activity is diagnostic telemetry
because CPU isolation remains deferred. No sudo, reservation claim or changes to
other users' jobs. Retain all raw timings, medians, resource observations and
environment/driver identities in a new directory, preserving the original run.

Report the same numerical range filter: min(candidate)>max(baseline) is diagnostic
regression; otherwise both modes require candidate medians no worse and
max(candidate)/min(baseline)<1 to pass beyond the observed range. Favorable small
medians or a diagnostic numerical pass alone do not promote this occupied-host
experiment. Controlled performance stays INCONCLUSIVE without controlled evidence.

Compare the observed direction with Tier 1's modest favorable medians, distinguish
timing from recorded search counters, and record learning. No Tier 3, merge,
general speedup claim or alteration of original Tier 1 conclusion.
