# H-007 advancement: fill the Windows Tier 1 case gap

2026-10-08, before executions. User asks to advance H-007. Current yfclab2
read-only observations show 75.897/75.991/75.505% global idle, CPU102 100% idle,
CPU230 0% idle in three five-second windows. No active lease/partition; occupied
host (24 users, load average 61.85/62.54/63.30). No controlled reservation is
inferred. No root-helper scope expansion, workload termination or Tier 3.

Windows fallback already has verified Tier 0 and twelve LP340 diagnostic solves,
but no complete four-case Windows Tier 1. Perform exactly one 48-run diagnostic
to fill this coverage gap, not a repeated attempt to obtain favorable timing.
Hypothesis and implementation remain H-007 LTO only. Reuse the unchanged binaries
from E004-windows-tier2-02, baseline 24572d6 and candidate 5b13a2c, no rebuild or
stacked optimization. Verify 156 package payload hashes, binary identities and
prior Tier 0 PASS first. Keep compiler/runtime identities with the new evidence.

Cases BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6; modes OFF/MTO separate,
three baseline and candidate repetitions in AB/BA/AB order. 180s internal wall
limit, 195s external watchdog, one solver at a time. Native spare-capacity guard
>50%, one worker <= half spare, checked before/through execution. Stop and retain
the first mismatch, crash, timeout or resource interruption; no automatic retry.
Expected distances are checker-only. No scientific, timeout or result changes.

Use original preregistered numerical Tier 1 filter: nonoverlapping per-case
regression rejects the numerical diagnostic; otherwise all medians must be no
worse and both mode geometric means of max(candidate)/min(baseline) below 1.
Also report every median/range and both mode median geometric means even if an
early numerical rejection prevents the original judge from reporting all cases.
Desktop timing remains diagnostic; numerical pass does not establish controlled
promotion. Existing Linux Tier 1 and Windows Tier 2 evidence remain separate.

Expected cost a few minutes given prior short cases; worst-case total solver
budget 144 minutes, stopping at first incomplete solve. This is not a parameter
sweep or whole benchmark suite. Whole-host control is still needed to resolve
formal acceptance; do not falsely attest exclusive-host status to the server
runner. If evidence remains inconclusive, retain exact controlled-run commands
and explicitly state the missing reservation/stability requirement.
