# B002 corrected source baseline

Current status (2026-10-09): FULL_WINDOWS_LOCAL_CORRECTNESS_CERTIFIED;
see [the actual full certificate](WINDOWS_FULL01_CERTIFICATE.md). The original
crash was invalid-sentinel watcher indexing, not demonstrated out-of-memory.
Merged [PR59](https://github.com/guluchen/DistQLDPC/pull/59) removes retired
auxiliary soft literals before lookahead and rebuilds the affected heaps while
preserving objective accounting. The original300B failure now returns optimum5;
full finite Windows validation covers54 application outcomes,162 PMS outcomes,
40 WCNF comparisons,12 genuine timeout paths and2 smokes. This does not certify
all possible inputs, exclude every memory bug, or establish a performance gain.
Fresh native Linux certification is pending; the historical source-registration
status below is retained rather than relabeled as native binary certification.

Registered in [issue62](https://github.com/guluchen/DistQLDPC/issues/62).
Source commit 72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7 is the merged GH58
correctness repair. SOURCE.json pins all32 tracked production src/Make inputs;
all equal the already validated b2e1274 head. Two legacy tracked .or objects
are listed for honest source provenance but must not be consumed by fresh builds.

Status: SOURCE_REGISTERED; BINARY_RUNTIME_CERTIFICATION_PENDING.
No existing245 binary is renamed or relabeled, no prior performance outcome
is promoted, and the old baseline/history remain immutable.

Before actual comparison, separately prerecord the selected one-concept candidate,
freeze consumed runtime/compiler/objects/executables/support/inputs, build fresh
root Make -j1 with unchanged GNU/O3 settings, and run the exact300B original
regression first (independent optimum5), all11 oracle cases and80+1 partition
invariants, plus applicable full scientific/bounds/model/timeout checks and the
required QDistSAT cross-repo check against B002. Fresh runtime certification is
specific to the actual host; hostedCI correctness does not certify its binaries.

Then Tier1 compares three baseline and three candidate runs per case/configuration,
retains raw data and medians, checks unchanged science and noise before promotion;
Tier2 and Tier3 retain existing gates. SharedCI timing never establishes speed.
Root schedules one named runner per host under the user's spare-resource limits;
resource telemetry/raw private metadata remain local. Each agent independently
proposes exactly3, selects1 and records its selection and learning in GitHub.

Proof links: [repair PR59](https://github.com/guluchen/DistQLDPC/pull/59),
[full correctness](https://github.com/guluchen/DistQLDPC/actions/runs/37871089896),
[cross-repo](https://github.com/guluchen/DistQLDPC/actions/runs/37871089865).
