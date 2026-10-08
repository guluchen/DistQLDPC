# User-authorized emulator affinity partition

2026-10-08. User explicitly asks Codex to apply the described Task Manager
restriction: emulator CPU0--13, leave physical-core SMT pair14/15 for experiments.
This supersedes the earlier setup scope that changed only the benchmark process
tree. Applied through the equivalent native process-affinity property; no other
programs or persistent Windows configuration changed, no emulator closed.

Four observed processes changed from mask65535 (CPU0--15) to16383 (CPU0--13):
dnplayer PIDs4220/12556, Ld9BoxHeadless12532/17828. Original PID/name/start-time/
mask backed up before mutation to workspace E004-emulator-affinity-backup-01.json.
Each setter verified immediately; a later reread confirmed all four still16383.
Does not establish permanent restrictions on restarted/new emulator instances,
Windows exclusivity, or freedom from shared-cache/power/memory interference.

Initial two5s samples: pair14/15 idle96.875/93.125%, then96.875/94.6875%.
Later5s sample91.5625/96.875%. No sample qualified both threads>=95%.
Affinity restriction verified, but a strict eligible window was not established.
No LP340 solver launched/timing samples, no threshold weakening or scientific
accept/reject inference. E004 Tier2 performance remains INCONCLUSIVE from the
initial environment refusal; candidate LTO diff and semantics unchanged.

Original settings remain recoverable. Restore helper checks PID, process name
and exact start time before touching an instance, skipping exited/reused PIDs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\DistQLDPC\optimization\experiments\E004\restore_emulator_affinity.ps1
```

Helper syntax check PASS; restoration deliberately not executed because the
user requested the restriction to remain in effect. Benchmark-only job/sleep
cleanup is separate and does not automatically undo emulator settings.
Do not attribute remaining activity on14/15 to a specific background process
without measurement. Strict LP340 continuation remains authorized when a
qualifying window is observed; no unrelated workload mutation or diagnostic
mode switch inferred from this emulator-affinity request.

[Raw backup/verification/resource samples](raw/windows-emulator-affinity-01)
preserved. No DistQLDPC application/MaxCDCL engine changes or NOTICE/MODIFICATIONS
update required. Files added: restore helper, setup record/raw data; STATE/E004
index updated. Original LTO-only performance experiment remains separate.
