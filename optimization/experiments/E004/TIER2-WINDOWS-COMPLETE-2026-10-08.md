# Windows fallback ready; E004 performance remains INCONCLUSIVE

2026-10-08. User asked to complete Windows settings and use this computer when
server resources are unavailable. Explicitly reviewed task-local Cygwin setup
completed without administrator rights, shortcuts, global PATH or power-policy
changes. i9-11900K / 16 logical CPUs / Windows 10.0.19045, GCC 14.4.0,
Cygwin 3.6.11, native Python 3.13.14. Interactive desktop, no CPU reservation or
fixed affinity; do not pool results with Linux or the older Windows host.

Same H-007 LTO hypothesis and original Windows preregistration, reaffirmed in
[setup continuation](WINDOWS-SETUP-2026-10-08.md) before builds. Baseline 24572d6,
candidate 5b13a2c, pinned QDistSAT 7c4774f, original 156-file manifest verified.
Makefile flags differ only by -flto=1 at compile/link. All 31 src and 28 selected
matrix files byte-identical; downstream MaxCDCL notices/patches unchanged.
DistQLDPC is not identical to upstream MaxCDCL; scientific semantics unchanged.

## Setup and Tier 0

[Installation logs](raw/windows-setup-2026-10-08/) and installed package versions
retained. First build under the tool sandbox failed before compilation because
its child PATH was reset: make could not find installed mkdir. No solver sample
or scientific failure. [Failed attempt](raw/windows-build-sandbox-failure/) kept.
A reviewed execution outside that PATH restriction found mkdir/g++ and used a
new output directory and fresh sources; no code/toolchain workaround.

Application builds LTO=0/1 PASS, serial make -j1 bin/distqldpc. Only this target
was built; standalone maxcdcl CLI is not newly validated. Tier 0 PASS: six
byte-identical WCNF pairs, exhaustive CSS oracle distances 2/1 in three modes,
smoke/help, pinned QDistSAT pilot LP136/BB108 in OFF/MTO with exact results and
bounds, and six parent timeout/UNKNOWN checks. All original assertions retained.

Binary SHA256:
- baseline: 22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815
- LTO: b483fe59a90201f53c7ea4a87b95aa39740f738f1f418feec3a7b4b036f5e547

## User-requested Tier 2 diagnostic

Fresh output E004-windows-tier2-02, twelve serial LP_340_56_8 runs: three per
binary/mode, AB/BA/AB, unchanged 600s internal / 615s external limits. All return
0, distance/objective/LB/UB exactly 8, no timeout/unknown/resource interruption.
Ground truth is checker-only. Independent raw-output/hash/build-flag/input audit
PASS. Native GetSystemTimes observations every two seconds and preflight enforce
>50% spare capacity and one worker <= half spare; no global resource settings.

| Mode | Baseline median s | LTO median s | LTO / baseline | Descriptive reduction | max LTO / min baseline |
| --- | ---: | ---: | ---: | ---: | ---: |
| OFF | 66.323620 | 65.513694 | 0.987788 | 1.221% | 1.007184 |
| MTO | 73.610052 | 73.149978 | 0.993750 | 0.625% | 0.996600 |

Raw timings in seconds (execution order retained separately in samples.json):

- OFF baseline: [67.20239990000846, 66.32362049999938, 66.136288099995]; LTO: [66.61142970000219, 65.47880339999392, 65.51369350000459].
- MTO baseline: [73.66598380000505, 73.4061628000054, 73.61005160000059]; LTO: [73.14997790000052, 73.15656350000063, 73.06882919999771].

424 capacity observations, minimum observed global idle
71.177333%. No exclusive-host claim, IRQ/cache/power isolation
or guarantee between observations. Solver/build processes finished normally.

Decision **INCONCLUSIVE**, not formal Tier 2 promotion. Median direction is mildly
positive and no serious diagnostic regression observed; OFF ranges overlap and
its envelope exceeds 1. MTO separation is small. Interactive desktop and unmet
controlled Tier 1 gate prevent reproducible performance acceptance. No Tier 3,
adoption or merge. Prior Linux Tier 1 and resource-aborted attempts unchanged.
No unsupported rejection or architectural/compiler portability conclusion.

## Durable evidence and reproduction

[All raw outputs, WCNF exports, build logs, environment, samples and medians](raw/windows-tier2-02/)
plus [independent audit](raw/windows-tier2-02/independent-audit.json).
Local evidence archive E004-windows-tier2-02-evidence.tar.gz SHA256
`0d9547e9643c7aa4fde23f4e22f3003372ebef5820161c52f2e66469d5a10741`. Raw evidence is also versioned here; not dependent on the local
archive or expiring CI artifacts. Immutable input tar and built binaries remain
in the original task workspace. [Driver](run_windows_tier2.py) and
[auditor](audit_windows_tier2.py) reproduce this diagnostic; output must be fresh.

```powershell
python -X utf8 .\DistQLDPC\optimization\experiments\E004\run_windows_tier2.py `
  --archive .\E004-server-package.tar.gz `
  --cygwin-root .\E004-windows-runtime\cygwin `
  --output .\E004-windows-tier2-03
python -X utf8 .\DistQLDPC\optimization\experiments\E004\audit_windows_tier2.py `
  .\E004-windows-tier2-03
```

These commands include the full twelve-run diagnostic, not just environment
checks. Within Codex, execution may need reviewed escalation to retain the
process-local Cygwin PATH. In normal PowerShell no global PATH modification or
new install is needed. Do not rerun merely to obtain a favorable timing.

Learning: this desktop is a working correctness/diagnostic fallback and completed
comparisons that were resource-interrupted on Linux. It does not establish a
larger LTO gain or solve server isolation validation. Next: use Windows for
routine validation/diagnostics when appropriate; resolve formal E004 gates only
with a controlled run. No new optimization hypothesis or automated schedule.
