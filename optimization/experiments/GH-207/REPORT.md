# GH-207 nonprimitive binary CSS BCH lower-reference targets

Status: LOCAL_CONSTRUCTION_PASS; LINUX_SHORT_GATES_PENDING. Goal ACTIVE.
Issue https://github.com/guluchen/DistQLDPC/issues/207; hub6509605442.
Branch codex/bch-library from main6083e662c621f3b66defd434cfae31a028d483c4.
Previous goal turn PROGRESS: GH2053ad90734 completed six-input structural/
numeric gates,54Linux retained-only contracts and final CI40963734046SUCCESS,
with3unexecuted MaxSAT jobs. GH200/GH202 scientific holds remain unchanged.

## Three proposals, source review and frozen cases

CHOSEN missing mainstream CSS BCH, with rigorous lower-only targets;
DEFERRED quantum Reed–Muller known-distance controls; DEFERRED VossMB static/
circuit/peer review. BCH is generally dense CSS, not a qLDPC/asymptotically-good
claim. No solver behavior/performance change, so no timing/default adoption
request or tier-performance experiment.

Aly–Klappenecker–Sarvepalli quant-ph/0604102v1, IEEE TIT53,1183–1188(2007),
DOI10.1109/TIT.2006.890730, Lemma1/Theorems3/10/19/Lemmas12/17(b). Visual PDF
pages9/14 and PDF hashes in raw/source-review.json/source-pdf-sha256.json.
Wang–He–Yi–Zheng2609.00532v2 Theorem21/Example23, visual PDFp23, supplies
classical85,69,5; CSS purity and actual subgroup word establish the control.
Related Chen–Xie–Ding2510.22259v1 Sec6/7 and Chen–Chen–Ding–Lao2604.23594v1
were reviewed for newer exact claims. Their relevant exact statements concern
different delta/offset/characteristic or primitive hypotheses, not the four
chosen higher-delta narrow-sense codes. Earlier GH205 tentative classification
of2609.00532 as primitive was corrected here: it concerns nonprimitive length
families with specific delta3/5. No GH205 matrix/result is affected.

Original GPL3+ mathematical implementations only. No author code/matrix/paper
text/images redistributed or external distance solver used.2006arXiv perpetual
distribution is not a software license;2026CCBY4 and2025CC0 sources credited
in NOTICE. Source exact/lower-only/reference statuses remain distinct; absence
of an exact claim in reviewed sources is not a globally-open/novelty claim.

Five inputs/order fixed in issue207 before generation. Full parameters in
scripts/codegen/bch_cases.json:

| ID | n,k | m,p | designed delta | Reference |
|---|---|---|---|---|
| anchor85 | 85,53 | 8,0x11d | 5 | classical exact5+CSS purity; actual5 word |
| lower341 | 341,261 | 10,0x409 | 9 | general construction lower9 only |
| lower819 | 819,699 | 12,0x1053 | 11 | general construction lower11 only |
| lower1365d17 | 1365,1173 | 12,0x1053 | 17 | general construction lower17 only |
| lower1365d19 | 1365,1149 | 12,0x1053 | 19 | general construction lower19 only |

All b1, beta=alpha^((2^m-1)/n), physical coefficient X^i. Source quantum k
predictions guard actual ranks before any write. Primitive polynomials are
first monic primitive by numeric order, checked with complete field cycles;
this algebraic representation choice is not a distance parameter search or
additional code count. Prefix BCH proposed on work branch; no stem rename.

## Local independent construction, evidence and preservation

Generator multiplies Frobenius-closed root factors to obtain binary g, divides
X^n+1 and shifts reciprocal(h) to obtain both Hx/Hz. Independent implementation
uses carryless-field products/irreducibility/full primitive group/root order,
literal binary physical root-syndrome columns and a one-dimensional truncated
kernel to derive g. Independent coefficient-list division reconstructs every
actual stabilizer entry and full root rowspaces. Vandermonde soundness proof
in MODIFICATIONS.md and data/matrices/untiered/BCH.md establishes the source
lower only after the physical root-rowspace check. Complete GF2/logical
quotient/pairing and identity physical XZ map checks PASS.

