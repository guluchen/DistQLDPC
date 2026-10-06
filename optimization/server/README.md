# E001 dedicated-server package

The [2026-10-07 continuation](../experiments/E001/CONTINUATION-2026-10-07.md)
retains an actual archive, checksum, validation receipt and exact run commands.
To recreate the pinned source/input package from a DistQLDPC clone:

```sh
git clone --bare --filter=blob:none https://github.com/guluchen/QDistSAT.git QDistSAT.git
python3 optimization/server/make_package.py \
  --qdistsat-repo QDistSAT.git --output E001-server-package
```

The output directory must be new. The exporter uses the original E001 baseline,
candidate and QDistSAT revisions, ignores working-tree edits, preserves committed
LF bytes even on Windows, and verifies the original input identities. Transfer
`E001-server-package/E001-run-package.tar.gz` and `SHA256SUMS` together; verify
with `sha256sum -c SHA256SUMS` before extracting. The archive checksum identifies
that export (archive timestamps may differ on another export); the manifest
identifies every immutable source/input file.

The delivered tar.gz is self-contained: exact baseline/candidate source snapshots,
original matrices and pinned QDistSAT correctness harness/data, notices/licenses,
and a SHA-256 manifest. No network access, paid cloud or full suite is required.
Use an exclusively reserved Linux machine with g++, make, Python >=3.10 and zlib
development headers. Reserve the selected physical core and its SMT sibling;
stop unrelated jobs and fix CPU governor/power policy for the entire run.
An operator must attest the reservation; the script cannot prove host exclusivity.
If these conditions are not met, do not run or draw performance conclusions.

From the extracted `E001-run-package` directory, choose a CPU allowed by your
reservation and a NEW output directory, then execute (replace example CPU 2 and
reservation note with real values):

```sh
python3 candidate/optimization/server/run.py \
  --package . --output ../E001-controlled-results \
  --cpu 2 --exclusive-host --reservation-note 'exclusive dedicated host reservation ID'
```

The script verifies every packaged file, builds both snapshots with identical
Makefile/g++ flags, records host/compiler/input/binary identities, and reruns Tier 0.
Any correctness mismatch rejects/escalates and blocks further tests. It then runs
Tier 1 serially: four named cases, OFF/MTO separately, 3 baseline + 3 candidate runs,
AB/BA/AB order, 180s internal timeout (195s watchdog). Each execution logs full
stdout/stderr; total wall includes preprocessing, encoding and search. Completed
semantic tuples must agree; unknown/timeouts cannot count as completed solves.
Tier 1 pass alone enables LP_340_56_8 Tier 2, both modes × 3 × 2 versions, 600s
internal timeout (615s watchdog). Tier 3 is not implemented. No repeated runs are
silently discarded or retried. Failures retain all logs and halt promotion.

Preregistered rule: see ../experiments/E001/PROPOSAL.md. Review reservation and
host stability with the captured evidence before relying on any generated decision.
A reservation violation invalidates timings even if the numeric filter passes.
No merged optimization or research-grade claim follows automatically.

Resource notes: one solver process at a time on the pinned CPU; builds use two
jobs. No new RAM/address-space cap is imposed; retain host memory availability.
Historical Tier 1 pure solver estimate ~4.2 min, worst internal budget 144 min;
Tier 2 ~29 min, worst 120 min; Tier 0/build/watchdog overhead extra. Actual runtime
and memory depend on host and search; ensure disk space for verbose logs.

Outputs: environment.json, binary-identities.json, tier0/, all build/run logs,
samples.json, decision.json (raw samples, per-case medians/ranges and mode aggregates),
STATE.md. Retain the whole directory under optimization/experiments/E001/controlled/
and update repository STATE.md/HYPOTHESES.md based on that evidence. An inconclusive
run remains inconclusive. Never replace ground truth or lower the gates to get a pass.
