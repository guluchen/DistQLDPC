# Polynomial-minor cyclic CSS inputs (GH209)

Proposed prefix PM; a three-block quasi-cyclic CSS construction prescription,
not a claim of a disjoint mathematical family or new globally-open codes.
Source: V. Nourozi, R. Smarandache and D. G. M. Mitchell,
*Quantum LDPC Codes from Polynomial Minors*,
[arXiv2610.19459v1](https://arxiv.org/abs/2610.19459v1),14Oct2026,
Eqs10/11,Theorem5,TablesI/II. Original mathematical reconstruction under
GPL3+; the source paper is CC BY4.0, attributed in NOTICE. No author program,
matrix file, paper text or images redistributed; no external distance solver.

All13 examples in the paper have known exact distances. This batch preserves
two source controls and adds four ORIGINAL longer lifts whose distances are
unconfirmed in the reviewed sources. It does not turn known examples into
open problems or assert global novelty. Parameters/order were fixed before
generation/search in issue209; k predictions were frozen before matrix writes.

|Case|Lift N|n|k|Source claim|Initial verified overall upper|
|---|---:|---:|---:|---|---:|
|source27|9|27|4|exact4, TableII Example1|4, independent tiny control|
|source255|85|255|80|exact12, Example13|12, actual source X word|
|lift255|255|765|88|unknown, original specialization|54, fixed algebraic word|
|lift425|425|1275|80|unknown, original specialization|54, fixed algebraic word|
|lift595|595|1785|80|unknown, original specialization|54, fixed algebraic word|
|lift935|935|2805|80|unknown, original specialization|54, fixed algebraic word|

Larger lifts use the UNSCALED Example13 supports a={0,17,24,34,40,44,45},
b={5,22,29,39,45,49,50},c={1,38,41,46,55,65,74,84},t=0,q=1. They do not
inherit distance12, k80, decoder performance or a source expansion theorem.
The first lift has k88, confirmed independently; a copied k80 would be wrong.
Row weights are22/75 on the four new inputs, versus22/61 at N85 due to
cyclic cancellation. Check weights stay bounded for these fixed polynomials;
no asymptotic nonzero-rate or growing-distance claim is made.

## Physical construction and independent verification

Work in GF2[X]/(X^N+1). C(p) has coefficient first row, successive rows shift
RIGHT, and p^T=p(X^-1). Physical qubit(j,u)=j*N+u, j=0,1,2.

```
Hx = [[a^T,b^T,c^T], [c^T,a^T,b^T]]
Hz = [b²+ac, ab+c², a²+bc]
```

The two polynomial Laplace identities hold before reduction. Transposition
then gives Hx*Hz^T=0 on the actual expanded binary matrices. The generator
uses integer cyclic products/rotations and records all original cyclic check
rows. Independent validation uses coefficient-list arithmetic, literal
physical displacement i-e for Hx and i+e for Hz, and ordinary Smith minors.

For the unstarred2x3 polynomial matrix, gamma1 is the gcd of entries, gamma2
the gcd of unreduced minors. Smith factors with X^N+1 predict actual rankHx;
the gcd of cyclic minors predicts rankHz. Odd N makes X^N+1 square-free,
yielding k=deg(g)+2deg(g1), with g=gcd(a,b,c,X^N+1) and g1 the minor gcd.
Both formulas must agree with the actual binary ranks. Actual ranksHx/Hz:
16/7,118/57,454/223,798/397,1138/567,1818/907. Every matrix entry, complete
logical quotient basis and pairing is checked independently.

Source X logicals lie in ker(Hz) outside rowspace(Hx). Bundled Gx instead
lies in ker(Hx), detecting X logicals; its rows represent Z logicals. The
validator respects both conventions explicitly. Unequal physical ranks
obstruct a pure permutation X/Z exchange; no dual map is assumed.

The source weight12 word is checked directly at support
{0,14,39,40,45,51,54,62,186,195,199,230}. For the27-qubit control, an independent
tiny reference exhausts supports below4 in BOTH halves, then finds the first
weight4 logical. Larger codes undergo no local distance search.

## Fixed constructive upper words

Let u be the ordinary gcd of a,b,c. Dividing the first polynomial syzygy row
by u preserves its exact Laplace identity; physical reflection gives
((a/u)^T,(b/u)^T,(c/u)^T) in ker(Hz). If u shares a factor with X^N+1, the
primitive row is nonzero at a root where the original rows vanish, so it is
outside the original stabilizer module. Rather than trusting this argument
alone, the verifier checks the actual word's syndrome, stabilizer quotient
and odd pairing with the opposite logical detector.

This ONE deterministic construction gives weight54 for N85 and all four
larger lifts; it is not a parameter/order/random-distance search. The source
word12 remains better at N85. Ordinary bundled-basis uppers in both halves
are retained too: X6/Z7, source X20/Z28 before adding its explicit12 word,
X96/Z84,X100/Z140,X140/Z196,X220/Z308. Construction.json contains every actual
word and provenance; reported native fields are never overwritten by these.

Canonical RREF is formed separately for each stabilizer space, and their
support-component union is connected at every frozen n. This is basis
invariant; merely mixing displayed rows cannot turn a direct sum into a
connected code. Forty-three pinned main/library refs have no same(n,k) peer.
No arbitrary column-permutation/global inequivalence theorem is inferred.

```sh
python3 scripts/codegen/polynomial_minors.py --all --out /tmp/pm-rebuilt
python3 scripts/codegen/validate_polynomial_minors.py --dir /tmp/pm-rebuilt --out /tmp/pm-validated.json
python3 -m unittest discover -s tests -p 'test_codegen_*.py'
```

All inputs stay `_unknown` in untiered. Known exact controls must reproduce;
unknown-target exact distance is not an acceptance prerequisite. Missing
numeric fields or missing actual minimum words remain INCOMPLETE. Numeric
exact agreement without a GF2 minimum word stays PLAUSIBLE, never confirmed;
actual contradictions remain fatal. Linux one-shot short checks and remaining
unexecuted server packages are recorded in GH209/REPORT.md. No solver/default,
tier, stem, main or QDistSAT change is authorized by this library batch.
