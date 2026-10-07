# Windows continuation: INCONCLUSIVE (toolchain unavailable)

2026-10-07. User requested running the same LP_340_56_8 comparison on this
Windows computer. [Preregistration](TIER2-WINDOWS-PROPOSAL.md) was written before
installation/builds. H-007 remains opt-in GCC LTO only; no new hypothesis or
source change. Baseline 24572d6 and candidate 5b13a2c remain isolated.

No Windows solver binaries were built, no Windows Tier 0 was executed, and no
LP_340_56_8 timing samples were produced. Medians/ratios are unavailable, not
zero. Prior Linux Tier 0 PASS, Tier 1 INCONCLUSIVE, and both interrupted Tier 2
attempts remain unchanged. No Tier 3, adoption or merge.

## Actual observations

- Windows 10.0.19045, host DESKTOP-9NILU90, i9-11900K, 8 physical / 16 logical
  cores. This is a different host from the historical Core Ultra 5 Windows runs.
- Two-second native `GetSystemTimes` observation: 86.185% global CPU idle.
  This single observation does not establish sustained capacity or isolation.
- Existing Git supplies MSYS bash, but no GCC/G++/make/Cygwin toolchain was
  found in PATH or the inspected standard installation locations. Git's runtime
  alone cannot build the existing POSIX fork/pipe application.
- Official Cygwin installer downloaded into the task-local
  `E004-windows-runtime`; SHA512 matched the official published checksum.
  Requested per-user quiet installation with no elevation/shortcuts and
  packages `gcc-g++,make,zlib-devel`.
- **Automatic execution review rejected launching the installer.** The tool
  returned `rejected: blocked by policy`, without an explanatory reason.
  No retry, alternate execution mechanism, elevation or security disabling was
  used to bypass that rejection. No installer process was launched, no runtime
  was installed, and no global PATH or power-policy change was made.
- Original archive SHA256 verified, all 156 archived manifest payload hashes
  verified. Solver/data/downstream MaxCDCL notices remain unchanged.

[Raw preflight](raw/windows-preflight/preflight.json) retains environment,
archive/installer hashes, validation scope, empty samples and null medians.
[Official digest](raw/windows-preflight/official-sha512.sum) retained separately.
No performance conclusion follows from an unavailable toolchain. Local spare
capacity suggests this host may be usable after setup, not that LTO helps.

## Reproduction once a Cygwin runtime is available

The prepared [Windows driver](run_windows_tier2.py) needs an existing Cygwin
runtime containing GCC/G++, make and zlib-devel. It does not install anything.
The official installer is [Cygwin setup](https://www.cygwin.com/install.html);
per-user setup can use `--no-admin`, selecting the three packages above. The
attempted task-local root was `E004-windows-runtime/cygwin`.

From the original task workspace in PowerShell, after that prerequisite:

```powershell
python -X utf8 .\DistQLDPC\optimization\experiments\E004\run_windows_tier2.py `
  --archive .\E004-server-package.tar.gz `
  --cygwin-root .\E004-windows-runtime\cygwin `
  --output .\E004-windows-tier2-01
```

Output must be new. Driver verifies the fixed archive and manifest, extracts
fresh sources, builds both application binaries serially with Makefile flags
and LTO=0/1, records hashes/commands/build logs, then runs the existing LTO Tier 0
harness with Windows-to-Cygwin path adaptation. Only after PASS does it attempt
the twelve OFF/MTO AB/BA/AB solves, 600s internal / 615s external limits, distance
8 checked independently. It logs CPU observations and stops below the resource
allowance or on an incomplete/incorrect solve. Raw stdout/stderr and samples
are saved under `evidence/`; no retry or Tier 3 runner. Semantic assertions mark
REJECTED; an environment failure/interruption remains INCONCLUSIVE.

Driver syntax, four path-adaptation checks (including embedded dump-WCNF paths
and spaces), and a live native CPU-counter check PASS. Its missing-dependency
guard was exercised and stops before extraction/builds. Build/Tier 0/performance
integration is **not yet validated**, because the required toolchain is absent.
Any future run must retain this limitation and its actual results rather than
counting these harness checks as solver correctness.

Next action: make the task-local Cygwin toolchain available through an allowed
installation path, then execute the command above. Windows desktop measurements
remain separate diagnostic evidence; resolving formal gates still requires a
controlled comparison. No new research or next optimization is selected here.
