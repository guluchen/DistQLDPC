# GH-187: original SL2 quantum Margulis finite targets

Status: LOCAL_AND_LINUX_EVIDENCE_PASS; n2640 numeric gate INCOMPLETE; two independent-proof jobs unexecuted.
Issue https://github.com/guluchen/DistQLDPC/issues/187; hub claim6502254099.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/quantum-margulis-library. No PR requested/main integration.

## Three proposals and choice

1. CHOSEN: original finite SL(2,p) quantum Margulis2BGA instances from fixed
   integral conjugators. Fills useful missing provenance/group structure
   while individual exact distance remains unconfirmed. Risks: wrong left/
   right or inverse transpose, accidental PSL quotient, source-data identity,
   unsupported girth/decoder/distance or physical-product claims.
2. Static X-cube: separate remaining mainstream type-I fracton prescription;
   Haah Code1 does not cover it. Prioritize after open-distance targets.
3. Certified-expander HGP/cubical cosheaf: stronger source/hypothesis and
   practical-size gaps persist; generic finite instances do not replace them.

GH153..186 prior records/coverage/literature reviewed. GH186 has three
cross-checked distances, one missing numeric gate and three unexecuted proof
jobs; prior jobs/GH1651920 ambiguity remain open. Fresh remotes/open issues
show no competing Margulis topic; GH181/GH183 solver work and server cores
untouched. This is finite library construction, not Tier1..5 solver adoption
or a timing claim. Collection goal and PI integration remain separate.

## Source and frozen finite specification

Pacenti–Chytas–Vasic2503.03936v3, Quantum10,2101(2026),
DOI10.22331/q-2026-05-12-2101, Sec3 Eq8/Sec4 Eqs10–11, CC BY4.0. Full
authors/title/links/attribution in NOTICE/QUANTUM_MARGULIS.md. No author
implementation, matrix data, prose or images copied; no external group/
distance program. Original scripts/generated matrices GPL3+.

Only metadata/root listing of author repo Error-Correction-Lab/
quantumMargulisCodes at a25d3bad4682a207fc7df67edfd96dffe5ca4a5b was used;
no detected license/root LICENSE, so no matrix redistribution. Source p7
length642 conflicts with its formula2p(p^2-1)=672. We implement ORIGINAL
unambiguous formula-based instances, never identify them with that author
dataset, silently repair a source name or transfer its k/girth/decoder claim.
Specific author-instance reproduction would require PI interpretation;
the independent original mathematics used here is unambiguous.

Frozen before ranks/logicals/distance in #187: p5/7/11, eta8, four A and
four B integral conjugators exactly in quantum_margulis_cases.json. Each
C U C^-1 reduced modulo p gives the support, not randomized screening.
Even support4 forces an all-row dependency in each check matrix and k>=2;
actual k4/20/58 computed from the fixed choices without selecting on rank.
n240/672/2640, actual per-half ranks118/326/1291. No reselection for poor
or easy results. Actual supplied-basis uppers52/26/12 are independently
GF2-verified existing words, not presumed minima. No published individual
exact d or globally-open-problem claim from missing source values.

## Written soundness and independent checks

QUANTUM_MARGULIS.md proves Hx=[R(A) L(B)], Hz=[L(B)^T R(A)^T], with all
right/left maps commuting pointwise by associativity, including product
multiplicities. Thus Hx Hz^T=AB+BA=0 overGF2. Constructor matrix conjugation
is checked by a separate integral rank-one formula. Complete determinant1
enumeration, faithful vector permutations on Fp^2 minus0, central I/-I
distinction, every generator product/order/generation on both sides and
every16Gcommuting square are checked independently. No projective-line
action, exterior software or incomplete relator-only regularity argument.
All inverse transposes and every physical binary column, full GF2 ranks/
logicals/pairing/actual-word checks pass. No identity X/Z metric map assumed.

Physical connectivity uses the full typed stabilizer space(Hx,0)/(0,Hz)
in2n binary coordinates. Reduce first, then map Xq/Zq onto physical q.
One physical component for all cases excludes hidden product partitions.
Initial scalar-merging Hx+Hz diagnostic falsely rejected the first case
because it forgot Pauli type. Failed log retained as
raw/construction-first-failed.log. Corrected only this independent checker
and added explicit synthetic typed false-split/true-product mutants; no
matrix, source input, acceptance definition or scientific expectation
changed. Earlier scalar-connectivity passes are conservative sufficient
evidence, not invalidated by this false-rejection fix.

Fresh main/all published pending-library same(n,k) scan has no peer;
direct/swapped row-space checks and full inventory pass. Prior24manifest
rows/96matrices and51tiered inputs preserved. This branch27untiered/78total.

Commands:
```
python3 scripts/codegen/quantum_margulis.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-187/raw/certificates
python3 scripts/codegen/validate_quantum_margulis.py --out optimization/experiments/GH-187/raw/construction.json
python3 tests/test_codegen_quantum_margulis.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```

