# GH-156: triangular 6.6.6 color-code library

Date: 2026-10-29 (Asia/Taipei). Issue: [#156](https://github.com/guluchen/DistQLDPC/issues/156).
Base main: `123011df4a2dc953f0e7947251cf536376260b65`.
Branch: `codex/color666-library`. Work budget: up to eight hours; complete
earlier if the deliverable and validation are finished. No minimum elapsed
time, long experiments or performance claim is implied.

## Proposal and scope

The PI requested representative new code families instead of further HGP
variants and approved this work package. Three proposals were recorded in
the issue: (1) triangular color codes, selected; (2) generalized toric/BB codes
on twisted tori; (3) balanced-product codes. Color codes add self-dual local
CSS face checks and three colored boundaries absent from the prior library.
Risks are primarily wrong boundary incidence and mistaken data-qubit counts.
Current GH-148 and GH-152 solver rounds are untouched.

Sources and complete coordinate specification are in
`data/matrices/untiered/COLOR666.md`. Original clean-room Python code and
generated matrices, GPL-3.0-or-later; no copied third-party matrices or code.
The selected published-family distances are 3,5,13,21,37,61, for n=7,19,127,
331,1027,2791, all k=1. They remain `COLOR_{n}_1_unknown` pending separate
PI naming/tier decisions. No new scientific distance claim is made.

## Changes

- `scripts/codegen/color666.py`: deterministic integer-coordinate generator,
  overwrite guard, logicals from the existing opt-in bitset backend.
- `scripts/codegen/validate_color666.py`: separate Cartesian squared-distance
  reconstruction; all face incidences, colors, boundary/bulk counts, degrees,
  logical bases and three independently checked weight-d boundary logicals.
- Six four-matrix codes, manifest rows, inventory validation, provenance and
  construction documentation in `data/matrices/untiered/` and NOTICE.
- Ten color-specific tests, plus existing eight repetition and seven cycle-HGP
  tests. The smoke runner gains explicit `--family COLOR`; default remains
  HGP and default selection is checked by a regression test.
- A branch-scoped ordinary Linux Actions workflow: unchanged solver build,
  algebra/unit checks, regeneration identity, six serial default 60-second
  smoke checks and one largest-code `-ub-pre=off -v` diagnostic. No broad sweep.

No C++ sources, solver flags/defaults, build files or existing tier matrices
are changed. Untiered matrices are excluded from existing tiers and QDistSAT.

## Local validation

Only generation, algebra and short unit tests ran on the PI's Mac; no solver
timing or experiment. All Python work uses the standard library.

```sh
python3 scripts/codegen/color666.py --ladder
python3 tests/test_codegen_color666.py
python3 tests/test_codegen_hgp.py
python3 tests/test_codegen_cycle.py
python3 scripts/codegen/validate_css.py --output /tmp/color-css-validation.json
python3 scripts/codegen/validate_color666.py --output /tmp/color-construction-witnesses.json
python3 scripts/codegen/color666.py --ladder --out /tmp/distqldpc-gh156-rebuilt
git diff --check
```

Results: all 25 tests pass. All 18 untiered codes pass independent GF(2)
validation against the full 69-code inventory. Each of the new six has no
same-(n,k) peer, so no row-space duplicate or X/Z-swapped duplicate exists.
Arbitrary column-permutation equivalence is not searched. All 24 generated
files reproduce byte for byte; logs and JSON certificates are in `raw/`.

The exact tiny oracle enumerates every stabilizer translate of a nontrivial
logical for d=3,5,7 (at most 2^18 words), including a separately relabeled d=5
code. A second d=3 oracle enumerates all 128 binary words and tests syndrome
and stabilizer membership directly. The CSS halves are identical, so these
are exact checks of both halves. Incidence, commuting missing-face and trivial
logical mutants are detected. The first test draft used the bitset builder's
API incorrectly; it was corrected before these successful checks. No matrix
or scientific-result mismatch occurred.

For large patches the independent geometric test plus witnesses verify the
actual incidence, dimension and a weight-d upper bound. The exact lower-bound
claim comes from the published triangular family (Sahay-Brown Sec. II), not
from this validator. Solver observations are recorded separately below.

## Linux smoke evidence

PENDING: branch CI has not run at this initial source checkpoint. Do not
interpret the known-distance claim or passing algebra checks as a solver
result. Manifest smoke fields remain PENDING until raw logs are reviewed.

Exact common resource protocol: Linux GitHub Actions ephemeral VM; serial,
one pinned available CPU; `prlimit --as=4294967296`; `-cpu-lim=60`; 90-second
wall backstop; stdin `/dev/null`. Default solver flags stay unchanged. Largest
diagnostic alone adds `-ub-pre=off -v`. Runner captures exact argv, compiler,
source commit, binary SHA256 and all four matrix SHA256 values. No external
distance solver, allocated server core, paid cloud host or Mac solver run.

A successful workflow means execution/integrity checks completed. A timeout
without numeric bounds remains an unmet numeric-bound acceptance requirement.
Any bound contradicting the published family distance fails collection and
requires scientific escalation. No missing bound is filled from the paper.

## Completion status

- What changed: six representative color codes and their reproducibility,
  validation and provenance package.
- Validation: 25 unit tests, all-code algebra, geometric certificates and
  byte-identical regeneration pass; Linux smoke pending.
- Results: no new scientific result or performance claim.
- Unresolved issues: Linux smoke results and final evidence retention pending;
  later server timing/tiering is a separate task.
- Scientific semantics changed: **no**.
- PI action required: **no** to finish the authorized branch package; any main
  integration or future tier/naming decision remains separate.
