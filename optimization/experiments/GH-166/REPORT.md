# GH-166: nonabelian ZSZ-LP representative library

Issue: https://github.com/guluchen/DistQLDPC/issues/166
Branch: codex/zsz-lp-library
Base main: 6083e662c621f3b66defd434cfae31a028d483c4.
Status: ACCEPTED AS SIX-INPUT UNTIERED LIBRARY PACKAGE; all construction and numeric smoke gates pass. Stronger single-engine scientific lower bounds remain PLAUSIBLE; optional exact-proof jobs prepared, not executed.

## Proposals and scope

Three proposals: (1) SELECTED: Hong 2607.27644v1 nonabelian five-block ZSZ-LP
codes, (2) new finite-group Quantum Tanner examples, (3) pair-partition/group
constructions. Selected because all group and polynomial parameters are
explicit and nonabelian product structure was missing from prior coverage.
Keep existing LP prefix; do not inflate family counts by renaming a subclass.
References: Eqs.1,5-10,13, Tables 1 and 3. Prior GH-153/154/156/159/160/164/165
records informed independence, claim handling, raw retention and short limits.
GH-165 n=1920 PI interpretation question and n=1800 numeric smoke gap remain
open. No approval is inferred from silence; this family is independent.

Six data codes, n=160,240,320,390,550,775, k=n/5. Published exact d=10,12,14
for first three; heuristic QDistEvol upper estimates <=16,<=18,<=22 for last
three. Do not use fold-symmetric n=390 <=15 or surgery/gauge projections.
No third-party implementation, data files, paper text or distance solver used.
Original mathematics-based generation is GPL-3.0-or-later, recorded in NOTICE.

## Implementation and correctness

Direct semidirect group multiplication with q^l2=1 mod l1; separate left/right
column actions, transposes, exact five-block CSS form. Commuting actions from
associativity imply every Hx Hz^T block vanishes. Full rank classical [A B]
and [C D] seeds imply both quantum ranks 2l, hence k=l. Full CSS homology
retained. Gx/Gz from existing compute_logicals.py --method bitset. Written
formulas and soundness derivation in untiered/ZSZ_LP.md.

Independent validator builds elementary x/y permutations, applies canonical
monomial powers and assembles dense blocks; no generator or logical-builder
imports. Independently checks noncommutativity, left/right generator commuting,
seed ranks, check weight 9, qubit degree {3,6}, GF(2)/logical quotient/pairing.
No same-(n,k) peers in current tiers/untiered or completed pending GH-160,
GH-164, GH-165 branches; identities retained in raw/pending-branch-peers.json.

Shared smoke collector reuses the tested GH-160 exact-vs-upper parser and
optional explicit engine flag; default MaxSAT argv is unchanged. Newly accepted
LP family is isolated in manifest selection. Exact reference means all output
bounds/answers must include/equal d; upper reference allows weaker observed
upper bounds and exact answers below the estimate, rejects a lower bound or
answer exceeding it. Actual reference-upper witness reproduction is explicit
in the independent audit, never inferred from a literature estimate.
No solver, defaults, Makefile or tiered matrices changed, so this is not a
solver optimization/adoption or cross-repo timing experiment.

## Local validation (Mac, no solver run)

- `python3 scripts/codegen/zsz_lp.py --all --out /tmp/gh166-first`
- `python3 scripts/codegen/zsz_lp.py --all`
- `python3 scripts/codegen/validate_zsz_lp.py --output optimization/experiments/GH-166/raw/construction.json`
- `python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json`
- test_codegen_zsz_lp.py (11), twisted_torus (9), color666 (10), hgp (8),
  cycle (7): 45 tests pass. Raw outputs in raw/.
- All 24 matrix files regenerate byte-identically. 30 untiered / 81 total
  inventory entries pass shared GF(2)/logical/duplicate checks.
- `git diff --check` passes.

Tests catch abelian replacement, wrong/noncommuting action, invalid group
parameter, lost GF(2) collisions, invalid support/syndrome/stabilizer witnesses,
misclassifying a heuristic upper estimate as exact, inconsistent bounds and
source-specific fixture audit errors. Exhaustive 32-element associativity and
50 deterministic random triples per larger group; inverse and presentation
checks. Synthetic fixture evidence is confined to tests, not scientific logs.

## Linux plan and evidence

Workflow zsz-lp-library-smoke.yml: build unchanged solver; 45 tests,
independent algebra/reconstruction, byte-identical regeneration, six MaxSAT
and six CC runs, serial 60s each on one allocated core, 4 GiB cap and 90s wall
backstop, stdin /dev/null. Audit raw/JSON consistency, all matrix hashes,
common source/binary, actual witness syndrome/stabilizer/detector membership,
claim semantics and independent exact-answer agreement. Witness absence is
not replaced with a fictitious word. New exact result initially PLAUSIBLE;
only two engine completions plus a verified minimum word cross-check it.
All raw evidence printed in workflow log and archived durably in this branch.
Partial/no bounds remain incomplete gates even if workflow execution succeeds.
Long work must become an exact unexecuted dedicated-server package, not more
CI time or a parameter sweep. No Mac solver run or assigned server core.

Source SHA, Actions IDs, binary/input identities and actual numerical results
will be appended after execution. Source literature claims remain separate.

