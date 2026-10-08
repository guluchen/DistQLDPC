# User-requested benchmark priority setup and LP340 continuation

2026-10-08 before probes/performance. User requests raising our program's
priority. Use AboveNormal(0x8000) on the entire owned benchmark controller/solver
process tree via the existing unnamed Windows Job Object. Both baseline and LTO
get identical priority; original priority restored after clearing job limits.
No realtime/high setting, unrelated process priority change or solver code change.
Emulator CPU0--13 user-authorized restriction remains; this setting does not
guarantee14/15 exclusivity or alter strict idle/sibling eligibility thresholds.

Initial ephemeral owned-job check confirms AboveNormal and successful restoration
to Normal(0x20), original affinity and sleep request. Next validate actual Cygwin
parent/fork-child priority/affinity with two one-second BB108 timeout probes,
retain UNKNOWN/sound bounds and cleanup. If probes pass and strict pair qualifies,
continue the already-authorized LP340 Tier2 as one fresh round using the existing
12-run/ABBAAB/600s internal615s watchdog/>50% idle/half-spare/95% pair+SMT rules
and30s preflight waits. Stop on active resource/window failure; do not rerun or
weaken thresholds silently. Expected12--15 minutes, at most120 solver minutes.
No automatic Tier3 launch. Same immutable GCC14.4/Cygwin source/binary/package
and prior Tier0 identities rechecked, exactly the unchanged LTO-only hypothesis.

Priority is measurement configuration applied equally, not a second candidate
optimization. Keep Normal-priority historical rounds separate. A fresh strict
eligibility check is still needed; higher priority cannot make an idle preflight
out of active sibling work. Correctness mismatches immediately reject; incomplete
or noisy timing remains INCONCLUSIVE. Attribution/scientific semantics unchanged.

Microsoft: [job priority class](https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_basic_limit_information),
[scheduling priorities](https://learn.microsoft.com/en-us/windows/win32/procthread/scheduling-priorities).
