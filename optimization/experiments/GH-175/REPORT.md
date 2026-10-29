# GH-175: periodic4D toric CSS size ladder

Status: CONSTRUCTION_AND_TWO_INDEPENDENT_CERTIFICATES_PASS; Linux smoke pending.
Issue: https://github.com/guluchen/DistQLDPC/issues/175 (hub15 claim6496620342).
Baseline: main6083e662c621f3b66defd434cfae31a028d483c4.
Candidate: codex/toric4d-library, source commit recorded after push.
No PR requested; no main integration authorized for this round.

## Proposals and choice

1. Add periodic4D face-qubit toric codes; expect practical n96..3000 and
   membrane distance4..20, constant-weight checks. Risk: face orientation,
   periodic incidence and both-half lower-bound proof. CHOSEN.
2. General Bravyi-Hastings homological products: broader construction, but
   finite source/parameter/proof availability requires further research.
3. Covering-graph BB: useful source provenance specialization; defer until
   graph-cover parameters are extracted rather than duplicating a BB label.

Prior records read: GH-164..174 work-branch reports and coverage ledger;
GH-168 supplies periodic2D topology, GH-173 negative distance-growth evidence
and GH-174 conditional LDPC-factor ladder. This round adds4D topology rather
than repeated BB samples or disconnected copies. No performance hypothesis,
solver adoption or Tier1..5 optimization gate is claimed.

## Change and source

Six fixed shapes in scripts/codegen/toric4d_cases.json; original constructor,
24 matrices, shared unchanged logical builder, manifest, independent column
incidence and two both-half matrix-certificate implementations,12 tiny units
including meaningful proof mutants, audit, provenance and branch-filtered CI.
Proof and license boundary: data/matrices/untiered/TORIC4D.md.
Source: Breuckmann-Duivenvoorden-Michels-Terhal1609.00510v2 Sec.2/Fig.1,
QIC17(3-4),181–208(2017). Only cubic [[6L^4,6,L²]] is a published exact family.
Three rectangular cases are original extensions: claimed_d keeps upper-only
individual metadata. Separately verified exact certificates do not invent a
publication claim. No external code, matrix or distance solver used.

## Local validation

Commands:
```
python3 scripts/codegen/toric4d.py --all --out data/matrices/untiered
python3 scripts/codegen/validate_toric4d.py --output optimization/experiments/GH-175/raw/construction.json
python3 scripts/codegen/verify_toric4d_certificate.py --out optimization/experiments/GH-175/raw/independent-receipt-check.json
python3 tests/test_codegen_toric4d.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 scripts/codegen/toric4d.py --all --out /tmp/gh175-fresh
```

Mac: generation/algebra/tiny randomized proof-unit checks only, no DistQLDPC
execution, no source support search and no timing experiment. First10 units
passed; two standalone-verifier tests subsequently added and12 rerun.
Full inventory:30 untiered+51 tiered. Preserve all prior24 manifest rows and
96 matrix bytes. Same-(n,k) direct/swapped row spaces checked by validate_css;
remote work-branch peer identities in raw/cross-branch-peers.json: no match.
Fresh regeneration:24 files byte-identical. No guessed equivalence discarded.

Both-half exact certificates: n96->4,324->6,486->9,1152->12,1536->16,3000->20.
The primary verifier reconstructs columns and uses high pivots/bitsets; the
standalone verifier imports no constructor/primary/shared algebra or solver,
uses low pivots/column syndromes/set packing on every retained support.
Actual quotient completeness, full pairing, disjointness and row-space
homology prove the lower bounds; actual GF(2) words attain both upper bounds.
Rectangular derived results have this independent implementation cross-check;
no stronger scientific claim relies on a single C++ search. Raw CLI fields
remain distinct; certificates never fill missing numeric smoke bounds.

## Linux validation plan and limits

One source build of unchanged solver. Prior34 library units plus12 new units,
complete inventory/certificate byte comparisons and24-file fresh regeneration.
Six selected default MaxSAT and six CC calls, each serial60CPU seconds,
one runner-affinity pinned core,4GiB address cap,90s wall backstop, seed default.
No supplemental calls, parameter sweep, paid cloud, Mac solver or server job.
The20min job cap covers at most12minCPU plus build/checks. Shared-host timing
is diagnostic only; no medians, seed ranges or speedup verdict apply.
All raw outputs including timeouts/failures retained durably; actual hashes
bind source, binary and four matrices. Audit rechecks every physical word and
all numeric bounds/exact answers against independent certified distance.
Any contradiction is a scientific escalation. Missing numeric fields remain
INCOMPLETE rather than a fabricated certified interval.

## Completion fields

What changed: six periodic4D toric inputs, reproducible generator and checks.
Validation: local construction/two independent certificates pass; Linux pending.
Results: both-half mathematical distances4,6,9,12,16,20.
Unresolved: Linux numeric gates; broader homological products remain open.
Scientific semantics changed: no.
PI action required: yes, main integration/tiering/final names and server core
allocation if incomplete C++ checks need heavy completion; none allocated.
