# GH-179: finite single-sector homological-product CSS representatives

Status: CONSTRUCTION_CANONICAL_LOGICALS_AND_UPPER_WORDS_PASS; Linux pending.
Issue https://github.com/guluchen/DistQLDPC/issues/179; hub15 claim6498528457.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/homological-product-library; source recorded after push.
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
Validation: local45units/construction/regeneration pass; Linux pending.
Results: overall upper16/42/110/168/272/266 only, exact distances unknown.
Unresolved: Linux numeric/scientific proofs and broader coverage gaps.
Scientific semantics changed: no.
PI action required: yes for HPC prefix/main integration/final names/tiers and
any server allocation; independent construction continues meanwhile.