Actual ranksHx/Hz16/40/60/96/108 each; complete Gx/Gz rows53/261/699/1173/1149.
Canonical support components single85/341/819/1365/1365. Actual check weights
40/148/372/612/624 (dense). Actual Gx/Gz basis uppers6/6,13/13,21/21,36/36,41/41,
plus explicit source-control support0/17/34/51/68 gives5 in both halves.
All words independently GF2 syndrome/quotient/detector verified; not claimed
half minima or new exact results. Source lower endpoints never fill missing
or weaker engine fields. Four lower-only cases have NO source upper-word
target; searching for a word at the lower bound is not a prerequisite.

41pinned main/library refs (main+40matrix branches), accepted Hx stems scanned
excluding quarantine, no same-(n,k) peers. Full refs/counts retained in raw/.
Different field presentation/physical permutation variants not added. No
arbitrary inequivalence theorem inferred from file hashes.20matrix byte
regeneration PASS. Prior300matrix files/40src-build files unchanged; prior24
manifest rows remain a byte-identical prefix. This branch29untiered/80total;
main remains24untiered+51tiered. No PR/main/default/tier/QDistSAT changes.

57units (23new+34prior),30tiny random source constructions and120random field
products PASS: independent entries/field/canonical polynomials/source root
dimensions, nonprimitive/reducible modulus/incorrect root order/reciprocity/
entry/logical/dimension/invalid-word/exact-answer/source-floor/missingnumeric/
unmaterialized-upper mutants. Mac algebra/generation/tiny unit correctness
only, no scientific distance solver experiments. DefaultHGP12 and explicit
BCH5 dry selections verified; sample CPU54 is syntax only, no allocation.

```
python3 scripts/codegen/bch.py --all --out /tmp/gh207-bch-staging --receipt optimization/experiments/GH-207/raw/generation.json
python3 scripts/codegen/validate_bch.py --dir /tmp/gh207-bch-staging --out optimization/experiments/GH-207/raw/construction.json
python3 -m unittest discover -s tests -p 'test_codegen_*.py'
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 scripts/codegen/bch.py --all --out /tmp/gh207-bch-rebuilt
```

## Preregistered bounded Linux and heavy completion

One unchanged build,57units/full independent construction/inventory compare/
20matrix byte regeneration. Five default MaxSAT and five explicitCC, once
each per case/engine in fixed order, serial60CPU/90wall seconds/4GiB/default
seed/pinned allocated ephemeral affinityCPU,20min job cap. Immediate per-case
word/source/explicit-answer consistency checks stop semantic contradictions;
always retain raw logs/source/binary/all4input hashes even on failure.
Two complete independent engines+actual GF2 minimum word confirm new finite
search exact results; otherwise stronger new search bounds stay PLAUSIBLE.
Source-construction bounds and observed bounds remain separate. A reported
upper without a materialized word remains an INCOMPLETE word gate, never an
invented verified word. No scientific retries, parameter/order changes,
cardinality sweeps, timing medians/adoption, fulltiers or paid cloud substitute.

Only incomplete proof/numeric/word gates become guarded unexecuted yfclab2
packages after short results. Each6CPUh/6h10wall/4GiB/seed0, serial taskset,
prlimit/nohup/nullstdin. Limits are not runtime expectations. Explicit PI
allocation/free-core verification required; no core allocated or server run.
No third-party solver, source hold diagnosis or external communication.

Scientific semantics changed:no. PI action required: existing GH200/GH202
source decisions; future main integration and server execution allocation.


## Terminal short gates and independent finite certificates

