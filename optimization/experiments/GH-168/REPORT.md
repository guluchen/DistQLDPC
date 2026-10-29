# GH-168: periodic square toric references

Issue https://github.com/guluchen/DistQLDPC/issues/168.
Branch codex/periodic-toric-library; base main6083e662c621f3b66defd434cfae31a028d483c4.
Status: local generation/algebra/topology/44-unit validation passes; Linux full distance and solver smoke pending.

Three proposals: SELECTED periodic toric, triangular4.8.8 color variant,
higher-dimensional toric. The selected round closes a genus-one periodic
topology gap, complements planar HGPk1 and provides known-distance scaling
references. Risk: seam indexing, detector convention, duplicate equivalents.
Prior GH-153/154/156/159/160/164/165/166/167 records inform source/provenance,
short limits, independent algorithm and durable evidence requirements.

Six fixed instances L3,8,13,18,27,38, n2L^2,k2,dL. Proposed prefix TOR,
unknown stems. Source Kitaev quant-ph/9707021v1 Sec.1 Eq.(1), all-L
construction, not a finite example table. Original mathematical implementation
only, no third-party code, matrix files or distance tools. Source arXiv
perpetual/nonexclusive license; no source text copied. Original code/data
GPL3+, attribution in NOTICE. One construction per branch, no solver/default,
tiered benchmark, QDistSAT or main integration changes.

Written commutation/rank/distance and signed-cover oracle soundness proof in
TORIC.md. Independent column incidence, primal/dual connected cellulation,
face cycles/vertex links/Euler characteristic, ranks and GF(2)/logical checks.
All four winding logicals and intersection matrix independently validated.
Signed-cover all-root/detector BFS distance oracle runs on Linux only for
the full size ladder; Mac unit checks use tiny cases. It verifies actual
GF(2) supports; never substitutes its distance for absent CLI output.

No same-(n,k) peers in current main or pending work branches. Pinned branch
identities in raw/pending-branch-peers.json. Generator refuses overwrite.

Local commands (no DistQLDPC solver execution):
- `python3 scripts/codegen/toric.py --all`
- `python3 tests/test_codegen_toric.py`
- `python3 scripts/codegen/validate_toric.py --output optimization/experiments/GH-168/raw/construction.json`
- `python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json`
- full fresh generation with byte comparison of24 matrices; old24 manifest
  parsed rows unchanged. Existing34 generator tests run alongside new10.

Planned Linux: unchanged build,44 units, independent algebra/topology/source
parameter checks and matrix regeneration, bounded full graph oracle, then
six MaxSAT and six CC default60s checks, serial allocated core,4GiB,90s wall,
stdin /dev/null. Source/binary/input identities and raw logs retained.
Reuse our exact-claim/GF(2) witness audit with independent graph supports.
Actual source/run/job IDs, bounds and verdicts follow execution. Any missing
numeric gate remains open; heavy work becomes unexecuted server package.

Completion fields: what changed: six periodic toric inputs and reproducible
generator/independent tests/provenance. Validation: pending final local/Linux
checks. Results: pending. Unresolved: numeric gates and PI integration.
Scientific semantics changed: no. PI action required: no to continue; yes
for main integration or server allocation. Prior hyperbolic n1920 question
remains a separate pending scientific decision, not implicitly approved.
