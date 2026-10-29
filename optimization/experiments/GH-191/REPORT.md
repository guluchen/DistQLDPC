# GH-191: published interval-valued GB references

Status: LINUX_NUMERIC_AND_ACTUAL_WORD_GATES_PASS; independent lower proofs pending.
Issue https://github.com/guluchen/DistQLDPC/issues/191; hub6504120701.
Branch codex/open-reference-gb-library from remotely verified main
6083e662c621f3b66defd434cfae31a028d483c4. No PR/main integration.
Previous goal turn made progress: GH190 completed Linux evidence retention,
byte-identical replay, frozen one numeric job, workbranch push and final
CI40924040928 SUCCESS at57be1e42. Goal remains active; PI priority now
individual exact-distance-unconfirmed codes rather than quantity expansion.

## Proposal, source and frozen selection

CHOSEN: PK2021 GB A1/A5 add published interval-valued reference targets;
expected useful open search gaps at moderate n, risk source transpose,
logical convention or unsupported upper claims. DEFERRED separate GHP
B1/B3 batch requires full matrix extraction. DEFERRED UB TableI proof status
cannot be silently downgraded to heuristic to create apparent unknowns.
Open issues/two pages of branches checked, no competing topic; all30pinned
library/main refs checked for same(n,k), none. No contact with outside authors.

Panteleev–Kalachev1904.02703v3 latest checked, Quantum5,585(2021),
DOI10.22331/q-2021-11-22-585, Sec4.2 first-column convention/AppendixB
sectionA/Table1. CC BY4.0 source, original GPL3+ mathematics-only scripts;
full title/authors/attribution NOTICE and REFERENCE_GB.md. No third-party
code/matrices/prose or external distance tools. A1 remains interval-valued
in Rabeti–Mahdavifar2605.14173v1 SecV; targeted source searches not proof
of global-open status. No parameter screening/reselection; fixed in issue
before generation and any ranks/distance observation:

| item | n | k | l | a | b | published interval |
|---|---:|---:|---:|---|---|---|
|A1|254|28|127|0,15,20,28,66|0,58,59,100,121|14..20|
|A5|180|10|90|0,28,80,89|0,2,21,25|15..18|

## Construction and local gates

Row-translation constructor versus independently enumerated physical columns;
set-polynomial common divisor degree14/5 agrees with binary rank113/85
both halves. Full GF2/logical quotients/pairing, actual typed physical RREF
connectivity and actual X/Z reflection/block-swap weight map pass. No new
lower bound, pruning rule or solver semantics introduced.

```
python3 scripts/codegen/reference_gb.py --all
python3 scripts/codegen/validate_reference_gb.py --out optimization/experiments/GH-191/raw/construction.json
python3 tests/test_codegen_reference_gb.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```
13newunits pass, including50tiny randomized physical-column reconstructions,
source/commuting-wrong-matrix/logical/entry/support mutants, actual-word and
source-interval contradiction guards, missing-number preservation, full
8matrix byte regeneration, overwrite/invalidfamily/default HGP12/GB2selection.
Actual computed basis uppers X/Z48/56 and36/37 verify in GF2. These are
not yet materialized source-upper20/18 words; keep that gate pending.
26untiered/77inventory pass, no direct/swapped duplicate. Prior24manifest
rows and300matrix files unchanged. Mac construction/algebra/tiny tests only.

## Preregistered Linux gates

One unchanged Linux build,13new+34prior units/full construction/inventory
byte compare and8matrix regeneration. Two default MaxSAT+two CC attempts,
serial60sCPU/90swall/4GiB/defaultseed/pinned allocated Actions CPU;10min cap.
Retain complete logs/argv/source/binary/input identities and verify actual
printed words against actual matrices. Published intervals constrain
contradiction review, never initialize independent lower/upper result fields.
Missing raw bounds stay INCOMPLETE; actual source-upper word gate separate.
Unmatched single-engine lower/exact results remain PLAUSIBLE. Two complete
independent engines plus actual minimum word required for cross-checked exact.
No repeated scientific CI for timeouts/full tiers/seed sweeps/adoption timing.
Heavy proof/numeric completions freeze defaultseed0/verbose6hCPU+600swall/
4GiB/serial pinned yfclab2 packages, with verified actual upper reference,
requiring explicit PI allocation/free-core checks/nohup/nullstdin. Configured
limits are not ETA; no server core allocated or paid-cloud substitute.

