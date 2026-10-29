# GH-173: HGP from degree-three Gallager LDPC factors

Date2026-10-29, [issue173](https://github.com/guluchen/DistQLDPC/issues/173).
Base main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/gallager-hgp-library. Local and Linux proof/smoke PASS; quality verdict NEUTRAL for
growing-distance coverage, valid unexpurgated controls only.

Three proposals: selected fixed first-seed Gallager(3,4) factors + HGP;
deferred higher-dimensional toric/homological CSS; deferred covering/discovery
BB provenance targets. Prior GH153/154/172 and coverage ledger reviewed.
Open issues and remote branches checked; issue claimed on hub15 before code.
This is input-library reconstruction, not solver/performance adoption.

Sources, complete sampler/product coordinates, rank/dimension/commutation
argument, provenance and distance semantics in GALLAGER_HGP.md. Gallager's
primary book pages7/13/14/15/17/18/19 were rendered and visually read because
the PDF text encoding is broken; only its SHA256 and URL/page metadata are
retained, not its copyrighted file or images. Theorem2.4 is a typical-ensemble
growth result, never a distance guarantee for each seed. HGP Theorems1/15
read from Tillich–Zémor0903.0566v2. No source programs, matrices, external
distance tools or author implementations read/copied/run.

Preregistered classical n8/12/20/28/36/44, seed0, one sample per size with no
screening/resampling. Raw column3/row4 weights, sparse ORIGINAL-row basis
selected in source order, actual ranks4/7/13/19/25/31; quantum(N,k) are
(80,16),(193,25),(569,49),(1145,81),(1921,121),(2897,169).
All raw/selected factor and quantum graphs connected. Quantum row weights5..7.
No assumption that cycle-code factors or fixed-base cyclic lifts supply the
same asymptotic regime. These are finite LDPC-ensemble representatives;
an explicit deterministic expander-factor family remains a separate gap.

Local validation:10 new tests plus34 existing tests; independent reverse-shuffle,
set elimination, physical-column product reconstruction, actual GF(2) ranks,
full logical quotient bases/pairing and tensor-swap duality; initial all-ones
product upper words; all30 untiered inputs/81 total inventory. All24 new files
reproduce byte for byte, prior24 rows/96 matrices unchanged. No same-(N,k)
peer across current/pending library branches. LegacyCOLOR unit's default-HGP
inventory assertion made manifest-based because HGP now contains18 inputs;
its explicit COLOR checks and the runner's HGP default remain unchanged.
Tiny classical<=8-bit/17-qubit quantum units only on Mac, no source-distance
or solver experiment there.

Linux plan: bounded one-core4GiB/60s CPU/90s wall independent classical
kernel enumeration over at most8192 words, then six explicit-subset default
MaxSAT and six CC60s serial runs with the same resource backstop/null stdin.
The raw source claim is <=classical n with an algebraic word, not an invented
published exact distance. Audit each engine against the independently derived
product distance, preserving missing fields and verifying actual supports.
Any disagreement is a scientific escalation. New results PLAUSIBLE until
an independent implementation/search and GF(2) word check complete. Retain
all raw identities/logs/weight enumerators; unresolved proofs become unexecuted
allocated-server packages. No broad sweeps or longer CI diagnostics.

Scientific semantics changed: no.
PI action required: main integration and any dedicated-server allocation.
No PR/main/gh-pages push, tier/name/default/solver/QDistSAT change.

## Linux results, independent proofs and utility verdict

Validated sourcee8c75b566b6e70a8045d06d7ff8cf2cbd28189e1;
data commit6cd6fe1f76bdaa2a0acad8347bf15d1ff8a4c70e;
source tree66e4b34516a6df520fdd9eb9a46c12d72a580ccc.
[Library run40867842360](https://github.com/guluchen/DistQLDPC/actions/runs/40867842360),
job123427009402 SUCCESS; ordinaryCI40867842236, job123427009342 SUCCESS.
All44 tests,30 untiered/81 inventory cases, independent construction and24
new-file regeneration comparisons passed. The entire independent classical
proof ran within its declared one-core4GiB/60s CPU/90s wall cap.

| Stem | Classical words enumerated | Derived d | MaxSAT lb/ub | CC lb/ub |
|---|---:|---:|---|---|
| HGP_80_16_unknown | 16 | 2 | 2/2 SOLVED | 2/2 SOLVED |
| HGP_193_25_unknown | 32 | 2 | 2/2 SOLVED | 2/2 SOLVED |
| HGP_569_49_unknown | 128 | 2 | 2/2 SOLVED | 2/2 SOLVED |
| HGP_1145_81_unknown | 512 | 4 | 4/4 SOLVED | 4/4 SOLVED |
| HGP_1921_121_unknown | 2048 | 2 | 2/2 SOLVED | 2/2 SOLVED |
| HGP_2897_169_unknown | 8192 | 2 | 2/2 SOLVED | 2/2 SOLVED |

All numeric gates PASS. Each new finite exact result is independently
cross-checked by the complete classical kernel/product proof and BOTH quantum
engines, with verified quantum supports. None remains a one-implementation
PLAUSIBLE result. These computed distances are not relabeled as published
finite claims; the manifest retains its explicit upper-only algebraic source
claim. No scientific disagreement or long unfinished proof remains.

However, this does NOT satisfy the intended growing-distance finite ladder.
Five fixed factors have repeated nonzero raw parity-check columns, giving
weight-two classical words. Their counts2/2/2/0/1/1 exactly match the full
classical weight enumerators; collision groups retained in structural-review.json.
The n28 factor has distance4, but the sequence is not a distance-growth
demonstration. Do not infer failure of Gallager's asymptotic ensemble theorem
from these tiny deterministic samples. Do not retrospectively replace the
preregistered seed or claim that passing correctness meets the quality goal.

Verdict: VALID_UNEXPURGATED_CONTROLS / NEUTRAL_FOR_GROWING_DISTANCE_COVERAGE.
The six valid cases and full negative utility evidence remain reviewable on
this work branch; PI integration/utility review decides whether these controls
are wanted. The coverage ledger explicitly leaves a useful finite-growth
ladder and an explicit deterministic expander-factor family OPEN. A new round
may preregister a source-related expurgated ensemble, with explicit structural
acceptance and a conditioning argument; this round makes no such change.
No heavy server run is needed or launched for these fully verified controls.

Binary SHA25668f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
The full555756-character job log, all12 raw quantum runs, complete classical
weight enumerators/minimum supports, input/source/script/binary identities,
CSV/DONE records and audit are versioned in raw/actions/default/. Audit replay
from retained artifacts is byte-identical, with every word rechecked in GF(2).
No theory result fills a missing CLI bound. No solver, generator, test or
scientific input change follows the validated checkpoint; metadata-only
updates record outcomes. All prior24 rows/96 matrices remain unchanged.

Replay, no new search:

```sh
python3 scripts/codegen/audit_gallager_hgp_smoke.py --maxsat optimization/experiments/GH-173/raw/actions/default/gallager-maxsat --cc optimization/experiments/GH-173/raw/actions/default/gallager-cc --classical optimization/experiments/GH-173/raw/actions/default/classical.json --out /tmp/gallager-audit.json
python3 scripts/codegen/validate_gallager_hgp.py --output /tmp/gallager-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/gallager-inventory.json
```

Scientific semantics changed: no. PI action required: main integration/utility
review only; there are no unexecuted proof jobs for these six cases. The
broader library goal remains active and is not complete.
