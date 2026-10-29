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
