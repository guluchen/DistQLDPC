# GH-170: quaternary group-valued PP

Issue https://github.com/guluchen/DistQLDPC/issues/170.
Branch codex/quaternary-pp-library; base main6083e662c621f3b66defd434cfae31a028d483c4.
Status: construction and all four numeric smoke gates pass. Source/MaxSAT upper words verified; stronger CC-only bounds and exact12 remain PLAUSIBLE. Work branch only.

Three proposals: SELECTED quaternary/noncyclic PP; divisor-driven GB;4.8.8
color patches. Hypothesis: add the trace-expanded/product-group specialization
absent from GH-167 CPM. Risks: group-order vs group-law confusion, trace basis/
symbol weights, coordinates, source variant/license scope. Read GH-164..169
records and coverage ledger. No topic collision or server allocation.

Source Lee2610.06820v1 SecV Eq21, AppB3 Eq35, AppD2. Four exact source claims
[[256,64,12]],[[512,128,19]],[[768,192,22]],[[1024,256,25]], not our own lower
exclusions. Full binary homology, one unknown stem per(n,k). Written weighted
cancellation, field/trace, row-basis and reflection proofs in QUATERNARY_PP.md.
No solver/default/tiered/QDistSAT/performance-adoption change.

Repo pinned04ad4795ad15cb89ee47b7868ff925c30b2fc731. Outer catalogue Git blob
3230843653068c1af0ba81b9b10ed0032eb543a3 and noncyclic bundle
98d9dd4674065cc5c6b9290fd7e2dfcd9371ed90 verified exactly. Mathematical
projection digests retained; virtual record paths identified. No LICENSE in
repo; paper arXiv perpetual/nonexclusive. Handoff7.2 permits independent
mathematical rebuilding: original scripts/outputs GPL3+, attribution, no
original JSON/matrix/frame/program files redistributed or license imputed.
No external constructor/search/verifier code read/copied/run. External lower
receipts remain source claims. Noncyclic screening d_upper22, algebra-upper-
only note, physical word19 and paper exact19 have separately recorded scopes.

Mac local checks, no DistQLDPC solver execution:
- `verify_quaternary_pp_source.py --cache /tmp/gh170-source-containers --out optimization/experiments/GH-170/raw/source-projections.json`.
- `quaternary_pp.py --all`; fresh /tmp/gh170-regenerated reproduces16 matrices.
- `validate_quaternary_pp.py --out optimization/experiments/GH-170/raw/construction.json`: polynomial GF4/trace, tuple-group column pullback, weighted cancellation, full binary ranks/logical quotients/pairing, source/reflected words, connected halves, translations/reflection.
- `validate_css.py --output data/matrices/untiered/validation.json`:28 untiered/79 inventory, no same(n,k) peers, X/Z swap checked.
- Pending GH-160/164/165/166/167/168/169 heads reviewed, exact identities in raw.
-12 new plus34 prior tests:46 pass, logs retained. Random tiny lifts,
  exhaustive16-qubit supports, group/field/source/logical mutants.

Coordinate diagnostic: plus-shift temporary code is exactly equivalent under
group inversion on physical columns and row slice indices. Final rowg->colg-e
matches source coordinates. All four source Z/reflected X words GF2-valid,
weights12,19,22,25. Initial test wrongly assumed unchanged row order after
relabeling; corrected to include the proved row permutation. Initial failure
and passing logs preserved; no distance mismatch or altered code semantics.

Executed Linux: unchanged build,46 units, algebra and16-file regeneration, four
MaxSAT and four CC60s checks, serial allocated pinned core,4GiB,90s wall,
stdin null. Raw actual bounds/words/identities retained. Independent GF2 source
words can certify upper bounds even if an engine prints no attaining word;
they cannot fill missing CLI values or lower proofs. Source `de5a58d53920711221e22b6467e259f7a537cb03`.
Library [40859442106](https://github.com/guluchen/DistQLDPC/actions/runs/40859442106),
job123398616916: SUCCESS. Generic CI40859442027, job123398616883: SUCCESS.
Binary SHA256 `68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a`.
Full674452-character job log,8 raw engine logs/JSON/CSV, DONE/environments,
source/binary/input identities and audit committed under raw/actions/default/.
Audit replay is byte-identical. All8 raw/CSV/JSON results agree, input hashes
match, old24 manifest rows unchanged. Algebra validates28 untiered/79 inventory.
No expiring-only evidence dependency or source/core/Makefile/tiered changes.

|n|source exact claim|MaxSAT60s|CC60s|common independently supported lower|
|---|---|---|---|---|
|256|12|[9,12]|exact12|9|
|512|19|[9,19]|[16,20]|9|
|768|22|[9,22]|[18,35]|9|
|1024|25|[9,25]|[18,59]|9|

All four numeric gates pass with actual outputs from both engines. Source Z
and reflected X words12,19,22,25 are GF2-verified. MaxSAT independently prints
words of those same weights, all verified; all printed CC words pass too.
CC1024 prints no word in this run; none is invented for its reported upper59.
The independently verified word25 and MaxSAT word25 remain separate evidence.
No actual CLI bound is substituted, tightened or filled by source values.
No contradiction between source, engines or physical logical witnesses.

CC-only lower12,16,18,18 and n256 exact12 remain **PLAUSIBLE** pending an
independent lower completion. Common lower9 in every case is retained
separately. `runner/review_bounds.py` binds this distinction to the actual
audit SHA256 in raw/bounds-review.json. Source exact claims/third-party
exclusion receipts provide no independent internal lower proof. No stem
rename or novel exact-distance announcement. No additional parameter sweep,
increased CI limits or Mac solver run.

## Unexecuted server continuation

Seven unresolved engine proofs: all four MaxSAT, CC512/768/1024; solved CC256
not repeated. runner/jobs.jsonl selects only these actual incomplete proofs.
Default-dry-run runner requires yfclab2, clean frozen checkout, explicit PI
allocation/free-core confirmation, affinity/pinned-process checks. Serial
4GiB,21600s CPU+600s wall backstop, stdin /dev/null; exact commands and source/
binary/case/job/input identities retained, inputs/binary rechecked around runs.
Aggregate limits42h CPU/43h10m wall are limits, not timing estimates. No core
allocated/process launched. Syntax, dry-run and exact job regeneration pass.
Numeric gates are complete; independent lower proofs are the remaining
scientific work. See runner/README.md. No server work moved to Mac/Actions.

Completion: what changed: four inputs, generator/cases/independent checks/tests/
source pins/provenance. Validation:46 units, source identities, independent field/group/columns/GF(2)/logicals/symmetries/duplicates/connectivity,16-file regeneration and8 Linux engine runs with witness audit pass. Results: all four numeric gates and source upper words reproduced; CC exact12 provisional. Unresolved: independent stronger lower/exact completions and PI integration/server allocation.
Scientific semantics changed:no. PI action required:no to continue;yes before
integration/server use. Prior hyperbolic n1920 decision remains pending.