## Terminal Linux evidence

Data732eb0849dfd14a433f9086518dcf31b615577dd;
source9588fc5ed120c57bf9bdc4588c52022e48e01bc9,
treecdd63f1d239aee4fb433c925e1ebd9d99eefc072.
[Library run40925199585](https://github.com/guluchen/DistQLDPC/actions/runs/40925199585),
job123628715707 completed SUCCESS, every step including audit/retention/upload.
Ordinary sourceCI40925199561 completed SUCCESS. Unchanged solver binary SHA256
68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
47units/full independent construction/inventory comparisons and8matrix byte
regeneration pass. Exact commands in source-pinned workflow. Four one-time
serial60sCPU/90swall/4GiB/defaultseed/pinned allocated runner CPU attempts,
10min cap. No performance/median/tier adoption inference from shared timing.

| stem | MaxSAT raw60s | CC raw60s | actual GF2 upper | numeric/word gates |
|---|---|---|---:|---|
|GB_254_28_unknown|[10,20]|[16,20]|20|PASS/PASS|
|GB_180_10_unknown|[9,18]|[17,18]|18|PASS/PASS|

Actual printed upper words20/18 reproduce source upper claims, verified
against both actual parity/stabilizer quotient/detector conditions. Full
printed word histories retained, not replaced by basis uppers48/36. No
contradiction. Published14/15 lower claims stay separate from our raw
MaxSAT10/9 and CC16/17. The raised CC lower16/17 is PLAUSIBLE pending an
independent proof/search; do not rename stems or claim certified improvement
from one engine. No exact answer. Both numeric gates complete; no synthetic
bound filled from source or another engine.

Durable raw/actions/default/job.log has342080characters,14engine files
(two logs/two metadata/environment/results/DONE per engine),audit.json.
Local replay (no solver) is byte-identical:
```
python3 scripts/codegen/audit_reference_gb_smoke.py --maxsat optimization/experiments/GH-191/raw/actions/default/reference-gb-maxsat --cc optimization/experiments/GH-191/raw/actions/default/reference-gb-cc --construction optimization/experiments/GH-191/raw/construction.json --out /tmp/gh191-audit-replay.json
cmp /tmp/gh191-audit-replay.json optimization/experiments/GH-191/raw/actions/default/audit.json
```
Four unfinished proof jobs frozen in runner/jobs.jsonl, one MaxSAT+one CC
per case, defaultseed0/verbose,6hCPU+600swall/4GiB/serial pinned explicit
PI-allocated confirmed-free yfclab2 core/nohup/nullstdin. Actual upper
references20/18, source/other-engine/word contradiction guards. Total24hCPU/
24h40mwall configured LIMITS, not ETA. No core allocated/server execution.
Dry-run, Mac and altered-argv refusals pass with no solver/output directory;
CPU54 syntax only. No repeated scientific CI to fill proof gaps.

## Completion fields

What changed:2 reproducible GB interval references, independent source/
GF2/physical/logical checks, actual-word audit/provenance and durable Linux
evidence;4frozen proof jobs; next independent source notes.
Validation performed:47units/full actual columns/gcd/ranks/logicals/typed
space/XZ map/30pinned peers;8matrix byte reproduction;4bounded Linux attempts
and byte-identical local actual-word audit replay. Prior24rows/300matrices
and solver/build preserved.
Results: actual verified uppers20/18; MaxSAT raw[10,20]/[9,18], CC raw
[16,20]/[17,18]. All numeric/actual-word gates PASS, no exact distance.
Unresolved: CC raised lower16/17 PLAUSIBLE pending independent proof;
4proof jobs, earlier packages/APM hold/stronger finite-expander/cosheaf gaps
and PI integration. Goal continues with interval-valued GHP source review.
Scientific semantics changed:no.
PI action required:yes for integration/tier/name/server allocation or prior
scientific hold; routine safe collection/research continues.
