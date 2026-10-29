# GH-160: finite Tanner-cycle balanced-product library

Date: 2026-10-29 (Asia/Taipei). Issue [#160](https://github.com/guluchen/DistQLDPC/issues/160).
Base main `a727e3621d53425487070e2c079353f8536d69b8` (GH-159 integrated
with PI approval; main CI 40821214805 passed). Branch `codex/balanced-tanner-library`.

## Selection, scope and source

Three proposals in the issue: (1) explicit finite Tanner(Hamming)-cycle balanced
products, selected; (2) reproduce the paper's hyperbolic 1014-qubit example;
(3) nonabelian balanced products. The selected package makes every finite
graph, local label and group action reproducible without unresolved external
surface-group or label data. It is a specialization of the general construction,
not a reproduction of the paper's specific numerical code.

Source: Breuckmann-Eberhardt, arXiv:2012.09271v3 Sec. IV-D/E/F,
DOI:10.1109/TIT.2021.3097347. Complete finite specification, proof and provenance:
`data/matrices/untiered/BALANCED_TANNER.md`. Original GPL-3.0-or-later work;
no third-party code, matrices or paper text copied. Cyclic balanced products
overlap lifted products; the proposed BP prefix records construction provenance,
not a mathematically disjoint family. No asymptotic expansion or distance
theorem is claimed for our finite cyclic graphs.

The key scientific boundary is to keep the full CSS homology. No subsystem
projection or removal of logical classes as gauge is performed, and none of
the paper's horizontal-subsystem distance statements is assigned to the full
CSS distance. New inputs n=78,130,182,286,494,962 all have k=2. `claimed_d`
contains independently verified upper bounds <=3,5,7,11,19,37 respectively,
not published or assumed exact values. Any new solver result remains PLAUSIBLE
until independently cross-checked with a GF(2)-verified witness.

## Changes and soundness

- Original graph/Tanner/deck generator and total-complex boundary matrices.
- Separate full product-cell orbit enumeration, with no generator/logical-builder
  import, to reconstruct every matrix and verify complete CSS semantics.
- Six four-matrix inputs in untiered, manifest, NOTICE and reproducibility docs.
- Smoke collector distinguishes exact claims from upper bounds and can explicitly
  run CC. Its default HGP/MaxSAT argv remains unchanged; old claim checks are
  preserved. New safeguards reject inconsistent intervals and nonpositive
  upper bounds/answers; a zero lower bound remains valid.
- Independent printed-witness/cross-engine auditor and scoped Linux CI.

Let A be the Tanner boundary, T1/T0 the free deck actions on edge/check cells.
The labels are equivariant, so A*T1=T0*A. The balanced total complex has
d1=[A,I+T0], d2=[I+T1;A]. Therefore d1*d2=0 over GF(2). Hx=d1, Hz=d2^T;
qubits are all 14*l edge cells and 12*l check cells. Factor full rank and full
CSS k=2 are independently verified for every selected l. All local labels were
fixed from seed 0 before any distance measurement and are stored explicitly;
no performance/distance-based parameter selection occurred.

Indicators of free edge orbits have zero Hz syndrome; an orbit outside
row(Hx) is independently selected and checked by a Gx logical detector. Its
weight l gives the conservative reference upper bound. This does not establish
distance l. The tiny l=3 oracle separately excludes all weight-1/2 logicals in
both CSS halves and verifies a weight-3 nontrivial cycle, giving exact d=3.

No C++ code, solver default/behavior, build file, existing tier, stem or
QDistSAT mirror changes. This is a library/verification package, not a solver
optimization or benchmark promotion. No active agent's solver round is touched.

## Local checks

Mac activity is generation, GF(2) and short deterministic unit checks only;
no solver experiment or timing. Python standard library only.

```sh
python3 scripts/codegen/balanced_tanner.py --ladder
python3 tests/test_codegen_balanced_tanner.py
python3 tests/test_codegen_twisted_torus.py
python3 tests/test_codegen_color666.py
python3 tests/test_codegen_hgp.py
python3 tests/test_codegen_cycle.py
python3 scripts/codegen/validate_balanced_tanner.py --output /tmp/bp-certificates.json
python3 scripts/codegen/validate_css.py --output /tmp/bp-validation.json
python3 scripts/codegen/balanced_tanner.py --ladder --out /tmp/distqldpc-gh160-rebuilt
```

All 43 unit tests pass. Action inversion and invalid/trivial witness mutations
are caught, and tests explicitly reject treating an upper bound as an exact
claim. Independent validation covers all 30 untiered codes in the 81-code
inventory. New cases have no same-(n,k) peer; same-order row spaces and X/Z
swaps are checked, arbitrary column permutations are not searched. All 24 new
matrix files reproduce byte for byte. Raw local logs and certificates are in
`raw/`. All prior 24 manifest rows and 96 untiered input files are unchanged.

## Linux execution and scientific status

Two source checkpoints were validated:

| Attempt | Source | Library run / job | Ordinary CI |
|---|---|---|---|
| initial | 5a58dafafe14544b8cc0ba5d5799330a5e189c30 | 40826355475 / 123290181493 | 40826355401 |
| recheck | 2831b4b79f89b535f6649a85d29ca12b94090607 | 40826686405 / 123291225482 | 40826686375 |

Both library workflows and ordinary CIs passed. The initial source tree is
`df180c9e2e8a0d4312f91dbd275d5a5a1ca5e6a3`; recheck tree is
`2482678bd1ad28402300fdd14002fbda053fde49`.
After initial CI, collector review corrected two edge cases: zero is a valid
weak lower bound, and exact-answer auditing must read the explicit `o` value
rather than infer it from a possibly looser reported lower bound. No emitted
result triggered those draft issues and no scientific contradiction occurred.
Unit tests were updated and the same fixed panel rerun with the corrected
collector. The matrices, solver executable and flags were unchanged. Both
attempts' complete raw evidence is retained; no favorable run was selected.

Binary SHA256 for both attempts and both engines (same unchanged executable
as the prior library batches):
`13aa8ba74b3960b8767bfda60d10fb09f057e6655f5112c6f3f343dfdee03328`.

Each workflow passed all 43 tests, all-code algebra, independent cell-orbit
reconstruction and 24-file regeneration. Each input then ran for 60 seconds
with default MaxSAT and independently with CC. Both used verbose witnesses,
one pinned CPU, a 4 GiB address-space cap, a 90-second wall backstop,
stdin /dev/null and serial execution on the ephemeral Linux runner.

Both attempts yielded exactly these bounds/results:

| Stem | Derived reference upper bound | MaxSAT 60s | CC 60s | Scientific status |
|---|---:|---|---|---|
| BP_78_2_unknown | 3 | exact 3 | exact 3 | cross-checked; also tiny exact oracle |
| BP_130_2_unknown | 5 | exact 5 | exact 5 | cross-checked |
| BP_182_2_unknown | 7 | exact 7 | exact 7 | cross-checked |
| BP_286_2_unknown | 11 | exact 9 | exact 9 | cross-checked |
| BP_494_2_unknown | 19 | exact 9 | exact 9 | cross-checked |
| BP_962_2_unknown | 37 | [5,9], timeout | exact 9 | **PLAUSIBLE**, independent completion pending |

For the first five original finite instances, two distinct internal search
implementations agree and matching weight witnesses were independently
verified. The last case's CC result 9 is not promoted to cross-checked exact:
MaxSAT did not complete. The observed lower-bound gap and the PLAUSIBLE status
are preserved. All stems remain unknown and untiered; no new paper claim or
asymptotic/performance assertion is made.

Durable evidence: `raw/actions/attempt1/` and `raw/actions/recheck/`. Each has
`bp-maxsat/`, `bp-cc/`, independent `audit.json`, and the complete Actions
`job.log`. Per-case JSON records exact argv, input/binary SHA256, source, exit
status and bounds; environment, CSV and completion markers are retained.
All 24 executions replay consistently with CSV/JSON; both audits reproduce
identically, independently checking every printed logical, cycle certificate,
matrix identity and interval (`raw/actions/replay.txt`). The manifest's primary
and supplemental fields use the latest corrected collector's MaxSAT and CC
records. Earlier records remain in full and have identical semantic outcomes.

```sh
make --jobs=2 bin/distqldpc
python3 scripts/codegen/smoke_untiered.py --ci --family BP --verbose --out /tmp/bp-maxsat
python3 scripts/codegen/smoke_untiered.py --ci --family BP --engine cc --verbose --out /tmp/bp-cc
python3 scripts/codegen/audit_balanced_smoke.py --maxsat /tmp/bp-maxsat --cc /tmp/bp-cc --out /tmp/bp-audit.json
```

Every printed support is independently checked for syndrome, stabilizer
membership and logical detector. Engine intervals must intersect and agree
with the independently verified upper bounds. Only matching complete results
from both internal implementations plus a matching independently verified
minimum-weight witness receive CROSS_CHECKED status. Other new results retain
PLAUSIBLE status. Missing solver bounds are not filled from witnesses or claims.
No stem is renamed. Any contradiction stops collection for scientific review.

This is a fixed new-input correctness panel, not a performance sweep. One
default-seed run per engine/case; no repeats, seed medians or performance
claims. No external distance solver, server allocation or Mac solver run.

## Completion status

- What changed: six fully specified balanced-product CSS inputs and generator,
  independent orbit/witness checks, provenance and two-engine smoke package.
- Validation: 43 tests, all-code algebra, independent orbit/rank/cycle checks,
  regeneration and both Linux panels pass; all 24 executions and witnesses
  independently replayed and retained.
- Results: five exact distances cross-checked on original finite instances;
  largest code has a PLAUSIBLE CC distance 9 and independent MaxSAT [5,9].
- Unresolved: independently complete the largest-code lower bound; later server
  timing/tiering/naming are separate tasks. No numeric smoke bound is missing.
- Scientific semantics changed: **no**.
- PI action required: **no** to finish the authorized work-branch package;
  integrating this new batch into main remains separate approval.
