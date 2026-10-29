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
