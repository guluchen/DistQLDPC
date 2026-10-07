# E001 Windows repeat 02 — before measurements

User explicitly requested another round and an explanation of the Windows setup.
Repeat H-001 unchanged, not a new optimization experiment. Read the first Windows
result before this repeat: Tier 0 passed; all 48 results match; GB regressed with
disjoint baseline/candidate ranges in OFF/MTO. Do not alter the hypothesis or gates
to obtain a different answer. No additional conceptual performance change.

Verify the same baseline/candidate/probe binaries and all pinned package source
identities before running. Reuse compiled applications; no rebuild is needed
because neither code nor compiler flags changed. Re-enter fresh Tier 0, then
the same 48 Tier 1 samples: four cases, OFF/MTO, 3 repeats per version, serial
AB/BA/AB, 180-second internal limit and 195-second external watchdog. Preserve
commands, all outputs, hashes, raw times, medians/ranges and between-round
comparisons. Same existing E001 numerical gate. Semantic mismatch/crash stops;
incomplete timeout blocks performance conclusions. No Tier 2/3 scheduled.

Windows Cygwin provides Unix process behavior for unchanged DistQLDPC C++.
GCC 14.4.0 uses the original root Makefile application flags. Native bundled
Python with UTF-8 drives the unchanged Tier 0 harness; only CLI paths for Unix
executables are adapted. The original probe binary uses gnu++11. The legacy
standalone maxcdcl CLI is not tested here; its prior Cygwin link failure remains
recorded. This is DistQLDPC with an embedded modified MaxCDCL engine, not a
standalone upstream MaxCDCL performance experiment.

New output: raw/windows-repeat-02/. Do not overwrite raw/windows-validation/.
The host still has no exclusive reservation, pinned CPU or fixed power policy.
Repeated local evidence can test persistence of the GB regression, not establish
cross-machine portability or retroactively pass the original controlled gate.
Overall controlled experiment remains INCONCLUSIVE unless actual controlled
evidence becomes available. Do not accept this candidate based on laptop/desktop
timing, and do not hide a serious per-case regression behind averages.
