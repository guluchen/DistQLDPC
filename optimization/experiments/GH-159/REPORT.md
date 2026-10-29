# GH-159: generalized toric / BB instances on twisted tori

Date: 2026-10-29 (Asia/Taipei). Issue [#159](https://github.com/guluchen/DistQLDPC/issues/159).
Base main: `8fe913e2ca79bda37cb755975b06b1b60416a418`.
Branch: `codex/twisted-torus-library`.

## Proposal and changes

Continue the PI-authorized representative matrix-library expansion after
GH-156. Three proposals in the issue: twisted-torus generalized toric/BB
codes, selected; balanced-product codes; newer non-abelian Quantum Tanner
instances. This adds quotient-lattice boundary identifications and polynomial
checks to an existing BB subclass. It does not claim an unrelated new family.
No competing twisted-torus issue or branch was found when claiming the topic.
Active solver rounds GH-148/GH-152 are untouched.

Added six reproducible four-matrix inputs in untiered: n=30,120,186,248,294,340
and k=4,8,10,10,10,16. Published distance claims are 6,12,14,18,20,18.
Source parameters/provenance and a complete original coordinate specification
are in `data/matrices/untiered/TWISTED_TORUS.md`. Source: Liang et al.,
arXiv:2503.03827v3, Eqs.(3)-(5), Tables 1-4, DOI:10.1103/rmy6-9n89.
No third-party code, paper text or matrix files copied; original work is
GPL-3.0-or-later. No external distance solver is executed.

New generator `scripts/codegen/twisted_torus.py` uses floor-division reduction
in the lattice <(0,h),(w,s)>; parameter data are in
`scripts/codegen/twisted_torus_cases.json`. An independent congruence validator
rebuilds every check without importing the generator. Existing logical builder
is reused unchanged. The smoke runner gains explicit `--family BB`, preserving
its HGP default and the existing COLOR selection. Added nine tests, a scoped
Linux workflow, manifest/provenance, witnesses and raw evidence.

All new stems retain `unknown`. No solver sources, flags/defaults, build files,
existing tier matrices, timings, names or QDistSAT data change. All 18 prior
manifest rows and 72 prior untiered matrix files remain unchanged.

## Validation and soundness

Each X check is [f,g], and the Z check is [bar(g),bar(f)] translated over the
finite abelian quotient. In matrix notation Hx=[F G], Hz=[G^T F^T]. Commuting
translations give Hx Hz^T=FG+GF=0 in GF(2). Monomials colliding in the quotient
cancel by XOR. Negative coordinates and crossing the x seam need y shifted
by minus s; both are tested. The independent implementation enumerates
source/target pairs and tests integer lattice membership instead of sharing
the coordinate-reduction routine.

All 24 untiered codes pass the GF(2) inventory validator (75 codes including
existing tiers), with dimension, complete logical quotient and full pairing
checks. The six new cases have no same-(n,k) peer, so no row-space or X/Z-swap
duplicate is possible with an existing input. Arbitrary permutation
equivalence is not searched. Independent reconstruction reproduces every new
matrix row and published n,k; all checks have weight six. Explicit logical
basis-row witnesses have verified weights 6,22,14,54,50,66 respectively;
these are upper bounds on actual matrices, not replacements for published d.

The n=30 independent oracle scans increasing supports through weight six,
tests syndromes and excludes stabilizer row space. It returns exact d=6 for
both halves and after random relabeling. Mutations omitting the antipode or
reversing the seam are caught. Degenerate quotient examples test GF(2)
monomial cancellation. Nine new plus 25 existing tests pass, and all 24 new
matrix files regenerate byte for byte. All Mac activity was generation,
algebra or short unit checks; no solver timing/experiment.

```sh
python3 scripts/codegen/twisted_torus.py --all
python3 tests/test_codegen_twisted_torus.py
python3 tests/test_codegen_color666.py
python3 tests/test_codegen_hgp.py
python3 tests/test_codegen_cycle.py
python3 scripts/codegen/validate_css.py --output /tmp/twisted-css-validation.json
python3 scripts/codegen/validate_twisted_torus.py --output /tmp/twisted-certificates.json
python3 scripts/codegen/twisted_torus.py --all --out /tmp/distqldpc-gh159-rebuilt
```

Raw local logs, validation and construction-witness JSON are in `raw/`.
No new bound/pruning rule or performance optimization is introduced, so there
is no optimization adoption gate or seed-median timing claim.

## Linux smoke results

Source checkpoint: `5745cb2ac0f9091a5cd93455e32e1e526fa115c2`;
tree `4be689bcd8ed8acf74afcac8fb125f6af1993fd7`.
[Library workflow 40802954550](https://github.com/guluchen/DistQLDPC/actions/runs/40802954550),
job `123215096866`: **success**. Ordinary CI `40802954319`: **success**.
CI passed unchanged-solver compilation, all 34 tests, independent lattice and
GF(2) checks, all 24 regeneration comparisons and six default smoke executions.

Binary SHA256 (same unchanged build as GH-153/GH-154/GH-156):
`13aa8ba74b3960b8767bfda60d10fb09f057e6655f5112c6f3f343dfdee03328`.

| Stem | Published exact d | Default 60s lb | ub | Status |
|---|---:|---:|---:|---|
| BB_30_4_unknown | 6 | 6 | 6 | SOLVED |
| BB_120_8_unknown | 12 | 12 | 12 | SOLVED |
| BB_186_10_unknown | 14 | 14 | 14 | SOLVED |
| BB_248_10_unknown | 18 | 10 | 18 | BOUNDED, timeout |
| BB_294_10_unknown | 20 | 10 | 20 | BOUNDED, timeout |
| BB_340_16_unknown | 18 | 10 | 18 | BOUNDED, timeout |

All six have numeric lower and upper bounds consistent with their published
claims. Three exact distances are reproduced; the remaining three published
lower bounds are not independently established by this 60-second run. No
scientific contradiction is observed. One default seed per input, no repeats
or seed-median timing claim. Verdict: **library and short-check acceptance
pass; untiered, no solver optimization/performance adoption**.

All raw stdout, per-case argv/identity/results, input and binary SHA256,
source commit, environment, CSV and completion marker are retained in
`raw/actions/default/`; complete Actions job log in `raw/actions/job.log`.
All six execution records were replayed through the collector and agree with
their JSON, CSV and every bundled input hash (`raw/actions/replay.txt`). Final
report/manifest-only edits do not change validated inputs or executable code.

```sh
make --jobs=2 bin/distqldpc
python3 scripts/codegen/smoke_untiered.py --ci --family BB --stems BB_30_4_unknown BB_120_8_unknown BB_186_10_unknown BB_248_10_unknown BB_294_10_unknown BB_340_16_unknown --out /tmp/twisted-default
```

Per execution: one pinned runner CPU; 4 GiB address-space cap; -cpu-lim=60;
90-second wall backstop; stdin /dev/null; serial on an ephemeral Linux Actions
VM. No server allocation, broad sweep or external distance solver. Raw argv,
source, binary/input SHA256 and complete stdout are retained. Bounds or an
answer contradicting a published exact claim stop collection and require
scientific escalation. No-bound timeouts remain an unmet numeric-bound gate,
even if the execution workflow is green (lesson retained from GH-153/GH-156).

## Completion status

- What changed: six representative twisted-torus BB inputs and reproducibility,
  independent validation, provenance and smoke package.
- Validation: 34 tests, all-code GF(2), independent lattice checks, full
  regeneration, Linux CI and all six raw execution replays pass.
- Results: three known exact distances reproduced, three bounded timeouts;
  all six numeric intervals agree with source claims. No new scientific or
  performance claim.
- Unresolved: the last three exact distances are not reproduced within 60s;
  subsequent server timing, tier assignment and naming remain separate tasks.
- Scientific semantics changed: **no**.
- PI action required: **no** to finish the authorized work-branch package;
  main integration remains a separate approval.
