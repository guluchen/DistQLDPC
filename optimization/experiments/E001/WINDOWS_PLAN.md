# E001 Windows continuation — preregistered before measurements

User requested Windows execution while the dedicated server is unavailable,
then requested performance measurement and emphasized portability of the gain.
Retain H-001 and exactly the existing baseline/candidate application code.

Use an isolated, unprivileged Cygwin environment installed in the workspace
using the official installer, verified SHA-512 and signed package metadata.
No system registry/shortcut changes, solver patches or benchmark data changes.
Compile both LF source snapshots from E001-linux-package with identical flags.
Run the existing full Tier 0 helper/algebra, exhaustive fixtures, smoke, pilot
and timeout validation before timing. Any semantic mismatch/crash rejects;
retain logs and stop. A platform build/setup failure is inconclusive, not a
scientific rejection. Compiler workaround, if necessary, must apply equally
to both and be recorded; no solver portability patch will be mixed into H-001.

After Tier 0 PASS, measure the four Tier 1 cases in OFF/MTO separately, each
baseline/candidate three times, AB/BA/AB serial order. Original 180-second
internal limit and 195-second external watchdog. Same matrices from baseline.
Full wall time includes encoding/preprocessing. Retain exact commands, binary
hashes, compiler version, OS, process affinity, outputs, return codes and bounds.
Compare all completed scientific results with each other AND named ground truth.
Do not count timeout/unknown/failure as completed. Stop on the first such outcome;
semantic disagreement or crash rejects, sound timeout leaves measurement incomplete.

Use the existing E001 median/range/geometric-mean rule, separately by mode,
without changing thresholds after results. Report numerical outcomes and noise
honestly. Windows alone is not a reason to reject measurement; single-machine
evidence cannot establish portability. This interactive desktop has no exclusive
reservation or fixed power policy. Numeric results are local diagnostic evidence;
they do not satisfy the originally preregistered controlled-host promotion gate.
Keep overall decision INCONCLUSIVE absent sufficient controlled evidence.
No Tier 2 or Tier 3 is scheduled by this diagnostic continuation.

Platform build discovery before timing: Cygwin make fails to start its Guile
dependency. Invoke the exact Makefile compiler commands and flags directly for
the DistQLDPC application and four engine objects, equally for both versions.
DistQLDPC baseline linked successfully. The separate upstream-style maxcdcl CLI
fails to link memUsedPeak() on Cygwin; retain that log and omit that unrelated
target, without introducing an engine portability change. All experiment code
and Tier 0 checks continue to use the DistQLDPC application.

Keep raw evidence under raw/windows-validation/. Do not replace older Tier 0
evidence or infer platform-independent speedups from one environment.
