# GH-205 repeated-cyclic CSS hyperbicycle targets

Status: LOCAL_CONSTRUCTION_PASS; LINUX_SHORT_GATES_PENDING. Goal ACTIVE.
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
