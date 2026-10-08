# H-007 Windows resource-window setup: completed

2026-10-08. [Preregistered scope](WINDOWS-AFFINITY-PROPOSAL-2026-10-08.md).
Decision INCONCLUSIVE; local numerical filter REJECT (BB108 MTO disjoint
sample ranges), controlled performance unresolved. Candidate not adopted/merged.
No new optimization: same LTO-only baseline24572d6/candidate5b13a2c,
GCC14.4/Cygwin verified against previous identical binaries/runtime/156 payloads;
prior Tier0 PASS reused after identity checks. DistQLDPC downstream MaxCDCL
patches and scientific semantics unchanged; NOTICE/MODIFICATIONS unchanged.

## Setup and verification

8 physical/16 logical CPUs, kernel-reported SMT pairs0/1 through14/15.
Final setup uses an unnamed Windows Job Object with job-wide affinity and no
breakaway flags, enclosing only this benchmark controller/descendants. One CPU
used (14, sibling15). No exclusive reservation or changes to other workloads.
Balanced power scheme retained; temporary system-sleep requirement and job
limits/process affinity restored on completion/error. Native API sampling,
owned parent/child affinity checks every250ms; capacity check every2s, before
runs, with idle>50%/one CPU<=half spare. Strict launcher additionally requires
initial/preflight pair and active sibling>=95% idle. These thresholds are
practical eligibility checks, not a scientific noise definition.

Two probe rounds: baseline/candidate one-second BB108 timeout each, UNKNOWN
and sound partial bounds, parent/fork child affinity verified and cleanup PASS.
Final48-run Tier1 round (four cases/two modes/three repeats each, ABBAAB), all
exact expected distance/objective/bounds, no scientific mismatch/crash/timeout
or resource abort; scientific/affinity independent audit PASS. Normal settings
restored, job affinity cleared, original mask65535 restored. No local Tier2/3
rerun in this follow-up; earlier Linux pilot and Windows LP340 remain separate.

## Preserved failures

Attempt01: 19 correct completions, stopped by a~27ms
post-completion tail reporting46.875% idle; preceding broader sample71.618%.
Stopped evidence retained. Fixed monitor to complete2s resource checks;
sub-tick tails no longer decide capacity. Guard threshold unchanged.

Attempt02: 26 correct completions, then descendant-affinity
mismatch during BB108 OFF repeat2. Owned parent/child tree terminated successfully,
settings restored. Raw driver reported REJECTED because affinity was an assertion;
this is a setup failure, not a scientific rejection of LTO. Original result is
retained unchanged; independent disposition INCONCLUSIVE. No offending-mask
trace was saved by that old assertion, so do not infer its numerical value.
New Job Object setup prevents widening affinity, and setup failures now use
runtime INCONCLUSIVE classification. No pooling of these partial attempts.

## Complete attempt03 timing evidence

| Case | Mode | Baseline median s | LTO median s | LTO/baseline |
| --- | --- | ---: | ---: | ---: |
| BB_90_8_10 | no-card | 2.907848900 | 2.914435700 | 1.002265180 |
| GB_144_12_8 | no-card | 1.198532200 | 1.212210100 | 1.011412209 |
| BB_108_8_10 | no-card | 3.465239500 | 3.471595300 | 1.001834159 |
| LP_238_44_6 | no-card | 2.414792500 | 2.357906200 | 0.976442572 |
| BB_90_8_10 | card-mto | 3.510486700 | 3.491085400 | 0.994473330 |
| GB_144_12_8 | card-mto | 1.490782500 | 1.503144200 | 1.008292088 |
| BB_108_8_10 | card-mto | 4.409726200 | 4.660967100 | 1.056974263 |
| LP_238_44_6 | card-mto | 2.870323900 | 2.807871200 | 0.978241933 |

OFF geometric median ratio 0.997903036;
MTO 1.009072910. Both noise envelopes>1;
BB108 MTO median+5.697%, candidate min4.5166s>baseline max4.4722s. Preserve this
negative observation, do not cherry-pick earlier favorable rounds or claim
portable rejection/speedup on an unreserved desktop. Numerical filter REJECT;
scientific performance decision INCONCLUSIVE. No further performance tier from
this local negative round. User's uncertainty override does not erase regressions.

90 resource observations, minimum global idle
65.839041%, 55 contention observations.
No pair met95%-idle preflight initially; explicitly allowed contention for this
setup-validation diagnostic. Therefore the fixed-core setup works, but a
low-interference resource window was not achieved in this occupied session.

## Emulator observation and next action

Direct read of two dnplayer and two Ld9BoxHeadless process masks allowed all
CPUs0-15. All331 observed threads also had full mask65535. This snapshot does
not prove permanent behavior, but does not support the assumption they are
currently pinned to separate fixed cores. Earlier2s activity sample (attempt02)
observed4.96875 CPU-seconds combined from the two headless processes; this is
active background work, not proof of which core/search-time difference it caused.
No emulator was closed or moved. If user pauses/exits CPU-heavy applications,
run the [strict launcher/instructions](WINDOWS-WINDOW-GUIDE.md) and inspect
actual eligibility/telemetry rather than assuming a quiet machine. New proposals
remain alternatives, not an automatic queue.

## Reproduction and retained data

Executed command:

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E004/run_windows_affinity_tier1.py --prior E004-windows-tier2-02 --cygwin-root E004-windows-runtime/cygwin --output E004-windows-affinity-tier1-03 --allow-core-contention
```

[Attempt03 raw evidence](raw/windows-affinity-tier1-03): exact commands/raw timings,
stdout/stderr, affinity/process/core telemetry, environment, executed driver/helper,
restoration and independent audit. All medians derive only from these48 samples.
[Attempt01](raw/windows-affinity-tier1-01), [attempt02](raw/windows-affinity-tier1-02),
[probe01](raw/windows-affinity-probe-01), [probe02](raw/windows-affinity-probe-02)
and partial correctness/disposition audit retained. Candidate source/binary hashes
remain the same as the earlier Windows record. Recompute complete audit using:

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E004/audit_windows_affinity.py E004-windows-affinity-tier1-03 --prior E004-windows-tier2-02 --probe E004-windows-affinity-probe-02
```

Files added: window/Job Object helper, owned-process probe, fixed-core Tier1
driver, audit, strict PowerShell launcher, guide, proposal/result/raw evidence.
STATE/HYPOTHESES/E004 index updated. No solver/input/timeout performance change.
