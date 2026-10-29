# GH-164: representative coverage and weight-8-check BB inputs

Issue: https://github.com/guluchen/DistQLDPC/issues/164
Branch: codex/weight8-bb-library
Base main: 346d1c681b0cd7063b69e3da17c7c714eafa5b71
Status: algebra/package validated; Linux evidence pending.

## Scope and proposals

The continuous goal is construction coverage, reproducibility and scientific
validation, not a solver optimization. Three proposals: weight-8-check BB
(published compact explicit polynomial parameters), hyperbolic surface codes
(missing geometric family; explicit quotient reconstruction needed), and
nonabelian ZSZ-LP (missing group structure; action/orientation checks needed).
Select weight-8 BB for this batch and retain the other gaps in
`docs/CSS_LIBRARY_COVERAGE.md`. The BB extension is not counted as a new family.
Existing GH-153/154/156/159/160 records informed the scope and the short-smoke
limitations. Active Mac-agent solver rounds are untouched.

Source: Lu-Yang-Guo arXiv:2609.06572v1, Tables 1-3. Case JSON records every
polynomial, grid and table row. Six published exact claims: [[72,14,8]],
[[72,4,10]], [[144,16,10]], [[144,10,12]], [[200,20,9]], [[200,8,10]]. No
extrapolation beyond the source's finite size range or third-party code/data.

## Changes and soundness

Original modular-translation generator Hx=[A,B], Hz=[B^T,A^T]; commuting
polynomial shifts imply Hx Hz^T=AB+BA=0 over GF(2). Separate dense Kronecker
validator reconstructs every check without importing the generator. Logical
bases use existing `compute_logicals.py --method bitset`. No solver, defaults,
Makefile or tiered data changes. Shared smoke gains optional `--engine cc`;
its default MaxSAT argv is unchanged. The existing twisted-torus test now
selects its six stems explicitly because the BB family contains two batches.

Same-(n,k) peer TN_72_14_4 is independently proved inequivalent. Both row-space
parity profiles happen to be even, so parity alone cannot distinguish them.
Pair-syndrome collision enumeration covers every support <=4 (each splits into
two subsets <=2). It excludes all nontrivial words in both BB halves; verified
TN supports [0,2,56,58] and [0,6,19,57] give upper bounds <=4. Distance is
invariant under all column permutations and X/Z exchange. See construction.json.
No other selected case has a same-(n,k) peer. General permutation-isomorphism
search is not claimed.

## Local validation (PI Mac, no solver run)

- `python3 scripts/codegen/weight8_bb.py --all --out /tmp/gh164-first`
- `python3 scripts/codegen/weight8_bb.py --all`
- `python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json`
- `python3 scripts/codegen/validate_weight8_bb.py --output optimization/experiments/GH-164/raw/construction.json`
- `python3 tests/test_codegen_{weight8_bb,twisted_torus,color666,hgp,cycle}.py`
  (execute each command separately; 9+9+10+8+7=43 tests).
- All 24 regenerated matrix files byte-identical; `git diff --check` passes.

Evidence in raw/: test outputs, algebra inventory (30 untiered, 81 total on
this branch), independent Kronecker/rank/equivalence certificate and regeneration.
Tests catch omitted transpose, wrong rectangular grid and failure to cancel
coincident GF(2) terms; short-word oracle is compared with literal enumeration
on 30 small random instances and tested to exclude stabilizer-only words.
Witness audit rejects stabilizers, invalid syndromes and malformed supports.

A first invocation of the smoke-selection unit preceded manifest insertion and
failed with 'unknown stem'; adding the six manifest rows resolved that ordinary
package-order error. Initial parity-only peer distinction was insufficient;
the exhaustive <=4 oracle above supplies the actual stronger evidence. Neither
was a distance disagreement or a change to solver scientific semantics.

## Linux smoke and retention plan

`.github/workflows/weight8-bb-library-smoke.yml`: build current main solver,
run units/algebra/independent construction and regeneration, then six default
MaxSAT and six independent CC 60-second checks, serial, one allocated CPU,
4 GiB address-space cap, stdin /dev/null and 90-second wall backstop. Both run
with -v to emit witnesses. Audit raw answer/bound agreement, all four matrix
hashes, common source/binary identity and every emitted witness directly in
GF(2), including stabilizer exclusion and a nonzero logical detector. Exact
results require a minimum-weight witness. Published claims and observations
remain separate. No cross-repo benchmark required: solver behavior is unchanged.

Source SHA, Actions IDs, binary hash, observed bounds and durable raw logs
will be appended after actual execution. NOT_RUN/partial bounds are not passed
numeric-bound gates. Any literature/result contradiction stops this batch and
is escalated. This batch has no heavy experiments; unresolved larger work
belongs in a reproducible dedicated-server package, never a longer CI sweep.

## Completion fields

What changed: coverage ledger, six inputs, original generators/validators,
manifest/provenance, tests and bounded Linux smoke/audit workflow.
Validation performed: local algebra, equivalence proof, 43 units, regeneration.
Results: local checks pass; solver evidence pending.
Unresolved issues: Linux smoke pending; main integration requires PI approval;
continuous construction-coverage goal remains incomplete.
Scientific semantics changed: no.
PI action required: no for continued work; yes before main integration.
