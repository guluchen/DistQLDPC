# GH-188: spatially coupled CSS unresolved-distance targets

Status: LOCAL_AND_LINUX_EVIDENCE_PASS; source-upper word PASS; n5800 numeric gate INCOMPLETE; two independent-proof jobs unexecuted.
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
uppers, not minima. Source16 was not materialized at the construction checkpoint. Linux CC
subsequently supplied an actual verified weight16 word, so that gate is PASS. Source/recent-result search found no independent exact proof
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

## Terminal Linux evidence and frozen completion jobs

Source615470fa26f6be950a4738a6244a33640da2c04b; unchanged solver binary SHA256
68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Library run40915696103/job123595188679 SUCCESS:47units/full construction/
inventory comparison,20matrix+5complete-certificate byte regeneration,
all10serial defaultseed engine attempts under60sCPU/90swall/4GiB/pinned
allocated runner CPU, actual-word/source/binary/input identity audit.
Ordinary source CI40915695967/job123595188171 SUCCESS.

| n | MaxSAT60s | CC60s | numeric gate | scientific status |
|---:|---|---|---|---|
|232|2|2|PASS|cross-checked exact2 with actual GF2 word|
|928|4|4|PASS|cross-checked exact4 with actual GF2 word|
|1450|8|8|PASS|cross-checked exact8 with actual GF2 word|
|2842|[6,14]|14|PASS|CC-only14 PLAUSIBLE, independent lower proof pending|
|5800|no numeric fields|16|INCOMPLETE|CC-only16 PLAUSIBLE, independent lower proof pending|

All supplied/printed physical words pass independent GF2. The actual CC
word16 for n5800 reproduces the published upper estimate, so its separate
source-upper actual-word gate is now PASS. Initial basis20 is retained as
an initial certificate, not a minimum. No disagreement among SC results.

Full480769-character job.log, all26collected engine files/metadata/input
identities and actual-word audit retained in raw/actions/default. Local
replay command and byte-identical comparison:
```
python3 scripts/codegen/audit_spatially_coupled_smoke.py --maxsat optimization/experiments/GH-188/raw/actions/default/spatially_coupled-maxsat --cc optimization/experiments/GH-188/raw/actions/default/spatially_coupled-cc --construction optimization/experiments/GH-188/raw/construction.json --out /tmp/gh188-audit-replay.json
cmp optimization/experiments/GH-188/raw/actions/default/audit.json /tmp/gh188-audit-replay.json
```
No CLI missing numeric fields filled from another engine, source or word.
These are finite correctness/bounds observations, not dedicated-server timing.

runner/jobs.jsonl freezes two MaxSAT jobs n2842/5800 with actual verified
upper references14/16,6hCPU+600swall/4GiB each, defaultseed0/verbose/serial
pinned explicitly PI-allocated confirmed-free yfclab2 core/nohup/nullstdin.
Aggregate12hCPU/12h20mwall are configured LIMITS, not ETA. No server
allocation/run. Dry-run CPU54 is syntactic only; Mac execution and changed
-ub-pre=off argv guards reject without solver invocation/output directory.
Source/input/cases/job/argv/actual-word/other-engine contradiction guards,
unchanged solver/build check and materialized minimum-word requirement remain.

## Held next-source review and remaining coverage

While the same SC Linux job ran, primary-source research identified a missing
general pin-relation construction and practical upper-only APM candidates.
Original fixed published-word arithmetic checks exposed a source Z-witness
mismatch for APM C1: two independent implementations give22 odd X checks;
PDF/latest v1 and both row/column conventions checked. Published X word10
passes in the explicit companion row convention, so the overall upper10 is
not refuted. No APM matrix files/new family inputs or distance search added.
Exact evidence, one-check counterexample and reproducible scripts retained
in NEXT_SOURCE_REVIEW.md/source_checks/raw. Source interpretation held for
PI review under AGENTS scientific boundaries; no external communication or
silent witness repair. Unambiguous library work can continue independently.

## Completion fields

What changed: five reproducible periodic SC-HGP inputs including a published
upper-only instance, full independent construction/physical/logical evidence,
retained Linux actual results and two frozen unexecuted completion jobs;
updated genuine coverage gaps and held APM-source review evidence.
Validation performed:47local+Linux units, all source/column/tensor-order/
GF2/logical/actual-word checks,20matrix+5fullcert byte regeneration,
10bounded Linux attempts, byte-identical local audit replay, runner guards.
Results: both engines exact2/4/8 at n232/928/1450; CC-only14/16 at n2842/
5800 PLAUSIBLE. n5800 source upper16 word PASS; MaxSAT numeric INCOMPLETE.
Unresolved: two independent-proof/numeric jobs; APM source interpretation;
prior jobs, general pin/X-cube/certified-expander/cosheaf and other coverage.
Scientific semantics changed:no.
PI action required:yes for integration/final names/tiers/server allocation
or APM source-interpretation decision; other routine library work continues.
