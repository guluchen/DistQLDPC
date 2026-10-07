# Windows LP_340_56_8 diagnostic preregistration

2026-10-07, before local installation/builds/solves. The user explicitly asked
to try the same experiment on this Windows machine after two Linux resource
interruptions. This is a separate diagnostic continuation, not Tier 1 promotion.

Hypothesis remains H-007: GCC LTO across the existing translation units can
reduce execution overhead. Exactly one conceptual change, `-flto=1` at compile
and link. Baseline 24572d6, candidate 5b13a2c, QDistSAT harness 7c4774f from the
unchanged E004 package. No source, encoding, ground-truth, bounds, timeout,
heuristic, Pauli-weight or logical-operator changes. DistQLDPC includes its own
downstream MaxCDCL patches; it is not identical to upstream MaxCDCL. Attribution
is preserved. No MODIFICATIONS/NOTICE changes are required.

Host: this Windows i9-11900K, 16 logical CPUs, approximately 64 GiB RAM. It is
different from the previously recorded Core Ultra 5 Windows host. No timing
pooling across hosts, compilers, operating systems, or interrupted attempts.

Scope: per-user task-local Cygwin GCC/make/zlib to retain POSIX fork/pipe and
parent wall-clock timeout behavior; clean fresh baseline/candidate builds,
serial `make -j1`, LTO=0 versus LTO=1. Installer integrity verified against the
official published digest; package verification retained. No elevation,
shortcuts, global PATH changes, affinity/isolation installation or power-plan
changes. Record compiler version, flags, hashes, host metadata and load.

Tier 0 prerequisite: unchanged package LTO harness checks six byte-identical
WCNF exports, independent exhaustive tiny CSS oracles, smoke/help, pinned
QDistSAT pilot OFF/MTO, and six parent timeout checks. Native Windows Python
adapts filesystem arguments to Cygwin paths without changing assertions. Any
semantic mismatch/crash stops before performance and rejects this build.
Build/toolchain incompatibility is INCONCLUSIVE, not an invented solver result.

If Tier 0 passes: LP_340_56_8 only, OFF and MTO separately, three baseline and
three candidate runs per mode, AB/BA/AB order. Twelve sequential runs, 600s
internal wall limit and 615s external watchdog; expected distance 8 is used only
by the checker. Keep exact commands, stdout/stderr, return codes, wall timings,
resource observations and all incomplete samples. One solver at a time; stop
if measured spare capacity falls to <=50%, an external timeout, crash, wrong
result/bound or output-semantics mismatch occurs. No automatic retry or Tier 3.

Cost: local runtime download/setup, two serial builds, short Tier 0, at most
120 minutes of solver time if all twelve runs approach the limit. Expected
order of minutes per comparison, not a promised speed. Risks: Cygwin fork/AV
compatibility, compiler/plugin differences, local desktop load and code-layout
regression. Do not work around fork failures by altering solver semantics or
disabling security software.

Analysis: report individual timings and medians, candidate/baseline ratio per
mode, sample ranges and range envelope. Complete correct solves may provide
diagnostic direction but cannot establish controlled reproducibility on this
interactive desktop. Overall E004 remains INCONCLUSIVE unless the original
controlled gates are independently satisfied. Keep prior Linux Tier 1 and both
resource-interrupted Tier 2 attempts unchanged. Candidate remains isolated and
unmerged; SLS/BDD and original H-001 are not stacked into this experiment.
