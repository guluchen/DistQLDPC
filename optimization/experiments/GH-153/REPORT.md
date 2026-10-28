# GH-153: repetition-product HGP library

Date: 2026-10-28 (Asia/Taipei). Issue: https://github.com/guluchen/DistQLDPC/issues/153.
Base: `e52d15baa7a430104329d20467c12375fe60f0f2` (main).
Branch: `codex/hgp-repetition-library`. Status: **GF(2) VALIDATED; SOLVER SMOKE PENDING**.
This is a library addition, not a solver optimization or performance experiment.

## What changed

- Original standard-library generator for the repetition-code specialization of
  the Tillich-Zemor hypergraph product; proposed new family prefix HGP.
- Six untiered codes, each with k=1: n=13,41,113,265,481,1105.
  Claimed exact distances 3,5,8,12,16,24 follow from Theorem 1 of
  arXiv:0903.0566v2, applied to [L,1,L] repetition factors. No new scientific
  distance is claimed. Stems retain `_unknown`.
- Manifest, source/license attribution, construction/order documentation,
  independent bitset verifier, tests, input SHA-256s and Linux smoke package.

Three proposals were recorded before implementation in #153: repetition-HGP
(selected: known-distance ladder), cyclic repetition toric (deferred), and
non-repetition finite-rate HGP (deferred). Existing open issues and remote
branches were inspected; no library-topic overlap. Hub #15 links #153.
Read AGENTS.md, optimization policy and the relevant literature context.
No solver/defaults/tiers or existing matrix bytes changed; no QDistSAT mirror.

## Validation performed

Environment: PI Mac, macOS, system Python 3.9, standard library only.
Only code generation and deterministic engineering tests were run; no
DistQLDPC solver process, external solver or timing experiment was started.

Commands from repository root:

```sh
python3 scripts/codegen/hgp_repetition.py --ladder
python3 scripts/codegen/hgp_repetition.py --ladder --out /tmp/distqldpc-gh153-regeneration
python3 tests/test_codegen_hgp.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 scripts/codegen/smoke_untiered.py --cpu 54 --out /tmp/not-executed --dry-run
git diff --check
```

The dry-run CPU value is an example only; core 54 was neither requested nor used.
`raw/smoke-dry-run.json` is a command inventory, not executed solver evidence.
No binary identity, solver bounds, medians, seed ranges, tier verdicts or
performance claims exist for these inputs yet (all NOT APPLICABLE / NOT RUN).

Evidence:

- `raw/unit-tests.log`: unit checks, tiny exhaustive supports for L=2,3 in both
  CSS quotients, deterministic random relabelings and check-basis changes,
  strict parsing, and corruption mutants (broken commutation, stabilizer used
  as logical, dependent logical quotient, invalid logical kernel membership).
- Duplicate fixtures detect row-equivalent checks after row operations,
  both directly and with X/Z swapped.
- Straight weight-L witnesses in both halves of all six bundled codes are
  independently checked for zero syndrome, non-stabilizer membership and odd
  mutual pairing. These verify upper witnesses; the cited theorem supplies
  the matching mathematical lower bound.
- `data/matrices/untiered/validation.json` and `raw/validation.log`: all six
  pass commutation, dimension/rank, complete logical-quotient bases and pairing.
  Inventory is 51 existing + 6 new. No same-(n,k) peers exist, so there are no
  candidates for rowspace or column-permutation duplication in this snapshot.
- `raw/regeneration.log`: every one of 24 regenerated matrix files is byte
  identical; SHA-256s retained. The validation report also reproduces exactly.
- Smoke-parser fixtures reject contradictory numeric bounds/answers, withdrawn
  final bounds and missing output. Linux runner dry-run passes on macOS.

Initial test attempt found a Python compatibility issue (`int.bit_count` is
unavailable on this host's Python); replaced it by portable population counts.
The failure did not involve a scientific result or solver execution.

## Results and unresolved issues

The matrix/library construction and reproducibility checks pass. The required
60-second DistQLDPC loading/bound checks are **not yet run** because the handoff
reserves the PI Mac and no dedicated-server core is allocated to this task.
Manifest smoke fields are empty with explicit NOT_RUN status. Do not interpret
claimed_d or GF(2) validation as completed solver validation.

The Linux execution package, exact commands, limits and evidence destinations
are documented in `data/matrices/untiered/README.md`. After a PI-assigned free
core is available, run the six jobs serially (at most six 90-second wall
backstops), retain raw output, check it against the mathematical ground truth,
then update the manifest with observed bounds. Any contradictory result stops
the sequence and requires scientific escalation. Tier timing is separate work.

No PR opened: the handoff says to open a PR only when asked. No merge attempted.

- Scientific semantics changed: **no**.
- PI action required: **yes** — assign an authorized smoke environment/core,
  then review the proposed HGP prefix and request a PR when ready. Merge of
  benchmark data requires explicit PI approval.
