# GH-168: periodic square toric references

Issue https://github.com/guluchen/DistQLDPC/issues/168.
Branch codex/periodic-toric-library; base main6083e662c621f3b66defd434cfae31a028d483c4.
Status: all construction/independent graph-distance checks pass; first four CLI numeric gates pass. Largest two CLI numeric gates incomplete, three server jobs packaged but not executed.

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

Executed Linux: unchanged build,44 units, independent algebra/topology/source
parameter checks and matrix regeneration, bounded full graph oracle, then
six MaxSAT and six CC default60s checks, serial allocated core,4GiB,90s wall,
stdin /dev/null. Source/binary/input identities and raw logs retained.
Reuse our exact-claim/GF(2) witness audit with independent graph supports.
Source `cdc653e77e8f45f61c02ee8abbde35163827359d`.
Library [40851403211](https://github.com/guluchen/DistQLDPC/actions/runs/40851403211),
job123371502317: SUCCESS. Generic CI40851403210, job123371502384: SUCCESS.
Binary SHA256 `68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a`.
All24 matrices reproduce exactly;30 untiered/81 branch inventory entries pass
GF(2) checks. All12 raw/JSON/CSV results match, and previous24 manifest rows
are unchanged. Complete575804-character job log, both engine collections,
DONE/environments, all identities, graph distance JSON and audit are committed
under raw/actions/default/. Replay audit is byte-identical; no expiring-only
artifact dependency. Scientific review binds audit/distance digests and input
identities, retaining CLI gate status separately from graph exact results.

| L | n | independent graph (dX,dZ) | MaxSAT60s | CC60s | CLI numeric gate |
|---|---|---|---|---|---|
|3|18|(3,3)|exact3|exact3|PASS|
|8|128|(8,8)|exact8|exact8|PASS|
|13|338|(13,13)|exact13|exact13|PASS|
|18|648|(18,18)|exact18|exact18|PASS|
|27|1458|(27,27)|no numeric bounds|[25,27]|INCOMPLETE|
|38|2888|(38,38)|no numeric bounds|upper38 only|INCOMPLETE|

All six independent graph distances and minimum-weight supports agree with
Kitaev's general published proof. These are known distances reproduced by an
internal independent algorithm, not new results on previously open codes.
No contradiction or scientific escalation. Every printed solver word and
both graph supports per case pass GF(2) syndrome/stabilizer/detector checks.
The reusable raw audit's INCOMPLETE_INDEPENDENT_REPRODUCTION means the two
CLI engines did not both finish; it does not discard the separately retained
complete independent graph proof. Conversely that graph proof never fills
missing CLI numeric fields. Both largest numeric gates remain INCOMPLETE.
No extra CI sweep/longer limits or Mac solver execution used.

## Unexecuted server continuation

runner/jobs.jsonl contains only three missing-numeric engine jobs: MaxSAT1458
and both engines2888. Existing CC1458 numeric evidence is not rerun. Six-hour
CPU limits and600s wall backstops, serial4GiB/free allocated pinned core,
stdin /dev/null. Aggregate limits18h CPU/18h30m wall, not solve-time estimates.
No core assigned and no process launched. Runner defaults to dry-run, requires
yfclab2, clean frozen source and explicit PI allocation/free-core confirmation;
checks frozen inputs/binary before and after each job, retains raw evidence
before failure. Syntax, dry-run and exact job-regeneration checks pass.
See runner/README.md for commands. This packages remaining compute without
claiming the missing gate passed or changing solver behavior.

Completion fields: what changed: six periodic toric inputs and reproducible
generator/independent tests/provenance. Validation:44 units, full GF(2)/topology/logicals/duplicates,24-file regeneration, Linux internal graph oracle and12 engine smoke runs. Results: all six known distances independently reproduced; first four also exact in both CLI engines. Unresolved: two largest numeric gates and PI integration/server allocation.
Scientific semantics changed: no. PI action required: no to continue; yes
for main integration or server allocation. Prior hyperbolic n1920 question
remains a separate pending scientific decision, not implicitly approved.
