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

Source checkpoint: `43203da6c17841d1aff229007e755ffaf6fd600f`.
Tree: `97e485c4875e478cb1652e42a289af74951566c1`.
[Color-code workflow 40781708080](https://github.com/guluchen/DistQLDPC/actions/runs/40781708080),
job `123144753288`: **success**. Ordinary CI `40781708143`: **success**.
The Linux run passed all 25 tests, independent algebra/geometry certificates,
all 24 regeneration comparisons, and the seven bounded execution checks.

Binary SHA256 (unchanged solver build, same as GH-153/GH-154):
`13aa8ba74b3960b8767bfda60d10fb09f057e6655f5112c6f3f343dfdee03328`.

| Stem | Published d | Default 60s observed lb | Observed ub | Status |
|---|---:|---:|---:|---|
| COLOR_7_1_unknown | 3 | 3 | 3 | SOLVED |
| COLOR_19_1_unknown | 5 | 5 | 5 | SOLVED |
| COLOR_127_1_unknown | 13 | 13 | 13 | SOLVED |
| COLOR_331_1_unknown | 21 | 9 | 21 | BOUNDED, timeout |
| COLOR_1027_1_unknown | 37 | 9 | 37 | BOUNDED, timeout |
| COLOR_2791_1_unknown | 61 | unavailable | unavailable | TIMEOUT_NO_BOUNDS |

Largest-code diagnostic `-ub-pre=off -v`: observed lb **5**, ub **unavailable**,
`TIMEOUT_PARTIAL_BOUNDS`. The verbose log confirms Hx/Hz `1395 x 2791`,
Gx/Gz `1 x 2791`, and MaxSAT search activity before timeout. This diagnostic
does not replace the default result and does not close the numeric-bound gap.
The independently verified boundary witnesses have weight 61, but the missing
solver-reported upper bound is intentionally left empty in the manifest.

Raw evidence is durable in `raw/actions/color-default/` and
`raw/actions/color-no-prepass/`, with the complete Actions job log in
`raw/actions/job.log`. Each configuration includes environment JSON, per-case
argv/identity/result JSON, raw logs, results CSV and completion marker. All
seven records were replayed through the collector; JSON/CSV/raw results and
every input SHA256 match (`raw/actions/replay.txt`). Final report/manifest
updates do not alter these validated inputs or executable sources.

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

Exact runner commands (as executed inside the ephemeral Linux Actions job):

```sh
make --jobs=2 bin/distqldpc
python3 scripts/codegen/smoke_untiered.py --ci --family COLOR --out /tmp/color-default
python3 scripts/codegen/smoke_untiered.py --ci --family COLOR --stems COLOR_2791_1_unknown --ub-pre-off --verbose --out /tmp/color-no-prepass
```

No seed-median or performance verdict applies: this is a new-library package,
not a solver optimization. There is one default-seed smoke per selected cell;
no timing, tier or baseline claim is made. No scientific contradiction was
observed. Verdict: **library construction and reproducibility delivered;
default 60s numeric-bound acceptance remains unmet for COLOR_2791_1_unknown**.
Longer timing/certification belongs to a separately authorized server task.

## Completion status

- What changed: six representative color codes and their reproducibility,
  validation and provenance package.
- Validation: 25 unit tests, all-code algebra, geometric certificates,
  byte-identical regeneration and Linux execution/integrity CI pass; all
  seven raw executions retained and replayed.
- Results: three known exact distances reproduced, two consistent bounded
  timeouts, one default timeout without bounds and a separately labeled
  diagnostic with lower bound only. No new scientific or performance claim.
- Unresolved issues: the largest code does not meet the default 60s numeric-
  bound requirement; later server timing/certification and tiering are separate.
- Scientific semantics changed: **no**.
- PI action required: **no** to finish the authorized branch package; any main
  integration or future tier/naming decision remains separate.
