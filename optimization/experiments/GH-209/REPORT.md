# GH209 polynomial-minor cyclic CSS targets

Status: LOCAL_CONSTRUCTION_PASS; Linux short gates pending. Whole-library
objective incomplete. Issue https://github.com/guluchen/DistQLDPC/issues/209;
hub6515461156, algebraic dimension checkpoint6515506686. Branch
codex/polynomial-minors-library from main6083e662c621f3b66defd434cfae31a028d483c4.
Fresh186branches/open-issue review: no competing minor-library/Mac-agent topic.
Prior GH205/207/208 terminal evidence, GH200/GH202 holds, literature and policy
read. This is a library construction task, not a solver/performance experiment.

## Three proposals and frozen target definitions

Chosen: missing explicit2x3 polynomial-minor QC CSS prescription, sparse
original longer lifts with unconfirmed finite distances. Expected effect:
structural diversity and useful unresolved-distance targets; main risks are
transpose/circulant convention, inherited dimension/distance, false connectivity
from a mixed row basis, and X/Z logical/detector naming. Deferred composite
duadic targets (less structural diversity after dense QR); deferred Reed–Muller/
Shor exact controls (lower priority than suitable unknown-distance targets).
This is a construction specialization, not a disjoint family/novel-code claim.

Nourozi–Smarandache–Mitchell2610.19459v1,14Oct2026,CCBY4.0, Eqs10/11,Theorem5,
TablesI/II Examples1/13. Visually reviewed PDFp3/4/5, version/hash/license in
raw/source-review.json. All13 source distances are exact, not published open
problems. Original GPL3+ mathematics/programs/matrices; no author program,
matrix file, paper text/images copied and no external distance solver used.

Six ordered cases fixed in issue209 before generation/search:

|ID|N|n,k|Reference|
|---|---:|---|---|
|source27|9|27,4|published exact4|
|source255|85|255,80|published exact12; source X word Eq23/24|
|lift255|255|765,88|original finite lift, no inherited source d|
|lift425|425|1275,80|original finite lift, no inherited source d|
|lift595|595|1785,80|original finite lift, no inherited source d|
|lift935|935|2805,80|original finite lift, no inherited source d|

All t0,q1, coefficient first row/right-shifting circulants; block-major qubits.
New lifts retain UNSCALED Example13 entries, not spaced exponents or disconnected
copies. K from the odd-lift gcd formula was frozen before writes and independently
matches actual binary ranks. In particular, k88 at n765 cannot inherit k80.
No distance/polynomial/parameter/row-order sweeps or replacement of easy/poor
frozen results. PrefixPM proposed; all stems remain PM_<n>_<k>_unknown.

## Physical/source/logical soundness and constructive words

Constructor uses integer cyclic arithmetic; independent checker uses literal
physical incidence and coefficient-list convolution/Euclid/Smith invariants.
Both exact Laplace identities establish CSS cancellation. Every physical entry,
source control rank/weight, generic Smith and odd square-free rank formula,
commutation, full logical quotient bases and complete pairing verified.
Source X words in kerHz/rowHx are separate from bundled Gx detector rows in
kerHx. All actual ranksHx/Hz unequal, so no permutation X/Z exchange assumed.
Actual ranks16/7,118/57,454/223,798/397,1138/567,1818/907; source255matches
published118/57. Check weights8/11,22/61, then22/75 on each longer lift.

Written proof in POLYNOMIAL_MINORS.md/MODIFICATIONS.md. A fixed primitive first
row obtained by dividing a,b,c by their ordinary common factor preserves the
exact Laplace syzygy. At a shared root with X^N+1 it is outside the original
stabilizer module. Physical reflected words are separately verified by GF2
syndrome/quotient/odd-detector checks. Weight54 for N85 and all four new lifts;
raw/primitive-row-witnesses.json retains the complete physical supports. This
is ONE deterministic algebraic construction, not a distance or parameter
search. Source255actual word12 remains better. No native upper field is filled
from the constructive bound and no bound is injected into the native solver.

