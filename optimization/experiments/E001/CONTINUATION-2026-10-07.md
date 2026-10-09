# E001 continuation — 2026-10-07

## Recorded before further validation

Recovered the selected Brain Round 1 #1 from `PROPOSAL.md`, `HYPOTHESES.md`,
and branch `experiment/h001-logical-row-xor` at
`9d68f459019e9c5a20c5c513cf89aaf4a2cd2854`. This is a continuation of E001,
not a second experiment or a new hypothesis. The existing proposal and its
preregistered gates remain authoritative.

Hypothesis/mechanism: one sequential, strictly weight-reducing row-XOR pass
on separate in-memory Gx/Gz copies before the DistQLDPC application invokes
its patched MaxCDCL engine. Each row selects its best current partner, ties
by lowest index; apply immediately, retain row order/count. Invertible row
operations preserve the logical nontriviality predicate and Pauli objective.
LP cases have the largest observed absolute reductions; BB/GB also have
shortening opportunities. Fewer gates do not establish faster solving.

Implementation scope: retain exactly implementation commit
`50623f9710969288d3a9d1c6325f3a72c35ff6d5`, against baseline
`24572d6d09cce9a4a5faa58300a89e0feba9da6a`. No new performance change,
solver patch, input edit, or altered evaluation threshold is planned.
Attribution and the distinction between QDistSAT, DistQLDPC and upstream
MaxCDCL remain intact. No MODIFICATIONS.md/NOTICE amendment is necessary
because E001 changes only the application layer.

Risks: search/propagation can worsen despite a smaller encoding; preprocessing
has quadratic dependence on the logical row count. Scientific correctness
requires invertible sequential updates and an unchanged feasible Pauli set.
Current local MSYS/Windows execution is useful for build/correctness checks
only, not controlled performance measurement.

Relation to earlier work: E001 already has local macOS Tier 0 PASS and hosted
Linux build/smoke and QDistSAT pilot PASS. Those are retained as earlier
evidence. No controlled samples have been recorded. H-002/H-003 remain
unselected alternatives; neither is part of this experiment.

Planned work/cost: verify identities and the retained CI evidence; attempt
local baseline/candidate builds and the existing Tier 0 checks using the
already available MSYS GCC toolchain; validate the server package. This is
short correctness work, not Tier 1. If no exclusively reserved dedicated
Linux host is available, deliver an actual self-contained package with exact
commands and retain INCONCLUSIVE pending controlled run. Tier 1 remains
48 measured runs (four cases, two modes, three runs per binary), internal
worst-case 144 minutes; conditional Tier 2 remains 12 runs, internal worst-case
120 minutes. No Tier 3 work is authorized by a missing earlier result.

## Results

**Decision: INCONCLUSIVE — pending controlled Tier 1 run.**

Supplemental local Tier 0 PASS: 676 algebra instances, independent exhaustive
CSS fixtures (distances 2 and 1) in default/OFF/MTO modes, both smoke checks,
eight cross-repo pilot solves, and six forced timeout checks. The pilot's exact
distance, objective, lower bound, upper bound and exit status match in both
explicit modes: LP_136_32_4 = 4 and BB_108_8_10 = 10. Timeout runs return
TIMEOUT/UNKNOWN with sound bounds, never a false exact result. No solver crash
or semantic mismatch was observed. Six existing runner tests also pass.

Raw evidence: [continuation directory](raw/continuation-2026-10-07/), especially
`tier0/summary.json`, `tier0/cross-repo.json`, `tier0/structure.json`, and all
stdout/stderr/command records. Existing evidence was retained without replacement.
Hosted Linux QDistSAT check on `9d68f45` also passed:
https://github.com/guluchen/DistQLDPC/actions/runs/37490929304.
Its report and status were downloaded to the continuation directory. These
are earlier hosted results, not newly executed CI or controlled measurements.

Local environment: Windows 10, Intel i9-11900K, MSYS GCC 15.3.0 / Make 4.4.1,
MSYS Python 3.12.14. `environment.json` records input/binary hashes and limits.
The unmodified baseline `make all` failed linking the separate `bin/maxcdcl`
target (`Minisat::memUsedPeak` has no MSYS definition). Both `bin/distqldpc`
targets build with identical, unchanged Makefile flags. The test-only probe
uses `-std=gnu++11` because MSYS hides POSIX declarations under strict c++11.
No production portability patch was added. Full Linux builds passed in the
retained hosted check; the Windows build limitation is not candidate evidence.

