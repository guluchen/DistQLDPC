# GH-178: finite twisted circle-bundle open-distance representatives

Status: CONSTRUCTION_AND_WORD_AUDIT_PASS;3default MaxSAT numeric gates INCOMPLETE.
Issue https://github.com/guluchen/DistQLDPC/issues/178, hub15 claim6497953233.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/fiber-bundle-library, source dd5570775658292091a9ea86dc10e5c7907a81dd
(tree d2c033b987e2b446b7f0910b11640acd69dffce3; data eb85ca14ad99066f88c4a9f78dafaefcc9d73a91).
No PR requested; FBC prefix/naming/tiering/main integration need PI review.

## Three proposals, choice and literature boundary

1. CHOSEN: finite circle bundles from2009.03921v2 Definition2.11 with sparse
   full-row-rank bases and nonremovable twists. Expected: genuine missing
   finite bundle structure and unknown distances at n252..2800. Risks:
   boundary/transposes, removable gauge, hidden factors/rank and false claims
   that these modest finite bases meet an asymptotic theorem.
2. Larger nonabelian two-block open targets: useful practical gaps, source/
   equivalence review needed.
3. General Bravyi-Hastings products: a distinct remaining family gap requiring
   finite parameter extraction.

Prior GH164..177 reports, literature survey and coverage ledger reviewed.
PI priority remains unknown exact distances. Fresh issues/remote branches
show no competing fiber-bundle topic. Published math: Hastings-Haah-O'Donnell,
2009.03921v2 Sec2.3 Eq5/Definition2.11/Lemma2.5/Proposition2.10. Only original
mathematical reconstruction; no source text/images/software/matrices copied
or external distance solver. arXiv perpetual/nonexclusive paper license is
not imputed to software/data. Original scripts/matrices GPL3-or-later.

These finite instances use the permissive bundle definition, NOT the paper's
polylog-check random-base, weight-reduction or distance-balancing theorem.
They are not a surrogate for asymptotically-good qLDPC or all general
homological-product codes. FBC is a proposed provenance prefix and overlaps
lifted-product mathematics. Full coverage ledger remains open.

## Frozen input selection and local checks

Bases(16,12),(24,18),(32,24),(40,30),(48,36),(64,48), circleL9/9/25/25/25/25,
N252/378/1400/1750/2100/2800, k4/6/8/10/12/16. Fixed stable PRNG seeds,
unbiased configuration shuffle, first simple/distinct-column/full-rank/
connected base accepted. Sample indices7/43/45/17/21/7, with only parallel-
edge rejects except one rank reject at base24. Twist sample0 in every case;
cycle-voltage gcdell=3/3/5/5/5/5. Complete base rows, twists, seeds and replay
receipts frozen. NO distance/support enumeration, seed resampling or tuning.

Commands:
```
python3 scripts/codegen/fiber_bundle.py --all --out data/matrices/untiered
python3 scripts/codegen/validate_fiber_bundle.py --out optimization/experiments/GH-178/raw/construction.json
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 tests/test_codegen_fiber_bundle.py
python3 scripts/codegen/fiber_bundle.py --all --out /tmp/gh178-fresh
```

Mac generation/algebra/tiny units only. Independent physical chain columns,
squarezero, actual ranks, complete logical quotients/full pairing, degree/
weight, base chain projection, fiber translation, raw and canonical-rowspace
connectedness PASS. BFS versus weighted-disjoint-set gauge implementations
agree on nonremovable subgroup.11 new units include random tiny chains,
actual gauge-induced physical permutations, frozen first-admissible replay,
wrong-boundary/trivial-gauge/base-rank/upper-stabilizer mutants and stable
PRNG output. Prior34 units pass, total45;24 matrix files byte-reproduced.
All prior24 manifest rows/96 matrix bytes preserved;30untiered+51tiered
inventory. No same(n,k) peer across current main/pending library branches.
Written structural/upper soundness proof in FIBER_BUNDLE.md. No pruning,
solver bound, default, build or tiered matrix change.

Actual verified X logicals give overall upper9/9/25/25/25/25. These upper
words have zero actual syndrome, are outside actual stabilizer row space and
have a logical detector. No exact distance or lower bound inferred from the
source asymptotics or a claimed equal-half symmetry.

## Linux plan and resource limits

