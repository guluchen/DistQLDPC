# GH-205 repeated-cyclic CSS hyperbicycle targets

Status: CONSTRUCTION_AND_NUMERIC_PASS; THREE_MAXSAT_PROOF_COMPLETIONS_PENDING. Goal ACTIVE.
Issue https://github.com/guluchen/DistQLDPC/issues/205; hub comment6509055409.
Branch codex/hyperbicycle-library from main6083e662c621f3b66defd434cfae31a028d483c4.
Previous goal turn was NO_PROGRESS (priority acknowledgement only); this turn
revalidated source/branch state and performed independent source selection,
construction and full local gates. GH200 and GH202 scientific holds remain
unchanged. Issues203/204 concern solver engineering and are untouched.

## Three proposals and frozen selection

CHOSEN: missing explicit repeated-cyclic multi-block hyperbicycle specialization
with unconfirmed finite distances. DEFERRED: binary CSS BCH initial controls
are already literature-known exact, not suitable open targets. DEFERRED:
VossMB requires static/circuit semantics and physical peer review. No optimization
or performance/default change, so tier-performance adoption is not requested.

Kovalev–Pryadko1212.6703v2, PhysRevA88,012311(2013), Eq19/Theorem9/Examples5–6.
PDF SHA and visual pages5/10/11 retained in raw/source-review.json. Only published
mathematics reimplemented; no source software/matrices/paper copied. NOTICE
credits the construction. Original GPL3+ scripts/data, no external solver or
outside-author communication. Paper perpetual distribution is not a software
license. LP prefix recognizes its lifted-product relationship, not a family-count
increment or claimed equivalence to an existing input.

Six cases and order fixed in issue205 before generation. Full numeric parameters
in scripts/codegen/hyperbicycle_cases.json. Two identical n15 factors h=[0,1,3,5],
c2/4/6 yield N900/1800/2700,K50; n7 h=[0,1,3] with n15 preceding factor,
c2/4/6 yield N420/840/1260,K30. chi1 throughout. Source900 exact14 control;
other five are original finite specializations, not inherited source named
cases. Theorem intervals14..14,14..28,14..42,8..8,8..16,8..24. Four c4/c6
cases had unconfirmed exact distance at selection, with no global-open/novelty
assertion. Keep all six after easy results; no reselection or stem rename.

## Local construction and preservation evidence

Actual stabilizer ranks each half425/875/1325/195/405/615 confirm all frozen k.
Full physical matrix entries match independent cyclic-incidence/carry and
transpose reconstruction. Complete scalar-set kernels of each ordinary factor
and transpose enumerate31 or7 nonzero words, prove repeated symmetry and finite
source hypotheses. Actual full CSS/logical quotients/pairings/GF2 words and
canonical stabilizer support connectivity pass. Initial actual Gx/Gz word
weights14/14,28/14,42/14,8/11,16/11,24/11, independently verified in GF2.
These are not claimed half minima. New finite exact/lower claims remain
PLAUSIBLE pending independent complete search/proof. In particular retain
the two larger symmetric cases already having a word matching the construction
lower14; do not relabel them as useful remaining open gaps.

40 pinned main/library versions scanned for all accepted Hx stems, excluding
quarantined files: no same-(n,k) peers. Full pinned refs and per-ref counts
in raw/peer-refs.json and raw/cross-branch-review.json. No unsupported arbitrary
permutation claim. Prior300 matrix files/24 manifest rows preserved (manifest
prefix byte identical); all src/Makefile unchanged. Preservation includes340
prior matrix/source/build files. Main stays51tiered+24untiered; this branch
adds6untiered/24files for30untiered/81total. No main integration/PR/tier/default/
QDistSAT change.

19 new meaningful contract/mutation tests plus34prior tests: final combined
log retained after execution.30tiny random incidences check actual columns and
commutation, scalar kernel vs full tiny brute force, transpose/carry/dimension/
invalid-entry/invalid-logical/false-coupling/symmetry/interval/missing-numeric/
actual-word-vs-search mutants. No Mac scientific solver experiment. All24
matrix files regenerate byte for byte and complete local validation.json
replays. Exact commands:

```
python3 scripts/codegen/hyperbicycle.py --all --out /tmp/gh205-hyperbicycle-staging
python3 scripts/codegen/validate_hyperbicycle.py --dir /tmp/gh205-hyperbicycle-staging --out optimization/experiments/GH-205/raw/construction.json
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 -m unittest discover -s tests -p 'test_codegen_*.py'
python3 scripts/codegen/hyperbicycle.py --all --out /tmp/gh205-hyperbicycle-rebuilt
```

