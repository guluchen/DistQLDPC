# GH-179: finite single-sector homological-product CSS representatives

Status: CONSTRUCTION_AND_ACTUAL_WORDS_PASS; two exact distances cross-checked;
one default numeric smoke gate and seven engine-proof completions remain.
Issue https://github.com/guluchen/DistQLDPC/issues/179; hub15 claim6498528457.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/homological-product-library; data056141ea1d3da12427790a649edef1ae297eeb03;
Linux source cdb6a5e33234b038ac99571c81c1d6e7f653f83d.
No PR requested; proposed HPC prefix/main integration/naming/tiering for PI.

## Three proposals and scientific boundary

1. CHOSEN: finite single-sector homological products from Bravyi-Hastings
   1311.0885v1 SecII/III Lemmas1/2/3/Eq13. Expected: a genuine remaining
   general-product CSS construction and unknown-distance/positive-rate sizes.
   Risks: similarity mistaken for weight isometry, tensor/transposes,
   hidden factors, incomplete logicals/rank and finite asymptotic claims.
2. Closed higher-genus color codes: genuine topology gap, explicit parameters
   and source construction still to resolve.
3. Explicit expander-factor HGP/practical good qLDPC: certified finite
   construction gap remains; source extraction needed.

Prior GH164..178/literature/coverage ledger reviewed; fresh issues/remote
branches show no competing homological topic. The primary paper has onlyv1;
its math, not source software, is reconstructed. No external code/matrices,
paper prose/images or distance solver. arXiv perpetual/nonexclusive paper
license is not imputed to software/data; original scripts/matrices GPL3+.
This single-sector construction is distinct from classical-factor graded HGP.
Checks can grow asO(sqrtN), not constant-check modern qLDPC. Do not claim the
finite selected rates satisfy sufficiently-small-rate/asymptotic distance
hypotheses. U similarity is algebraic only, not a physical weight isometry.
Broader good-qLDPC/closed-color/explicit-expander gaps remain open.

## Frozen selection and local validation

Factor(M,H)13,3/19,5/29,7/37,9/43,11/53,13; N169/361/841/1369/1849/2809,
k9/25/49/81/121/169. Independent stable seeded binary-factor streams reject
singular matrices only, with accepted(left,right) singular-draw counts
(1,0),(0,5),(3,2),(1,1),(0,4),(1,5). All accept pair sample0 with raw and
reduced-row-space connectivity; NO structural resampling was needed.
Every factor U/inverse/delta/seed/draw count is frozen. No distance/support
search, solve-time/word-weight screening or resampling poor finite controls.

Commands:
```
python3 scripts/codegen/homological_product.py --all --out data/matrices/untiered
python3 scripts/codegen/validate_homological_product.py --out optimization/experiments/GH-179/raw/construction.json
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 tests/test_codegen_homological_product.py
python3 scripts/codegen/homological_product.py --all --out /tmp/gh179-fresh
```

Mac generation/algebra/tiny units only. Independent factor basis actions,
inverse/conjugacy/nilpotence/rank, actual product physical columns/squarezero,
complete canonical AND computed logical quotients/full pairings, actual rank
(N-H²)/2, raw/row-space connectivity and growing-check-weight bounds PASS.
Actual canonical X/Z tensor words give overall uppers16/42/110/168/272/266;
no claim these are minima. Written construction/logical/upper soundness and
metric limitation in HOMOLOGICAL_PRODUCT.md.11 new units include random
small inverses by exhaustive vector actions, random nilpotent products,
wrong canonical transpose/diagonal OR/invalid inverse/logical mutants and a
four-qubit fixture proving GL similarity can change distance1->2 (15 words
only). Prior34 units pass, total45;24 files freshly byte-reproduced.
Prior24 manifest rows/96 matrix bytes and51 tiered inputs preserved;
30untiered+51tiered full inventory, no same(n,k) main/pending library peers.
No solver/build/default/tiered matrix change.

## Linux plan

One unchanged solver build,45units, full construction/inventory comparisons,
24-file regeneration. Six selected default MaxSAT and six CC calls, serial
60sCPU each,90swall,4GiB,one allocated pinned runner-affinity core,default
seed,20min total job cap. No repeated diagnostics/sweeps, Mac/external solver,
paid cloud/server execution or performance/Tier1..5 adoption. Medians/seed
ranges do not apply to single diagnostic short runs. Retain every raw output,
argv/source/binary/input identity/failure/timeout; verify actual words and
compare all intervals/answers against the independent upper words and other
engine. No algebraic upper fills a missing CLI field. Missing numeric gates
stay INCOMPLETE; new one-engine exact/lower results PLAUSIBLE until independent
completion. Heavier work becomes frozen unexecuted yfclab2 jobs requiring PI
allocation, not a longer/repeated CI experiment.

## Completion fields

What changed: six finite single-sector CSS products, reproducible factors,
independent actual product/canonical logicals and physical upper words.
Validation: local+Linux45units/construction/inventory/regeneration/actual-word
audit pass; raw audit replay is byte-identical.
Results: two-engine exact2/4; CC-only exact6 PLAUSIBLE; provisional open
combined intervals[10,12]/[9,16]/[8,49], with actual GF2 upper words.
Unresolved: n2809 MaxSAT numeric gate and seven engine-proof completions
packaged unexecuted; broader coverage gaps remain.
Scientific semantics changed: no.
PI action required: yes for HPC prefix/main integration/final names/tiers and
any server allocation; independent construction continues meanwhile.


## Next-family source research, not implemented here

