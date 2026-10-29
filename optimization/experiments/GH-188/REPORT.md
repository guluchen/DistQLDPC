# GH-188: spatially coupled CSS unresolved-distance targets

Status: LOCAL_CONSTRUCTION_PASS; Linux and source-upper actual-word gates pending.
Issue https://github.com/guluchen/DistQLDPC/issues/188, hub claim6502716118.
Branch codex/spatially-coupled-library, fresh remotely verified main
6083e662c621f3b66defd434cfae31a028d483c4. No PR/main integration.

## Three proposals and choice

1. CHOSEN: periodic2D-SC-HGP, published Eq89 supports with fixed square
   periods2/4/5/7/10. Represents missing spatially coupled provenance and
   an actual published n5800 unresolved-distance example (upper estimate16).
   Risks: treating decimal labels as cyclic16, complement/inverse/transpose
   errors, source coordinate swaps, transferring source decoder/distance
   properties to original smaller periods, hidden product/duplicate copies.
2. DEFERRED: multivariate/trivariate bicycle2406.19151v3; z=xy in its chosen
   binary encoding is not an independent third cyclic group variable. Mostly
   source exact-table examples, lower priority for unresolved-distance work.
3. DEFERRED: static X-cube; separate remaining mainstream coverage gap,
   prospective finite disjoint-logical certificate, known-structure control.

Prior GH153..187 reports/coverage/literature reviewed. GH187 final evidence
4d2a62f1 and final CI40913637080 passed; one missing numeric/two proof jobs
remain separately open. Open issues and remote branch inventory checked;
no competing SC library topic. GH181/183 solver topics/server cores untouched.
PI priority2026-10-30: emphasize published intervals/heuristic-only estimates
and genuine structure/size gaps; no globally-open claim from a missing value.

## Frozen source, original reconstruction and soundness

Siyi Yang and Robert Calderbank, Spatially-Coupled QLDPC Codes,
arXiv2305.00137v6 (latest checked), Quantum9,1693(2025),
DOI10.22331/q-2025-04-07-1693, CC BY4.0. Eq58, Sec6.1 footnote2,
Table2 Code7/AppB Eq89. Full attribution/source/soundness proof in NOTICE
and SPATIALLY_COUPLED.md. No author implementation/matrix files, external
distance tools, paper text/images used. Original scripts/matrices GPL3+.

Five fixed periods2/4/5/7/10 and source3x7 partitions frozen in #188 before
ranks/logicals/distance; no resampling. Source labels d map to(floor(d/4),
d mod4) over C_L x C_L, not cyclic16. Hx=[I7 tensor A|bar(B)^T tensor I3],
Hz=[B tensor I7|I3 tensor bar(A)^T] are expanded as group-ring translations.
Explicit source X(j2,i1)/Z(i2,j1)/VV(j2,j1)/CC(i2,i1) coordinate swaps
relate the source tensor order to retained labels. A separate polynomial
Kronecker expansion proves this bijection. Independent backwards column
reconstruction agrees at every physical coordinate. Replica coincidences
through VV/CC both equal a-b=(m-b)-(m-a), proving GF2 commutation even
for aliased period2. Full ranks/logical quotients/pairing and actual words
pass. Typed full stabilizer RREF has one physical component for every case.

| L | n | actual k | rank each half | initial verified upper X,Z | source claim |
|---:|---:|---:|---:|---|---|
|2|232|88|72|4,2|no individual distance|
|4|928|280|324|12,4|no individual distance|
|5|1450|424|513|10,10|no individual distance|
|7|2842|808|1017|14,14|no individual distance|
|10|5800|1624|2088|70,20|Table2 Code7 estimated upper16|

Source k>=1600, not exact1600. The n5800 case exceeds approximate100–3000
by design to retain a genuine published unresolved-distance target. Smaller
periods inherit no decoder/cycle/distance guarantee; period2 alias/easy upper2
retained as control, not silently replaced. Basis words are actual checked
uppers, not minima. Source16 not yet materialized: its actual-word gate is
INCOMPLETE. Source/recent-result search found no independent exact proof
for this identified input; this search absence does not prove global openness.

## Local validation and retained engineering failures

Commands:
```
python3 scripts/codegen/spatially_coupled.py --all --certificates optimization/experiments/GH-188/raw/certificates
python3 scripts/codegen/validate_spatially_coupled.py --out optimization/experiments/GH-188/raw/construction.json
python3 tests/test_codegen_spatially_coupled.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```
Mac generation/algebra/tiny units only, no solver/support-distance search.
13new+34prior units pass, including20 tiny fixed-seed random polynomial
column/cancellation cases and source/hash/complement/wrong-commuting-basis/
logical/stabilizer-word/Pauli-type mutants. First-case4matrix+1fullcert byte
reproduction and overwrite guard pass; complete20matrix+5certificate
reproduction is preregistered for Linux. Explicit SC5 selection, original
HGP default12 and triangular COLOR6 workloads remain. No solver change.
Full29untiered/80inventory and all same(n,k) rowspace/XZ-swap checks pass;
no peer across27 pinned refs. Prior24rows/96matrices and51tiered inputs
preserved. All raw construction/units/inventory/peer receipts retained.

An initial macOS resource.setrlimit setup failed before matrix generation;
raw/macos-rlimit-first-failure.log retained. The attempted RSS monitor lacked
process-list access, while its spawned serial generator continued; inspected
the same live PID26049/child26067 rather than restarting. The observed final
logical-builder snapshot was330896KiB RSS plus18672KiB parent. A subsequent
attached monitor found it already terminal. No full-run RSS hard-cap/peak
claim is made. Generation completed all5cases, then independent algebra
passed; no data/parameters reselected and no Mac solver was invoked.

## Preregistered Linux and heavy completion gates

One unchanged solver build;47units; independent full source/construction/
inventory comparison;20matrix+5complete-certificate byte regeneration.
Five default MaxSAT and five CC attempts, serial defaultseed60sCPU/90swall/
4GiB each on allocated pinned ephemeral runner CPU,14min total cap.
No broad/repeated scientific CI, seed sweep or timing adoption claim.
Retain every raw/source/binary/input identity and actual GF2 witness.
Audit all intervals/exacts and source-upper actual-word gate. Missing numeric
fields stay INCOMPLETE; new one-engine lower/exact values PLAUSIBLE until
independent completion. Source-upper conflict or other scientific disagreement
stops for PI review. No stem rename.

Unfinished proof/numeric/source-upper work becomes exact frozen unexecuted
yfclab2 jobs6hCPU+600swall/4GiB/defaultseed/verbose/serial pinned explicitly
PI-allocated confirmed-free core/nohup/nullstdin. No server core allocated,
job run or paid-cloud substitute. Source numeric claims never fill missing
raw bounds. Integration/final names/tiers/QDistSAT remain PI decisions.

## Completion fields

What changed: five original reproducible periodic SC-HGP inputs including
a published unresolved-distance instance; source/provenance/soundness, full
independent columns/tensor-order/logical/actual-word and bounded gates.
Validation performed:47local units, independent construction/GF2/logicals/
actual words/typed physical space/inventory/peer checks and tiny byte
regeneration; full Linux gates pending.
Results: initial verified basis uppers2/4/10/14/20; n5800 published upper16
actual-word reproduction remains INCOMPLETE. No new exact result asserted.
Unresolved: Linux/regeneration/numeric/scientific completion, prior jobs,
remaining mainstream/unknown-distance coverage and PI integration.
Scientific semantics changed:no.
PI action required:yes for integration/names/tiers/server allocation;
routine construction/independent validation continue.
