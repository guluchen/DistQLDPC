# GH209 polynomial-minor cyclic CSS targets

Status: CONSTRUCTION_AND_WORD_GATES_PASS; FOUR_REQUIRED_SERVER_GATES_INCOMPLETE;
final retained-only Linux pending. Whole-library
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


## Terminal native evidence and remaining gates

Scientific sourceb859a70a30b0be63a26d2d2df68024a406927d54, tree
49e7354f862b08f61b9a388b85ab452d9e1064f4, [41009341781](https://github.com/guluchen/DistQLDPC/actions/runs/41009341781)/
job123911436532 SUCCESS.53Linux units, physical/Smith/logical/source/word/
connectivity/inventory gates and24byte reproduction PASS, then exactly6default
MaxSAT+6CC one-shot short attempts. Source general CI41009341788/job123911436549
and data CI41009227430 SUCCESS. No scientific retry. Identical compiled binary
68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a on all12.

|n,k|Raw default MaxSAT|Raw CC|Actual GF2 upper|Status|
|---|---|---|---:|---|
|27,4|4..4 SOLVED|4..4 SOLVED|4|source4 independently reproduced|
|255,80|5..12 BOUNDED|8..12 BOUNDED|12|published12, both native proofs INCOMPLETE|
|765,88|3..64 BOUNDED|8..76 BOUNDED|54|original unknown target|
|1275,80|5..138 BOUNDED|8..100 BOUNDED|54|original unknown target|
|1785,80|null/null TIMEOUT_NO_BOUNDS|8..140 BOUNDED|54|default numeric gate INCOMPLETE|
|2805,80|null/null TIMEOUT_NO_BOUNDS|8..220 BOUNDED|54|default numeric gate INCOMPLETE|

Every actual source/basis/primitive/native word independently GF2 verified.
Reported-upper-word and exact-minimum-word gates PASS for every case; no
missing-word job. Both source controls have actual minimum-weight upper words,
but the255source lower12 has not been reproduced by either native search in
60seconds. This is an INCOMPLETE control proof, not a contradiction or an
erratum. Its source exact12 claim remains a source field, never injected into
native5/8lower fields. Four new CC8 lower bounds remain PLAUSIBLE, not renamed
or advertised as independently certified8..54. Both-engine conservative new
intervals are3..54 and5..54 on n765/1275; larger two have no independent search
lower beyond the trivial positive-weight floor1. Actual upper54 is rigorous.
No global openness/novelty claim. Original raw fields/audit remain unchanged.

Exactly4REQUIRED remaining jobs: both255source-control proofs and two missing
default numeric gates1785/2805. Optional2MaxSAT+4CC are further research on
intended unknown targets, not failed exact-distance acceptance gates. No core
allocated or execution. Each21600CPU/22200wall/4GiB/seed0,serialtaskset/prlimit/
nohup/nullstdin with explicit PI allocation/free-core/source/input/word guards.
Required4 ceilings24CPUh/24h40wall; optionalMaxSAT2=12CPUh/12h20wall;
optionalCC4=24CPUh/24h40wall; all10 ceilings60CPUh/61h40wall. Limits, not ETA.

Complete1810159-character native job and72engine files retained. Lossless
transport34indexed chunks decoded12945962payload bytes; SHA256
7b3fcea9394806daf7a930114b3bfb469bca6e3d827ac7d71c2946c18380484e plus length/
chunk-index/gzip-CRC checks all PASS. Complete construction and original audit
retained, byte-identical source construction, local12log/word replay PASS.
Transport decoder/receipt persisted so no evidence relies on expiring artifacts.

Retained-only transitionf8e399c215b0ea11a3b48c4506b4f9187137573a removed native
commands BEFORE follow-up edits.62local contracts (53original+9server-gate
planning/allocation/source/queue guards) PASS. Final static Linux pending.
No additional native searches. Every frozen matrix unchanged; prior300matrix/
40source-build files and24prior manifest rows unchanged; main/default/tier/
stem/QDistSAT untouched and no PR. Existing GH200/GH202 holds remain separate.

Related-family audit: GH198 full TT/Koszul triplet prescription reviewed; PM
is not counted as a disjoint family. For the SAME minor triplet at oddN,
full Koszul k=3deg(g1), versus PM k=deg(g)+2deg(g1); dimensions6/84/96/84/84/84
would differ from actualPM4/80/88/80/80/80. This limited rank comparison does
not assert arbitrary inequivalence to all possible other constructions.

What changed: six reproducible PM inputs, source provenance, independent
physical/Smith/logical/constructive-word validation, complete native evidence
and remaining-work packages. Validation:53originalLinux+62localstatic checks,
43pinned peers,24byte regeneration,12raw-log/witness replay and transport SHA.
Results:known4cross-checked; published12control proof incomplete; four original
unconfirmed targets retain verified upper54 and provisionalCC8. Unresolved:
4required server gates, intended unknown distances, existing source/mainstream/
server/integration backlog. Scientific semantics changed:no. PI action required:
future core allocation/integration/held source decisions; routine archive needs
no extra permission. Whole-library objective remains incomplete.