Mac generation/algebra/tiny units only, no solver/support distance search.
15new tests pass, with integral source/PSL collapse/identity/action/inverse/
binary-column/commuting-wrong-basis/typed false-split/hidden direct-sum/
false-upper/CLI selection mutants. Fresh12matrix+3complete-certificate byte
reproduction and overwrite guard pass. Prior34units pass,49total. Original
triangular COLOR6/HGP default12 and invalid family-stem workloads remain.
QMC added as explicit selector only, no solver/default change. Raw logs kept.

## Preregistered Linux gates and heavy completion

One unchanged build,49units, full independent inventory/construction compare,
12matrix+3certificate byte regeneration. Three selected default MaxSAT and
three CC calls,serial defaultseed,60sCPU/90swall/4GiB each,pinned allocated
ephemeral-runner CPU;12min total cap. No broad/repeated/supplemental
scientific CI, external/Mac solver or paid-cloud substitute. CI times are
diagnostic only; seed medians/ranges do not apply to single smoke calls.

Retain all raw/source/binary/input identities and actual witnesses. GF2-check
every printed/existing basis word; compare all intervals/exacts. Missing
numeric fields stay unavailable/INCOMPLETE, not filled from a word/source/
other engine. Exact answers need materialized verified minimum words.
One-engine new lower/exact values PLAUSIBLE until independent completion;
any contradiction stops for PI scientific review. No unknown-stem rename.

Heavy work becomes frozen unexecuted yfclab2 jobs6hCPU+600swall/4GiB,
serial defaultseed/verbose/pinned explicitly PI-allocated confirmed-free
core/nohup/nullstdin, actual-word/other-engine contradiction and full identity
guards. No core allocated/job run. No solver/build/default/tier/name/
QDistSAT/main/gh-pages/PR change. Independent work continues meanwhile.

## Terminal Linux evidence and frozen server package

Source ddace037c6027edee05b105a8c35224114d1fdbf, unchanged solver binary SHA256
68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Library run40912242015/job123583000824 SUCCESS:49units, independent full
construction/inventory comparison,12matrix+3fullcert byte reproduction,
all six serial60s engine attempts, actual-word and interval-consistency audit.
Ordinary source CI40912241813/job123583000629 SUCCESS.

| stem | default MaxSAT60s | CC60s | numerical gate | scientific status |
|---|---|---|---|---|
|QMC_240_4_unknown|[9,17]|17|PASS|CC-only17 PLAUSIBLE pending independent lower proof|
|QMC_672_20_unknown|8|8|PASS|exact8 cross-checked both engines and actual GF2 word|
|QMC_2640_58_unknown|no numeric fields|10|INCOMPLETE|CC-only10 PLAUSIBLE pending independent lower proof|

All actual supplied/printed words are independently verified. Initial basis
uppers52/26/12 are not confused with lighter observed physical upper words
17/8/10. Neither source absence nor one-engine completion proves a global
open-problem claim. No disagreement between available bounds/actual words.

Full job.log, all18 collected engine files, source/binary/input hashes and
actual-word audit are retained under raw/actions/default. Local replay:
```
python3 scripts/codegen/audit_quantum_margulis_smoke.py --maxsat optimization/experiments/GH-187/raw/actions/default/quantum_margulis-maxsat --cc optimization/experiments/GH-187/raw/actions/default/quantum_margulis-cc --construction optimization/experiments/GH-187/raw/construction.json --out /tmp/gh187-audit-replay.json
cmp optimization/experiments/GH-187/raw/actions/default/audit.json /tmp/gh187-audit-replay.json
```
Byte-identical PASS; full evidence is durable rather than artifact-only.
No timed-out field filled from CC, a source claim or a logical basis word.

runner/jobs.jsonl freezes two MaxSAT jobs n240/2640, actual verified upper
references17/10,6hCPU+600swall/4GiB each, seed0/verbose/serial pinned yfclab2.
Aggregate12hCPU/12h20mwall are configured LIMITS, not timing predictions.
No server allocation/run. Dry-run CPU54 is syntactic only; Mac execution
and altered -ub-pre=off argv tests reject without solver/output directory.
Raw guard logs retained; source/input/cases/job/argv/actual-word/other-engine
contradiction guards and materialized minimum-word requirement remain.

PI steering2026-10-30 recorded in CSS_LIBRARY_COVERAGE.md: after this batch,
prioritize reproducible individual codes with published intervals or only
heuristic estimates and genuine structural/size gaps. Known-distance X-cube
notes are deferred, not counted as an implemented/selected next batch.

## Completion fields

What changed: three reproducible original SL2 quantum Margulis2BGA inputs,
independent construction/logical/typed physical-space certificates, retained
Linux actual evidence, manifest/coverage and two frozen unexecuted proof jobs.
Validation performed:49local+Linux units, full source/group/action/column/
GF2/logical/actual-word checks,12matrix+3certificate byte reproduction,
six bounded Linux attempts, byte-identical local audit replay, runner guards.
Results: n672 cross-checked exact8; n240 CC-only17 and n2640 CC-only10
PLAUSIBLE. n2640 MaxSAT numeric INCOMPLETE; no contradictions observed.
Unresolved: two independent proof/numeric jobs; prior jobs and remaining
library coverage/unknown-distance targets; PI integration/allocation.
Scientific semantics changed:no.
PI action required:yes for integration/final names/tiers or server allocation;
routine construction/independent validation continue.
