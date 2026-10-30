# Binary nonprimitive CSS BCH inputs (GH-207)

Proposed prefix BCH. These are dense binary CSS representatives, not a qLDPC
or asymptotically-good-code claim. Parameters were fixed in issue207 before
generation or distance searches. Different field presentations are not counted
as additional codes; each chosen polynomial is the first monic primitive
binary polynomial in numeric order.

Source: Aly, Klappenecker and Sarvepalli, *On Quantum and Classical BCH Codes*,
[quant-ph/0604102v1](https://arxiv.org/abs/quant-ph/0604102v1), Theorems3/10/19,
Lemmas12/17(b), IEEE TIT53,1183–1188(2007), DOI10.1109/TIT.2006.890730.
The exact5 control uses classical [85,69,5] in Wang, He, Yi and Zheng,
[2609.00532v2](https://arxiv.org/abs/2609.00532v2), Theorem21/Example23,
and the CSS purity condition. This is a theorem specialization, not a named
published [[85,53,5]] numerical table being copied.

| Fixed case | n | Quantum k | m | Primitive polynomial, bits | Designed delta | Reference |
|---|---:|---:|---:|---|---:|---|
| anchor85 | 85 | 53 | 8 | 0x11d | 5 | exact5 after CSS purity and actual word |
| lower341 | 341 | 261 | 10 | 0x409 | 9 | construction lower9 only |
| lower819 | 819 | 699 | 12 | 0x1053 | 11 | construction lower11 only |
| lower1365d17 | 1365 | 1173 | 12 | 0x1053 | 17 | construction lower17 only |
| lower1365d19 | 1365 | 1149 | 12 | 0x1053 | 19 | construction lower19 only |

The four latter exact distances are unconfirmed in the reviewed primary
sources, not asserted to be globally open problems. Published exact statements
at delta3/5 do not determine these codes at delta9/11/17/19. Offset-zero,
nonbinary and primitive-family theorems are not silently transferred here.
All outcomes, including easy or poor cases, must be retained.

## Physical construction

Work over GF(2)[x]/p with alpha=x, beta=alpha^((2^m-1)/n). Physical qubit i
is coefficient X^i. Let Z be the union of binary cyclotomic cosets containing
1 through delta-1. Form g(X)=product over j in Z of (X+beta^j); Frobenius
closure makes g binary. Divide X^n+1 by g to obtain h. The first deg(g) shifts
of reciprocal(h) are a full basis of C-perp for C=<g>. Store these rows as
both Hx and Hz, then compute complete logical quotient bases with the existing
repository builder. Gx is Z-type; Gz is X-type.

The constructor checks full primitive field order, exact beta order, source
hypotheses, disjoint negative defining sets, dimensions and self-orthogonality
before writing anything. It refuses overwrites. The independent auditor uses
carryless polynomial products, irreducibility tests and binary coordinates
of all physical root syndromes. A one-dimensional kernel on degree<=rank
polynomials derives g independently of the constructor's root product. List
polynomial division independently reconstructs every stored stabilizer entry.
Full root-rowspace equality, logical quotients, pairing and identity physical
XZ map are checked. Canonical support components are connected.

## Soundness of the source lower and control upper

Suppose a nonzero C word has w<delta supported at distinct positions i_t.
Its first w root equations have coefficient matrix (beta^i_t)^j for j=1..w.
This is a Vandermonde matrix times a nonsingular diagonal matrix: the n-th
roots are distinct and nonzero. Its determinant is nonzero, forcing all
coefficients to vanish, a contradiction. Thus every nonzero C word has weight
at least delta. Each nontrivial quantum logical belongs to C and is nonzero,
so this is also a quantum distance lower bound. The independent physical root
rowspace check is essential to this argument.

For n85, the explicit support0/17/34/51/68 is a five-term subgroup sum,
vanishing at the required first four roots. GF2 syndrome/quotient/detector
checks verify it in both halves. Source dual distance>=6 additionally
validates transferring the published classical exact5 to CSS exact5.
Initial actual logical-basis uppers are6/6,13/13,21/21,36/36,41/41. The first
case has the separate actual5 word. No basis upper is a claimed minimum.
Check-row weights40/148/372/612/624 demonstrate the stored matrices' density.

## Reproduction and remaining gates

```
python3 scripts/codegen/bch.py --all --out /tmp/bch-new --receipt /tmp/bch-generation.json
python3 scripts/codegen/validate_bch.py --dir /tmp/bch-new --out /tmp/bch-validation.json
python3 tests/test_codegen_bch.py
```

41 pinned main/library refs have no same-(n,k) peers, including XZ swaps by
dimension exclusion. All20 files reproduce byte for byte, with full GF2 and
logical checks. Source-construction lower bounds, observed solver bounds and
actual verified words are separate; no missing or weaker engine field is
filled from a theorem. New finite search results stay PLAUSIBLE until an
independent complete cross-check and GF2 minimum word. Linux short gates and
any necessary unexecuted server jobs are tracked in GH207/REPORT.md.

Original scripts/matrices GPL3+; only published mathematics reimplemented.
No author software/matrix or paper text/images redistributed. Paper licensing
is not reused as a software license. Attribution and source licenses in NOTICE.
No main/default/tier/QDistSAT changes; GH200/GH202 source holds remain separate.


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
original10logs only; certificate Linux result PASS at run40984476152/job123832151018, source25a948a7a99c16beed75d4018ff838d56184d072.

Only the two n1365 default MaxSAT missing-numeric/proof cases enter the frozen
required server queue. Optional CC queue contains the same two genuine gaps.
Neither exact9/11 case needs another complete search to confirm its certificate.
Each21600CPU/22200wall seconds/4GiB/seed0, serial: required2 limits12CPUh/
12h20wall; both queues24CPUh/24h40wall, ceilings not estimated runtime.
No core allocated or execution. Queue, inputs, source/build trees, certificates,
old actual words and clean checkout guards must pass before execution on
allocated/free yfclab2. Dry plans only were checked locally.