Exact supplemental commands, from the repository root in the existing MSYS
shell (with MSYS Python on PATH), after exporting baseline/candidate to
`.validation/baseline` and `.validation/candidate` and the pinned QDistSAT
pilot to `.validation/qdistsat`:

```sh
# The initial default build failure is retained in baseline-build.log.
make -C .validation/baseline -j2 CXX=g++
make -C .validation/baseline -j2 CXX=g++ bin/distqldpc
make -C .validation/candidate -j2 CXX=g++ bin/distqldpc
(cd .validation/candidate && g++ -Isrc/solver -O2 -std=gnu++11 \
  optimization/tests/logical_probe.cc build/SimpSolver.o build/Solver.o \
  build/Options.o build/System.o -lz -o ../probe.exe)
.validation/msys-python/usr/bin/python3.12.exe \
  .validation/candidate/optimization/tests/tier0.py \
  --baseline .validation/baseline/bin/distqldpc.exe \
  --candidate .validation/candidate/bin/distqldpc.exe \
  --probe .validation/probe.exe --qdistsat .validation/qdistsat \
  --out optimization/experiments/E001/raw/continuation-2026-10-07/tier0
python -m unittest discover -s optimization/tests -p test_server.py -v
```

Git for Windows initially exported CRLF working-tree bytes. All local matrix
values match the pinned inputs, and all 56 input hashes match the preregistered
hashes after line-ending normalization. The new package exporter explicitly
disables this conversion: its packaged inputs match those hashes byte for byte.
An initial export was caught by the identity assertion and corrected before
delivery. No matrix values or benchmark ground truth changed.

## Controlled performance and learning

No dedicated Linux endpoint or exclusive reservation is available through this
task. The interactive desktop is not a controlled performance environment.
There are **zero controlled samples**; neither local nor hosted Tier 0 timings
are used for performance conclusions. For both OFF and MTO:

| Tier 1 case | Baseline runs | Candidate runs | Baseline median | Candidate median |
|---|---:|---:|---|---|
| BB_90_8_10 | 0 | 0 | N/A | N/A |
| GB_144_12_8 | 0 | 0 | N/A | N/A |
| BB_108_8_10 | 0 | 0 | N/A | N/A |
| LP_238_44_6 | 0 | 0 | N/A | N/A |

Tier 1 does not pass; Tier 2 and Tier 3 were not run. The candidate remains
isolated on its existing experiment branch and draft PR #11, without promotion.
The repeated structural checks reproduce the previous weight reductions;
LP_238 remains 1160 -> 936 and LP_340 2220 -> 1688. This adds cross-platform
correctness evidence, not evidence of runtime improvement. No next hypothesis
is selected from an unresolved performance result.

## Delivered server package

[E001-run-package.tar.gz](raw/continuation-2026-10-07/E001-run-package.tar.gz)
is self-contained (381,540 bytes). Its SHA-256 is
`8bf080e9e4cc0a53dfefdac97bb4d1126449533c5c094768ae25cda46478f04c`.
All 158 manifest entries were checked in the directory and compressed archive;
all 56 input identities passed. The only production source difference is
`src/core/distqldpc.cc`, exactly the preserved E001 implementation. The packaged
runner's six gate/parser tests pass. No performance run was executed to validate
the package.

The new `optimization/server/make_package.py` exports immutable Git revisions,
original inputs, licenses/notices, existing tests and the unchanged server
runner. It adds no performance mechanism or evaluation rule. Recreate with:

```sh
git clone --bare --filter=blob:none https://github.com/guluchen/QDistSAT.git QDistSAT.git
python3 optimization/server/make_package.py \
  --qdistsat-repo QDistSAT.git --output E001-server-package
```

On an exclusively reserved Linux server, after transferring the archive and
its adjacent `SHA256SUMS`, verify/extract it and execute the original gates.
Choose an allowed CPU and record the actual reservation; `2` is an example:

```sh
sha256sum -c SHA256SUMS
tar -xzf E001-run-package.tar.gz
cd E001-run-package
python3 candidate/optimization/server/run.py \
  --package . --output ../E001-controlled-results \
  --cpu 2 --exclusive-host --reservation-note 'ACTUAL reservation identifier'
```

Next action: obtain that exclusive server execution, retain the entire result
directory, and reconcile E001/STATE/HYPOTHESES from its measurements. The
preregistered Tier 1 thresholds, repeat counts, limits and conditional Tier 2
remain unchanged. There is no Tier 3 execution in the runner.