Unchanged solver build,45units, full construction/inventory comparisons,
24-file regeneration. Six selected default MaxSAT and six CC calls, serial
60sCPU each,90swall,4GiB,one allocated pinned runner-affinity CPU, default
seed,20min overall job cap. No sweeps/repeated diagnostics, Mac/third-party
solver, paid cloud or server execution. No performance/Tier1..5 adoption
claim; seed medians/ranges do not apply to single diagnostic smokes.
Retain every raw output, argv, source/binary/input identity, failure/timeout.
Audit every physical word and search interval against other engine and the
independent upper word. Missing raw numeric fields stay INCOMPLETE; an upper
certificate never fills absent CLI output. New one-engine exact/lower results
PLAUSIBLE until independent completion. Heavy jobs become an unexecuted
frozen yfclab2 package requiring an explicitly PI-allocated free core.

## Completion fields

What changed: six reproducible finite fiber-bundle representatives with
nonremovable twists and verified upper witnesses, proposed FBC prefix.
Validation: local+Linux45units/construction/inventory/regeneration pass; all actual
words/identities/bounds audited; retained audit replays byte-identically.
Results: both-engine exact9/9; CC-only13/18 PLAUSIBLE; two remaining CC
intervals[20,23]/[20,25] with provisional lower20; verified actual upper words.
Unresolved:3default MaxSAT numeric gates and6engine proofs packaged
unexecuted; other coverage gaps remain.
Scientific semantics changed: no.
PI action required: yes for prefix/main integration/final names/tiers and any
server allocation; independent library construction can continue meanwhile.


## Next-family research (not implemented in this batch)

The primary Bravyi-Hastings1311.0885v1 PDF was inspected (onlyv1 exists;
an attemptedv2 HTML returned404). SecII/III, Eq13 and Lemmas1/2/3 define
a distinct single-sector product of nilpotent differentials. A finite seeded
GL-conjugated ensemble would give unknown-distance CSS targets over roughly
169..2809 qubits with algebraic full logicals. Checks can grow asO(sqrtN),
so these cannot be advertised as constant-check modern qLDPC or as a proof
of finite linear distance. This is future source research, not extra matrices,
solver work, an issue claim or a narrowed completion of all good-code gaps.


## Retained Linux evidence and verdict

Library [40883387357](https://github.com/guluchen/DistQLDPC/actions/runs/40883387357),
job123480561025 SUCCESS; source CI40883387059/job123480558722 SUCCESS.
Source dd5570775658292091a9ea86dc10e5c7907a81dd, unchanged solver binary
SHA25668f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Ubuntu24.04 hosted Linux,Python3.12.3,c++13.3.0,pinnedCPU0,serial,default
seed,60sCPU/90swall/4GiB per call. Complete raw log617658 characters and
all engine logs/JSON/CSV/environment/argv/source/input identities retained
under raw/actions/default/. Audit replay is byte-identical on actual local
files. No repeated/supplemental CI, Mac solver, external solver or performance
claim. A green collection job does not certify the three missing numeric gates.

| n | MaxSAT60s | CC60s | Numeric smoke gate | Scientific status |
|---:|---|---|---|---|
|252|exact9|exact9|PASS|two engines+GF2 words|
|378|exact9|exact9|PASS|two engines+GF2 words|
|1400|[9,13]|exact13|PASS|PLAUSIBLE, independent lower proof pending|
|1750|UNKNOWN,no numeric fields|[20,23]|INCOMPLETE|lower20 PLAUSIBLE, verified upper23|
|2100|UNKNOWN,no numeric fields|exact18|INCOMPLETE|PLAUSIBLE, independent lower proof pending|
|2800|UNKNOWN,no numeric fields|[20,25]|INCOMPLETE|lower20 PLAUSIBLE, verified upper25|

No observed bound/word contradicts another or the independently verified
algebraic upperL. Every emitted physical word passes syndrome/stabilizer/
logical-detector checks. Exact9 at n252/378 has independent two-engine
completion. CC-only exact13/18 and stronger open lower20 remain PLAUSIBLE;
no name or source-distance claim changes. Missing raw MaxSAT fields are
empty, not filled by a CC result, an algebraic upper or a source formula.

Six frozen unexecuted yfclab2 jobs: MaxSAT n1400/1750/2100/2800, CC n1750/
2800.6hCPU+600swall/4GiB each,serial,seed0,explicit PI-allocated free core;
36hCPU/37hwall configured aggregate limits, not a runtime prediction. Default
dry-run and Mac/altered-argv guards pass; case/input/argv/host/allocation/core
and retained-other-engine contradiction checks included. No core allocated
or server job executed. Prior incomplete gates on other branches remain open.

Verdict: finite Definition2.11 bundle structure and reproducibility pass,
two exact global distances cross-checked, four scientific proof completions/
three missing MaxSAT numeric gates remain with six engine jobs. This is not
an asymptotic distance theorem, a tier/adoption decision or full goal completion.
