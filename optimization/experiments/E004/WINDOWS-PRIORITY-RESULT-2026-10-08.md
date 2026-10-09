# AboveNormal setup verified; LP340 stopped on SMT-window loss

2026-10-08, [preregistered scope](WINDOWS-PRIORITY-PROPOSAL-2026-10-08.md).
User requests raising our program's scheduling priority. Added optional
`--priority-class above-normal` to the Windows LP340 driver/probe and shared
owned-job helper: priority32768 (AboveNormal), original32 (Normal). The unnamed
Windows Job Object applies the same class to controller/solver/descendants,
preventing Cygwin fork/default process creation from silently resetting class.
Both baseline and LTO tested at identical priority; no realtime/high setting,
other-program priority change or permanent Windows configuration change.
Emulator CPU0--13 restrictions from the earlier explicit request remain.

Native owned-job setup/cleanup succeeded. Baseline/candidate one-second BB108
probes both observed parent/fork child at AboveNormal and one-CPU affinity;
normal UNKNOWN/TIMEOUT with sound partial bounds. Independent probe audit PASS.
All process priority, job limit, original affinity and sleep request restored.
This is a measurement setting shared by both versions, not a second candidate
performance change. Original LTO-only candidate source/binaries unchanged;
DistQLDPC downstream MaxCDCL instrumentation/attribution and scientific semantics
unchanged; NOTICE/MODIFICATIONS require no updates.

## LP340 follow-up

Strict selection qualified CPU14/sibling15 (initial idle98.125/100%). Original
156 payload/source/binary/runtime/compiler identities and prior Tier0 PASS
rechecked. First OFF baseline started, then guard terminated its owned parent/
child tree at29.096768s. Last2s observation global idle68.286334%, sibling idle
90.070922%; sibling95% rule failed. Global>50%/half-spare capacity remained valid.
Resource kill command returned0; cleanup restored priority32, affinity65535,
sleep request and removed job limits. Independent partial audit PASS.

No completed LP340 solve, no candidate run, completed pair, median, speedup or
Tier3. Buffered killed output supplied no distance/objective/bounds; absent
values are unknown, not zero or a wrong result. This is an intentional resource
guard abort, not a scientific solver crash or a reason to reject LTO.
Decision **INCONCLUSIVE**. Full12-sample audit cannot run on this partial attempt.
All earlier unfavorable/favorable evidence and refusals remain separate.

Learning: job-wide higher priority can be applied and verified equally, but it
does not eliminate independently executing SMT/background work or certify
resource exclusivity. Cannot infer runtime benefit from one interrupted baseline.
No cause assigned to a particular background application without measurement.
Next: strict retry only when a sustainable window exists, or user explicitly
chooses a new preregistered diagnostic scope; do not silently weaken95% gate.

Exact executed command:

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E004/run_windows_affinity_tier2.py --prior E004-windows-tier2-02 --cygwin-root E004-windows-runtime/cygwin --output E004-windows-strict-tier2-02 --preflight-wait-sec 30 --priority-class above-normal
```

[Probe evidence](raw/windows-priority-probe-01) includes exact commands, original
executed probe/helper, stdout, priority/affinity/cleanup and independent audit.
[Partial Tier2 evidence](raw/windows-strict-tier2-02) contains exact command/raw
output, resource samples, all observed priorities, executed driver/helper,
owned-tree termination, environment identities, decision and partial audit.
No automatic repetition after this aborted round. The optional class defaults
to absent to preserve older driver invocations' Normal-priority configuration.

Validation: helper/driver/probe/auditor syntax checks PASS; real Cygwin parent/
child priority and affinity, timeout semantics and restoration PASS. Dedicated
complete-Tier2 auditor extended for requested priority/cleanup fields, not run
on nonexistent12 completed samples. Files changed: shared helper, Tier2 driver,
probe/audit, proposal/result/raw evidence, STATE/HYPOTHESES/E004 index. No solver
or benchmark matrix change, candidate adoption or merge.

Microsoft [scheduling priority classes](https://learn.microsoft.com/en-us/windows/win32/procthread/scheduling-priorities)
and [job-wide limits](https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_basic_limit_information)
support the implemented distinction between scheduling preference and resource
reservation.
