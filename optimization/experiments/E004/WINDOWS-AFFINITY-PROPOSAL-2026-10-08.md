# H-007: Windows fixed-core resource-window setup and Tier 1 check

User requests proceeding with this Windows machine's controlled-window setup.
Same LTO-only candidate, prior GCC14.4/Cygwin binaries, immutable156-file payload
and prior Tier0 PASS verified before use. No rebuild or second optimization.
DistQLDPC downstream MaxCDCL patches remain intact; no NOTICE/MODIFICATIONS change.

Bounded setup/check: native Windows APIs read physical-core/SMT topology and
per-logical-CPU performance accounting; sample five seconds and choose the pair
with the highest minimum idle percentage. Temporarily pin only our benchmark
controller/children to one logical CPU; validate inheritance with a short
existing timeout smoke and observe owned descendants' affinity. Temporarily
inhibit automatic system sleep and restore on normal/error exit. Keep the same
Balanced power scheme, Normal process priority and current system configuration.
No administrator installation, changes to other workloads or exclusive claim.

A strict reusable launcher requires both selected threads at least95% idle
before each run and the unused sibling at least95% during running. Current
five-second check found no95%-idle pair despite substantial global spare capacity.
Under the user's standing instruction to keep progressing despite inconclusive
control, the first run explicitly allows contention as telemetry; it is a pinned
desktop diagnostic, not a successful exclusive-resource window.

Tier1 cases BB90/GB144_12_8/BB108/LP238, OFF and MTO, three repeats each
baseline/candidate, ABBAAB ordering.48 serial solves;180s internal/195s external
per run, expected a few minutes based on prior same-host runs; no heavy Tier3
suite. Global idle >50%, one CPU <=half spare capacity enforced before/every2s.
Scientific mismatch/invalid bound/output/crash rejects and stops immediately;
external/resource abort stops, preserves output, no silent retry. Do not kill
unrelated processes to manufacture control.

Retain exact commands, source/binary/runtime hashes, per-case medians, sample
spread and per-core telemetry. Existing noise gate unchanged. Full correctness
does not establish reproducible speedup or controlled dedicated-server acceptance.
Separate these pinned timings from prior unpinned Windows and all Linux rounds.

Before attempt02: attempt01 stopped after19 scientifically correct completions.
Its added post-completion sample covered only~27ms and reported46.875% idle;
the immediately preceding broader sample was71.618%. Keep the entire stopped
attempt; do not count it as a complete48-run round or a scientific crash. Fix
the monitor to the preregistered complete two-second guard cadence, separately
sampling owned-child affinity every250ms; do not use a sub-tick tail as the
capacity gate. Guard threshold remains >50%; no solver/timeout/input change.
Attempt02 is one fresh full round, not pooling or selecting favorable samples.

Before attempt03: attempt02 stopped during BB108 OFF repeat2 after26 exact
completions because an owned descendant had a different affinity mask. Its
raw harness labeled this assertion REJECTED; scientifically this is a setup
failure and INCONCLUSIVE, not an LTO semantic/performance rejection. The owned
process tree was terminated successfully; original affinity/sleep request restored.
Do not overwrite its original result or pool its samples. Replace mere inherited
affinity with an unnamed Windows Job Object JOB_OBJECT_LIMIT_AFFINITY enclosing
only this controller and its descendants; no breakaway, no other workload changes.
Two one-second probes validate child affinity, normal timeout and job-limit
release. Attempt03 is one fresh full round using this verified setup. Any setup
failure is now classified as runtime INCONCLUSIVE, not scientific REJECTED.
Microsoft reference: https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_basic_limit_information
