# GH-169: finite-group Quantum Tanner specialization

Issue https://github.com/guluchen/DistQLDPC/issues/169.
Branch codex/finite-group-tanner-library, main base6083e662c621f3b66defd434cfae31a028d483c4.
Status: six inputs pass source-instance, construction and all numeric smoke gates. Published overall upper words reproduced in GF(2); stronger CC-only lower bounds and one exact result remain PLAUSIBLE. Work branch only.

Three proposals: SELECTED moderate finite-group Tanner inputs; noncyclic
quaternary PP;4.8.8 color patches. Hypothesis: published fixed nonabelian
group/local-code inputs add open-distance specializations. Risk: source
same(n,k) variants, right-action inverse/local column order, heuristic distance
misinterpretation. Expected library effect only, no solver/default/performance
adoption, tiered benchmark or QDistSAT change. Read prior GH-160/164/165/166/
167/168 records and coverage ledger. No topic collision/server allocation.

Source Mian et al2608.12509v1 Eq34 Tables I/IX/XII. Six inputs n288k8,360k6,
480k8,588k14,756k10,864k8; published overall upper estimates15,18,18,18,9,27.
Not exact labels. TableIII variants are not substituted. Author files sometimes
retain older estimates; complete parameter agreement and proved source matrix
equivalence identify the selected instances. Source full numeric HDF5 records
pinned by commit/blob/SHA256 and projection digests; no constructor/search or
distance-verifier implementation read/copied/run. Source records not redistributed.

MIT numeric-source attribution/full notice in NOTICE, Copyright2026 Quantum
Savory. Paper perpetual/nonexclusive, no copied text; secondary mathematical
regular-action definition2512.20532v1 CC BY4 credited. Original scripts/matrices
GPL3+. Full source/license/construction/soundness proof in FINITE_TANNER.md.

Mac local checks (no DistQLDPC solver execution):
- Fixed HDF5 numeric inputs read using temporary h5py, Git blobs/SHA256 verified.
- `python3 scripts/codegen/finite_tanner.py --all`
- `python3 scripts/codegen/validate_finite_tanner.py --out optimization/experiments/GH-169/raw/construction.json`
- `python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json`
- `python3 tests/test_codegen_finite_tanner.py`:12 pass.
- Optional `verify_finite_tanner_source.py --cache /tmp/gh169-source --out optimization/experiments/GH-169/raw/source-equivalence.json`, all six pass: actual source numeric regular actions give an explicit fiber enumeration, then both stabilizer spaces match.
- Fresh generation in /tmp/gh169-regenerated, all24 files byte-identical.
- Pending branches GH-160/164/165/166/167/168 have no same(n,k) peers;
  exact reviewed commit identities retained in raw/pending-branch-peers.json.

Independent inverse-permutation group/column pullback validator uses no
generator/logical-builder imports. Checks local full duality and source
projection, nonabelian group order, both connected halves, GF(2), actual ranks,
logical quotient bases/full pairing. Random tiny local-code lifts compare
independent reconstruction, tiny8-qubit supports exhaustive, source/action/
permutation/connectivity/logical mutants caught. Wrong right-action convention
can remain CSS, so commutation alone is explicitly insufficient.

Executed Linux: unchanged build,46 unit checks, independent algebra/source
projection/incidence/connectivity,24-file regeneration, six default MaxSAT and
six CC60s checks serial allocated pinned core,4GiB cap,90s wall/stdin null.
Collector retains actual CLI values and supports explicit <= claims; it does
not fill from reference estimates. Every printed logical independently GF(2)
checked. Source `1ded66162548a3aa627da8f0e26d20d512784ff8`.
Library [40854960602](https://github.com/guluchen/DistQLDPC/actions/runs/40854960602),
job123383511802: SUCCESS. Generic CI40854960533, job123383511739: SUCCESS.
Binary SHA256 `68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a`.
Complete811489-character job log,12 raw runs/JSON/CSV, DONE/environments,
source/binary/input identities and audit committed under raw/actions/default/.
Audit replay is byte-identical. All12 CSV/JSON/raw results agree, input hashes
match committed files, old24 manifest rows unchanged,30 untiered/81 current
inventory entries pass algebra. No reliance on expiring-only artifacts.

|n|published overall upper|MaxSAT60s|CC60s|independently common lower|
|---|---|---|---|---|
|288|15|[9,15]|[13,15]|9|
|360|18|[9,18]|[15,18]|9|
|480|18|[9,18]|[14,18]|9|
|588|18|[9,18]|[14,18]|9|
|756|9|[5,9]|exact9|5|
|864|27|[5,27]|[15,39]|5|

Every printed word passes GF(2) syndrome, stabilizer exclusion and logical
basis detection. Actual words of weight15,18,18,18,9,27 reproduce the paper's
OVERALL upper estimates. This does not establish all per-half published
estimates or exact distances. No contradictory reference/engine/witness result.
All six numeric smoke gates pass with actual outputs from both engines.

CC-only lower13,15,14,14,9,15 and n756 exact9 remain **PLAUSIBLE** until
independent lower-bound completion; publication heuristic estimates supply no
lower proof. Common lower bounds are9,9,9,9,5,5. `runner/review_bounds.py`
records common vs strongest observed bounds and provisional exact status,
bound to raw audit SHA256 in raw/bounds-review.json, without changing raw data.
No stem rename/tiering/novel exact-distance announcement. No increased CI
limits, parameter sweep or Mac solver run.

## Unexecuted server proof continuation

Eleven unresolved engine jobs selected from actual short evidence: all six
MaxSAT, five CC except the solved756 case. `runner/jobs.jsonl` and default-
dry-run `run_serial.py` preserve the exact/upper claim distinction and actual
inputs. Six-hour CPU limits,600s wall backstop,4GiB, one explicitly PI-allocated
free pinned core, stdin /dev/null, serially. Aggregate limits66h CPU/67h50m wall
are limits, not timing estimates. No server core allocated or process launched.
Runner checks yfclab2, clean frozen checkout/affinity/pinned processes and
requires allocation reference/free-core confirmation. Records source/binary/
case/job/input identities and exact argv, rechecks inputs/binary around runs,
retains raw evidence before failures. Syntax, dry-run and byte-identical job
regeneration pass. See runner/README.md for exact commands. Numeric gates are
already complete; this package concerns the independently unresolved lower
proofs. Heavy compute was not moved onto the Mac or shared CI.

Completion fields: what changed: six TN untiered inputs, original generator,
source identity/pullback/GF(2)/tests/provenance. Validation:46 tests, numeric source identity/equivalence, independent incidence/GF(2)/logicals/connectivity/duplicates,24-file regeneration and12 Linux engine runs with witness audit. Results: all six numeric gates and overall source upper words pass; no independently completed new exact result. Unresolved: stronger one-engine lower bounds, n756 exact9 cross-check, and PI integration/server allocation. Scientific
semantics changed:no. PI action required:no to continue,yes for integration
or server allocation. Prior hyperbolic n1920 interpretation remains pending.