Higgott–Breuckmann, PRX Quantum5,040327(2024), DOI10.1103/PRXQuantum.5.040327,
arXiv2308.03750v2 SecII.1–II.3 provides Wythoff/finite-quotient color-code
tilings. Published article CC BY4.0; arXiv nonexclusive. Reconstruct only
mathematics, with attribution. Its Tables1–4 are FLOQUET embedded/circuit
distances and logical counts, not static face-X/face-Z CSS distances/counts;
never populate a static CSS manifest with them. Closed-color finite quotient
reconstruction is a remaining coverage/unknown-distance opportunity, still
requiring independent local manifold/coloring/rank/logical/word validation.
No next-family matrices, source-code copying, distance claims or issue claim.

Further actual omissions are now explicit in the coverage ledger:3D stabilizer
color/colex codes (Bombin–Martin-Delgado cond-mat/0607736v3, PRB75,075103)
and Haah cubic/fracton CSS codes (1101.1962v2, PRA83,042330). For the latter,
TableI/Eq8 give local CSS generators; Theorem1 gives only d>=L for periodic
codes1..4, and TableII k formulas are explicitly empirical over2<=L<=200.
Actual finite ranks/logicals and distances must be verified. Non-CSS Code0
and thermal-memory claims do not belong to this CSS distance task. The
arXiv Haah license is perpetual/nonexclusive, not software/data permission;
only original mathematical reconstruction is contemplated. No author code,
external solver, source support search or finite scientific experiment run.
These leads add open requirements; they do not claim coverage or completion.

A concrete next open-distance lead is now confirmed in the primary
Panteleev–Kalachev1904.02703v3 (Quantum5,585,2021, CC BY4.0), AppendixB
itemD/Table1: Haah Code1,8x8x8, [[1024,30,13<=d<=32]]. This source interval
is metadata, not a new independent bound/witness. Its long-decoder failure
to find smaller words is not itself a lower proof. No next-family matrix
has been generated. The report/citation must not be confused with the
different2012.04068 lifted-product paper.


## Retained Linux evidence and verdict

Library [40888592817](https://github.com/guluchen/DistQLDPC/actions/runs/40888592817),
job123498897175 SUCCESS; source CI40888592399/job123498896745 SUCCESS.
Source cdb6a5e33234b038ac99571c81c1d6e7f653f83d, unchanged binary
SHA25668f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Ubuntu24.04 hosted Linux,Python3.12.3,c++13.3.0,pinnedCPU0,serial defaultseed,
60sCPU/90swall/4GiB per call. Full job log1053096 characters plus all engine
logs/JSON/CSV/environment/argv/source/input identities retained under
raw/actions/default/. Actual local audit replay is byte-identical. No
repeated/supplemental CI solver calls, Mac/external solver or timing claim.
A green collection job does not pass the missing n2809 numeric gate.

| n | MaxSAT60s | CC60s | Numeric gate | Scientific status |
|---:|---|---|---|---|
|169|exact2|exact2|PASS|two engines+actual GF2 words|
|361|exact4|exact4|PASS|two engines+actual GF2 words|
|841|[3,6]|exact6|PASS|PLAUSIBLE, independent lower proof pending|
|1369|[3,12]|[10,12]|PASS|lower10 PLAUSIBLE, actual upper12|
|1849|[2,16]|[9,20]|PASS|lower9 PLAUSIBLE, actual upper16|
|2809|UNKNOWN,no numeric fields|[8,49]|INCOMPLETE|lower8 PLAUSIBLE, actual upper49|

All printed words pass independent syndrome/stabilizer/logical-detector
checks. No observed contradiction with another engine or actual canonical
upper. The small finite distances2/4 are retained as negative evidence
against interpreting these particular rates/seeds as a finite linear-distance
guarantee; no sample is replaced or excluded after seeing its result.

Important evidence distinction: n2809 CC stdout reports verified initial
basis upper49, but no actual corresponding support before timeout. The
unchanged audit therefore contains canonical upper266 as its lightest
materialized input word. Separately, verify_retained_basis_words.py selects
existing supplied Gx/Gz rows only (no combinations/support search), matches
EVERY CC initial per-half basis summary, binds all four retained matrix
hashes, and GF2-verifies the actual physical words. Full supports saved in
raw/basis_words.json; n2809 now has a reproducible actual upper49. This
post-smoke algebra certificate does not change raw stdout, audit JSON or
missing MaxSAT fields, and supplies no lower or exact proof. Reproduce with:

```
python3 optimization/experiments/GH-179/verify_retained_basis_words.py --out /tmp/hpc-basis-words.json
cmp optimization/experiments/GH-179/raw/basis_words.json /tmp/hpc-basis-words.json
```

Seven frozen unexecuted yfclab2 jobs: MaxSAT n841/1369/1849/2809; CC
n1369/1849/2809. References6/12/16/49 are actual checked physical uppers,
not asserted exact answers. Each6hCPU+600swall/4GiB,serial seed0,explicit
PI-allocated confirmed-free core;42hCPU/43h10mwall aggregate LIMITS, not ETA.
Dry-run/Mac/altered-argv guards pass without solver invocation/output
directory creation. Case/input/host/allocation/core guards, actual-upper
verification and retained-other-engine contradiction checks are included.
No core allocated or server execution; no final name/tier/QDistSAT/main/PR.

Verdict: finite single-sector construction and numeric gates for five cases
pass; two exact distances cross-checked. Four codes' independent proof
completions and one missing MaxSAT numeric gate remain with seven jobs.
Broader family/validation/integration gaps stay open; full goal not complete.
