# Windows H-007 resource-window setup

The existing Cygwin/GCC toolchain and validated baseline/LTO binaries suffice.
No administrator install, system affinity changes, or power-plan switch needed.

1. Save/pause work and exit CPU-heavy applications if convenient. This host has
   active Ld9BoxHeadless/dnplayer emulator processes; pausing their game does not
   necessarily stop emulator CPU activity. Use their own controls. Codex does
   not terminate or move unrelated processes.
2. Pause large downloads/sync/rendering while comparing, and avoid using the
   computer until the round finishes. Keep the same power scheme throughout
   baseline/candidate runs. The current scheme is Balanced; no setting changed.
3. From this workspace run the strict launcher below. It samples physical
   topology/load and refuses if no core/SMT pair meets the initial95%-idle check.
   One full round includes the four Tier1 cases, both modes, three repeats of
   both versions in ABBAAB order. Expected a few minutes; each solve has180s
   internal timeout and195s watchdog.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\DistQLDPC\optimization\experiments\E004\start_windows_window.ps1
```

The script confines its controller and descendants to one logical CPU via an
unnamed Windows Job Object. Before a solve it can wait up to30 seconds for
the same pair to become eligible; all failed preflights are retained. No timing
sample starts until eligibility passes, and active-run checks remain strict.
Other applications remain unchanged. It checks
global idle >50%/one CPU <=half spare and preflight core/sibling idle>=95%, then
sibling>=95% every two seconds. This is a practical low-interference eligibility
check, not a scientifically universal noise threshold. During running, the
selected CPU is expected to be busy. It temporarily inhibits system sleep and
releases the job limit/restores its original process affinity and sleep request
on normal/error exit. No permanent sleep or power setting changes.

If the strict launcher refuses or stops, preserve that output. Background
workload activity is not a solver failure. Explicit `-AllowContention` permits
pinned diagnostics under the unchanged global capacity guard and records sibling
interference; such a run must not be labeled an exclusive controlled measurement.

Affinity confines our own processes; it does not prevent Windows or other
applications from sharing the same core. Even a completed strict run does not
prove exclusive resource ownership or establish a controlled dedicated-server
performance claim. Repeated result/timing audits and recorded interference are
still required. The raw directory name is printed and each invocation uses a new
timestamped output directory. Scientific mismatches/crashes stop immediately.

API support: [job-wide affinity](https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-jobobject_basic_limit_information),
[CPU topology](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlogicalprocessorinformationex),
[per-CPU accounting](https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntquerysysteminformation).