raw/bch-triage.json records why six initially considered primitive binary BCH
choices are known exact from primary results and CSS purity. It is source
triage only, not a BCH implementation or a claim that every practical BCH
distance is known. Mainstream BCH remains a generally non-LDPC CSS coverage gap.

## Linux short gates and heavy completion protocol

One unchanged solver build.53units, full construction/inventory compare and24
matrix byte reproduction, then6default MaxSAT+6explicit CC serial smokes, each
60CPU/90wall seconds/4GiB/defaultseed/pinned allocated ephemeral affinityCPU.
One attempt per fixed case/engine,20minute job cap. Retain all logs, argv,
binary/source/input hashes and original missing fields, even on failure.
Scientific mismatch stops immediately; no parameter/order/engine substitution
or retries. Two independent complete engines+actual GF2 minimum word are required
for new search-confirmed exact claims. No timing medians, performance adoption,
fulltiers, paid cloud or external solvers.

Heavy unresolved proof or missing numeric gates will become a guarded unexecuted
yfclab2 serial package only after short outcomes. Each job6CPUh/6h10wall/4GiB,
seed0; limits are not expected run times. Explicit PI free-core allocation,
taskset/prlimit/nohup/nullstdin are required; no server core allocated. Packages
are not a waiver of incomplete gates. Source-construction intervals, actual
words and raw engine results remain separate fields and never fill each other.

Scientific semantics changed: no. PI action required: existing GH200/GH202
source decisions; later main integration and any server core allocation.

## Terminal short results and retained evidence

Data70c268bb38f866bb7d6cac4bf50b371a30039d98, scientific source
361f399d15801ffc2d68e9a6375ef46b03efb5e4, tree
2d05c543c527d0a3edb33725fe64ec8821cc2a72. Linux library run40961747658,
job123756014938 SUCCESS. Original53units/full geometry/classical hypotheses/
GF2/logicals/24matrix byte reproduction and all12numeric short gates PASS.
All12runs have the same source and binary SHA
68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a.
Source ordinary CI40961747630/job123756015467 SUCCESS. No scientific rerun.

| N,K | Original MaxSAT | Original CC | Actual X/Z upper words | Interpretation |
|---|---|---|---|---|
| 900,50 | [9,14] | exact14 | 14/14 | published exact14 control reproduced by CC |
| 1800,50 | [9,14] | exact14 | 14/28 | new finite search exact14 PLAUSIBLE |
| 2700,50 | [9,14] | exact14 | 14/42 | new finite search exact14 PLAUSIBLE |
| 420,30 | exact8 | exact8 | 8/8 | cross-checked both engines+actual GF2 minimum word |
| 840,30 | exact11 | exact11 | 11/16 | cross-checked both engines+actual GF2 minimum word |
| 1260,30 | exact11 | exact11 | 11/24 | cross-checked both engines+actual GF2 minimum word |

These are global distances/bounds; unequal half word weights do not supply
half minima. Source900 remains published exact14 rather than an open target.
N840/1260 finite11 confirms the initially unconfirmed cases without any global
novelty claim. Two larger symmetric easy14 outcomes and all original parameters
remain; no replacement or reclassification as distance-growth evidence.

Full764184-character job retained in raw/library-job-123756014938.log;
72nested engine files, original full construction and original audit in
raw/actions/default. No raw metadata overwritten or bounds filled. Local
replay of every log/input identity/source interval/actual word is byte-identical
to original audit.json. Source endpoint bounds, observed search bounds and
actual verified words remain separate fields in manifest and reports.

After the single scientific run, workflow-only2c66a9a2ab530ebd19904c3644adbb8fd897f03e
replaces solver execution with unit/construction/retained-log replay contracts.
General validator hardening fixes XOR cancellation for an unfrozen tiny
h=1+x^7 alias test; none of six frozen factors has such an alias, every frozen
construction JSON/matrix stays byte-identical. New regression plus prior53
tests gives local54 PASS; no renewed scientific search is needed or run.
Latest Linux contract status is recorded separately when available.

Three guarded default MaxSAT jobs are packaged; zero optionalCC, missingnumeric
or source-word jobs. Limits18CPUh/18h30wall total, not ETA. Dry-run3/default and
0/optional and Mac execution refusal pass; no allocation or execution.
README gives reproducible pinned-core/prlimit/nohup/nullstdin commands and
explicit PI execution guards. These jobs independently reproduce finite14;
they are not a claimed new unresolved global distance interval.

raw/next-source-review.json retains preliminary nonprimitive BCH root-set
checks N341/819/1365. No matrix, frozen batch or globally-open assertion:
additional recent primary-theorem review remains. This source review does not
complete the missing mainstream BCH coverage or waive outstanding family/
scientific/server/integration gates. Goal remains ACTIVE.