## Completion fields

What changed: six representative nonabelian LP inputs, original generator,
cases, independent validator, shared claim/witness helpers, provenance,
manifest, tests and bounded Linux workflow.
Validation performed: local generation, independent GF(2)/group/action/rank/
logical/pairing/duplicate checks, 45 units and byte-identical regeneration.
Results: all local/Linux numeric gates pass; exact d=10,12 cross-checked by both engines, CC reproduces published d=14; all heuristic upper witnesses independently verified.
Unresolved issues: stronger CC-only lower bounds and remaining exact proofs need independent completion; prior hyperbolic open items remain; main integration/server allocation need PI.
Scientific semantics changed: no.
PI action required: no for continued work; yes before main integration or
any dedicated-server execution; prior n=1920 interpretation remains pending.

## Actual Linux evidence and scientific verdict

Tested source 1fb9ba1d535c2a6936c9ac86ccb82e2d0dcc2a43. Library workflow
https://github.com/guluchen/DistQLDPC/actions/runs/40843413324,
job 123345015971, SUCCESS. Generic CI 40843413165, SUCCESS.
Binary SHA256 68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
All twelve input/source/binary identities, argv, environment, raw outputs,
CSVs, exact/witness audit and full job log retained in raw/actions/default/.
Every raw/CSV/JSON result and matrix hash rechecked; audit replay is
byte-identical to the actual CI audit. Published claims remain separate.

| stem | published claim | MaxSAT 60s | CC 60s | numeric gate |
|---|---|---|---|---|
| LP_160_32_unknown | exact 10 | exact 10 | exact 10 | PASS |
| LP_240_48_unknown | exact 12 | exact 12 | exact 12 | PASS |
| LP_320_64_unknown | exact 14 | [9,14] | exact 14 | PASS |
| LP_390_78_unknown | heuristic <=16 | [9,16] | [15,16] | PASS |
| LP_550_110_unknown | heuristic <=18 | [9,18] | [16,18] | PASS |
| LP_775_155_unknown | heuristic <=22 | [9,22] | [16,22] | PASS |

n=160 and 240 are CROSS_CHECKED_TWO_ENGINES_AND_GF2_WITNESS, reproducing
published exact distances. n=320 reproduces published d=14 with CC and a
verified weight-14 word, but independent MaxSAT completion remains pending;
label the current independent-reproduction status PLAUSIBLE, not complete.

For the three previously heuristic-only cases, all upper estimates 16/18/22
are independently reproduced by actual nontrivial GF(2)-verified words.
Stronger CC-only lower bounds 15/16/16 are **PLAUSIBLE_PENDING_INDEPENDENT_LOWER_BOUND_COMPLETION**.
Both engines independently support lower bound 9. Do not publish provisional
[15,16]/[16,18]/[16,22] as independently confirmed scientific intervals, or
infer exact d=16/18/22. The source literature estimates provide no lower-bound
proof. No new exact distance on an open code is claimed. Confidence fields
are explicit in raw/bound-crosschecks.json, manifest checks and this report.
The original audit's NO_NEW_EXACT_RESULT marker refers only to exact answers;
the separate bound review supplies the required provisional status for
stronger lower-bound observations, without changing any raw bound value.

Bound review is reproducible with runner/review_bounds.py (audit SHA256 retained).
It distinguishes the strongest observed lower bound from the minimum independently
supported by both engines and handles absent numeric bounds explicitly.
All 24 previous manifest records and all previous matrix files are unchanged.
CC BY 4.0 source attribution for Yifan Hong is recorded with source/license
links and an explicit statement of our original implementation/binary expansion.

## Optional long-proof package (prepared only)

runner/prepare_jobs.py selects exactly seven unresolved per-engine proofs
from the actual audit: MaxSAT n=320; both engines at n=390/550/775. It skips
all completed proofs. runner/jobs.jsonl is committed; command dry-run output
in raw/server-dry-run.json was inspected against the selected set. Runner
is syntax checked; no solver process launched locally or on a server.

One explicitly PI-assigned, occupancy-checked yfclab2 core, serial jobs,
4 GiB each, 21600s per job, +600s wall backstop, stdin /dev/null. Worst-case
serial package budget is 42h of solver limits or 43h10m with all backstops;
this is NOT authorization to run or a claim that any long gate passed. It
requires PI allocation and a server-enabled agent. Frozen source/case/job/
binary/input identities and raw logs are retained, mutations during execution
are rejected, all emitted witnesses are GF(2)-checked, contradictions stop
the queue. Exact/upper semantics are preserved for every job, no unknown stem
is parsed as a numeric expected distance. See runner/README.md.

Verdict: accept the six reproducible inputs as untiered library representatives;
all requested short numeric gates pass, with the scientific confidence limits
above. Seven optional exact-proof jobs and prior hyperbolic unresolved items
remain visible. No PR/main integration, tiering/renames, QDistSAT mirror,
external distance solver, Mac solver experiment or server allocation.
Continuous coverage goal remains active; next independent construction target
is pair-partition CPM, with source/provenance research in NEXT_FAMILY_RESEARCH.md.
Scientific semantics changed: no. PI action required: no to continue library
work; yes for main integration or any server execution, and the prior n=1920
hyperbolic interpretation question remains pending.