Independent tiny27 correctness reference exhausts BOTH halves at weights1..3
then finds the first physical weight4 logical. No native or larger distance
search on Mac. Initial actual overall uppers4/12/54/54/54/54; complete logical
basis uppersX6/Z7,X20/Z28,X96/Z84,X100/Z140,X140/Z196,X220/Z308 retained separately.
Source12 or either source rank/rate is not transferred to the four new cases.

Canonical RREF for EACH stabilizer space and the union of their physical
supports gives single components27/255/765/1275/1785/2805. The direct-sum
row-mixing mutant is caught: displayed Tanner connectivity alone is not used.
Forty-three pinned accepted main/library refs, no same(n,k) peers, quarantine
excluded. No arbitrary-permutation/global inequivalence claim. Full refs and
counts in raw/cross-branch-review.json.

## Local validation and preservation

53units (19new+34prior),30tiny randomized odd-lift physical/Smith cases,
80independent cyclic products, GF2 alias/transpose/rank/nonCSS/logical/source/
physical-entry/equivalent-reflection/connectivity/overwrite/timeout/word mutants.
All PASS. Numeric exact agreement without an actual GF2 minimum word stays
PLAUSIBLE and word gate INCOMPLETE; it never becomes confirmed exact. Missing
word evidence is distinguished from an actual semantic contradiction, which
still stops. New helper is branch-local; shared parser/raw native fields and
existing source claims are not reinterpreted. Known exact controls still must
reproduce. This distinction prevents absence of a certificate being reported
as a false solver contradiction.

24matrix byte regeneration PASS. Prior300matrix/40source-build files unchanged;
24prior manifest rows byte-identical prefix. Branch30untiered+51tiered; main
remains24untiered+51tiered. DefaultHGP12 versus explicitPM6 dry selections only;
exampleCPU54 is not an allocation. No solver/default/tier/stem/QDistSAT/main
change and no PR. Prior source holds are untouched.

```
python3 scripts/codegen/polynomial_minors.py --all --out /tmp/gh209-staging --receipt optimization/experiments/GH-209/raw/generation.json
python3 scripts/codegen/validate_polynomial_minors.py --dir /tmp/gh209-staging --out optimization/experiments/GH-209/raw/construction.json
python3 -m unittest discover -s tests -p 'test_codegen_*.py'
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 scripts/codegen/polynomial_minors.py --all --out /tmp/gh209-rebuilt
```

## Preregistered Linux and remaining-work boundary

One unchanged build;53units, full source/incidence/Smith/GF2/logical/connectedness
and actual-word reconstruction, inventory compare and24matrix byte reproduction.
Six serial default MaxSAT then six serial explicitCC, once per case/engine,
60CPU/90wall seconds/4GiB/defaultseed0/v/pinned ephemeral affinityCPU;20min job
cap. Immediate per-case actual word/source/numeric consistency audit. Stop
contradictions, retain partial/failure evidence; no scientific retries or
parameter/order/cardinality sweeps. Source known exact4/12 kept distinct from
native output, and original lifts have NO published lower/upper estimate.
New search claims PLAUSIBLE until independent search/implementation and actual
GF2 word. Unknown-target exact completion is not an acceptance prerequisite.
Missing numeric/proof/word gates get guarded unexecuted yfclab2 queues; optional
further unknown-distance searches are separate, each21600CPU/22200wall seconds/
4GiB/seed0/taskset/prlimit/nohup/nullstdin, explicit allocation/free-core check.
No core allocated, no paid cloud substitute, limits not runtime expectations.

Evidence export is lossless gzip/base64 in40K-character indexed log chunks,
with uncompressed payload SHA256 and full input/source/binary/native files.
This avoids oversized inline records being silently truncated. The decoded
files and complete original job log are archived permanently after terminal
results; temporary workflow artifacts are not the only evidence.

What changed:6minor-CSS inputs/generator/provenance, complete independent
physical/Smith/logical validation and actual constructive upper words.
Validation:local53units/43peers/24byte regeneration; Linux pending. Results:
known source4/12 controls plus four genuine unconfirmed-distance specializations
with actual word54. Unresolved:Linux native gates, scientific/server/integration
and mainstream backlog. Scientific semantics changed:no. PI action required:
only actual source ambiguity, future server allocation or integration.