The five frozen input pairs ran once each, serial, at source
`25936e3f36aad13fa47ba85708af68b01c274b0a` (tree
`de3f3cee70daf19213e667b6702d96096f62f45c`). Scientific run
[40966974370](https://github.com/guluchen/DistQLDPC/actions/runs/40966974370),
job123773827366, and source CI40966974267/job123773827581 succeeded.
The complete468624-character job and all60 engine evidence files, construction
receipt and original audit are retained in raw/. Resource and binary/source/
4input identities remain in each case's JSON. No scientific retry occurred.

| Frozen input n,k | Raw default MaxSAT | Raw CC | Actual word upper | Independent physical certificate |
|---|---|---|---:|---|
|85,53|5..5 SOLVED|5..5 SOLVED|5|exact5 source control|
|341,261|5..9 BOUNDED|7..9 BOUNDED|9|exact9|
|819,699|3..11 BOUNDED|6..11 BOUNDED|11|exact11|
|1365,1173|null/null TIMEOUT_NO_BOUNDS|5..22 BOUNDED|22|17..22|
|1365,1149|null/null TIMEOUT_NO_BOUNDS|5..24 BOUNDED|24|19..24|

All reported uppers have independently verified physical words. Four lower-only
source cases have no source upper-word target. Numeric smoke gates are PASS
for first3 and INCOMPLETE for last2; null fields are preserved. No source or
certificate lower replaces raw search fields, and original audit.json is
byte-identical. Original `confirmed_exact` remains null for four non-controls.

A separate implementation, scripts/codegen/bch_certificate.py, now verifies
finite lower/upper proofs without importing the constructor, logical builder,
physical validator or either engine. It checks irreducible fields using its
own coefficient-list arithmetic, n distinct nonzero roots, and every one of
32/80/120/192/216 binary root equations as an explicit XOR of ACTUAL H rows.
The Vandermonde proof excludes every nonzero kernel word below delta. An actual
kernel upper word and a separately checked kernel detector with odd pairing
prove nontriviality outside stabilizer space. Odd-weight words may serve as
their own detector; no assumption about a bundled logical basis is needed.
Both physical halves are identical and independently checked. Thus exact9/11
are CROSS_CHECKED_INDEPENDENT_ALGEBRAIC_CERTIFICATE_AND_GF2_WORD, separate from
search-confirmed exact and from published exact. No novelty/global openness
claim. Proof acceptance does not alter solver semantics or retry a search.

Local73contracts (57prior+14certificate+2server-guard), including120additional random field
products, missing/wrong root equations, bad order/field, duplicate/nonkernel
words, invalid/even-pairing detectors and physical identity mutants PASS.
Static Linux workflow now checks these proofs,20byte regeneration and replays
original10logs only; certificate Linux result is pending this evidence commit.

Only the two n1365 default MaxSAT missing-numeric/proof cases enter the frozen
required server queue. Optional CC queue contains the same two genuine gaps.
Neither exact9/11 case needs another complete search to confirm its certificate.
Each21600CPU/22200wall seconds/4GiB/seed0, serial: required2 limits12CPUh/
12h20wall; both queues24CPUh/24h40wall, ceilings not estimated runtime.
No core allocated or execution. Queue, inputs, source/build trees, certificates,
old actual words and clean checkout guards must pass before execution on
allocated/free yfclab2. Dry plans only were checked locally.

Prior300matrix files/40source-build files and24manifest rows remain unchanged;
20new matrices unchanged. Main, tiers, defaults, QDistSAT and all stem names
unchanged; no PR. These are dense CSS BCH codes, not qLDPC. GH200 remains
separately held. Latest authorized GH202 CC500 independently agrees with8,
while published6 remains unreproduced; all24 inputs remain quarantined (see
GH202 branch4ed02242f04d4cf9ae0e2f1966f795d209e5a83c), without labeling repair.

What changed: terminal evidence, separate finite certificates, manifest observed
fields and guarded remaining-work package. Validation: physical/source/GF2/
logicals/byte/static contracts and retained10short attempts. Results: exact
5/9/11 and intervals17..22/19..24. Unresolved: last2 numeric/proof gates,
source holds, server allocation, mainstream gaps and main integration.
Scientific semantics changed:no. PI action required: future server core
allocation/integration and source-label decisions; no routine certificate approval.
