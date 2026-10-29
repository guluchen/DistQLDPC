# Original finite SL(2,p) quantum Margulis CSS inputs (GH-187)

Three fixed cases p5/7/11, n240/672/2640, k4/20/58. QMC identifies quantum
Margulis provenance within2BGA, not a mathematically disjoint family. These
are original finite specializations with individually unconfirmed distance,
not asserted globally open research problems or reproductions of author data.

## Source and license boundary

Michele Pacenti, Dimitris Chytas and Bane Vasic,
*Construction and Decoding of Quantum Margulis Codes*,
[2503.03936v3](https://arxiv.org/abs/2503.03936v3), Quantum10,2101(2026),
[DOI](https://doi.org/10.22331/q-2026-05-12-2101), Sec3 Eq8 and Sec4 Eqs10–11.
The mathematical source is [CC BY4.0](https://creativecommons.org/licenses/by/4.0/).
Original scripts and generated matrices are GPL-3.0-or-later. No author
code, matrix files, paper prose or images copied; no external group/distance
solver run; no author endorsement claimed. Original fixed conjugators below
replace the paper's randomized example-selection procedure.

The author repository Error-Correction-Lab/quantumMargulisCodes at
a25d3bad4682a207fc7df67edfd96dffe5ca4a5b has no detected license/root LICENSE.
Only metadata/root listing was used; no matrix or implementation was copied.
The paper repeatedly labels p7 length642 although its group formula gives
672. This batch follows its unambiguous SL2 formula with original parameters;
it does not silently repair, identify or inherit the ambiguous author
instance's dimension/girth/decoder claim. Reproducing that specific source
dataset remains a separate PI interpretation issue.

## Fixed parameters and original finite reconstruction

Let U=(1,8;0,1). The four A conjugators are
(1,0;0,1), (0,-1;1,0), (1,0;1,1), (1,0;2,1).
The four B conjugators are
(2,1;1,1), (1,0;3,1), (3,-1;1,0), (2,1;3,2).
Generate each integer matrix C U C^-1, then reduce modulo p5/7/11.
Every C has determinant1 and the source's primitive bounded first column.
All choices were frozen before ranks, logicals or distance observations;
no support/word/distance screening or parameter replacement is performed.

Enumerate all determinant-one2x2 matrices over Fp, retaining the full
SL(2,p), of order G=p(p^2-1). The central elements I and -I are distinct;
using PSL2 or a projective-line action would be incorrect. For each g define
right maps R_a:g->g*a and left maps L_b:g->b*g. All four generators in each
set are distinct, nonidentity and generate the complete group. Full finite
regular actions and exact prime generator orders are checked independently.

Put A[g,h]=1 when h=g*a for an A support element and B[g,h]=1 when h=b*g
for a B support element. The actual CSS matrices are Hx=[A B] and
Hz=[B^T A^T]. Inverse regular maps implement the transposes. Each matrix
has G rows and2G columns, row weight8, and column weight4. Even support
size gives XOR of all rows zero in each matrix, so k>=2 without searching
for a positive-dimension seed. Actual k follows from full independent ranks.

## Soundness and independent verification

Associativity gives R_a L_b(g)=L_b R_a(g) for every g,a,b. Hence A B=B A
including multiplicities when products coincide, and
Hx Hz^T=A B+B A=0 overGF2. No geometric/girth/expansion argument is used
as a quantum distance proof. The constructor uses ordinary integer matrix
conjugation and modular products. The independent checker imports neither.

For first column(m,q) of C, the checker uses the separate rank-one formula
C U C^-1=(1-8mq,8m^2;-8q^2,1+8mq). It checks the exact integer/reduced
supports. It enumerates all group elements and their faithful permutations
on nonzero vectors in Fp^2. Every generator product on each side is
reconstructed by composing those vector permutations rather than repeating
the constructor's matrix-product routine. All supports' exact orders and
generation of the full group are checked. Every16G commuting square and
its product multiplicities, all inverse maps and every actual binary
physical column of both retained matrices are verified.

Full GF2 commutation, actual ranks and k, both complete logical quotient
bases, kernel/stabilizer-exclusion conditions and nonsingular logical
pairing are checked independently. Actual existing logical-basis words
verify syndrome, stabilizer exclusion and logical detection; only the
lightest existing row is selected, without combination/support search.

Physical direct-sum checks use the FULL typed stabilizer row space in
F2^(2n): X rows(Hx,0), Z rows(0,Hz). Reduce that space, then link each
row's support after mapping Xq and Zq to the same physical qubit q. A true
product partition would keep every reduced row inside one coordinate block.
All three inputs have one physical component. Scalar-merging Hx and Hz
would lose Pauli type and can falsely split a valid connected code; the
initial failed diagnostic is retained and this regression has explicit tests.
No matrix or fixed parameter changed to pass it. No identity X/Z weight
map or general code-equivalence claim is assumed.

| p | n | k | rank Hx | rank Hz | Actual supplied-basis upper |
|---:|---:|---:|---:|---:|---:|
|5|240|4|118|118|52|
|7|672|20|326|326|26|
|11|2640|58|1291|1291|12|

Those are verified physical upper words, not minima. No published individual
exact d is asserted for these original specializations; absence of a source
value does not establish a globally unsolved problem. Short/poor results
are retained. The paper's decoder comparisons and classical short-cycle
arguments supply no verified lower bound or decoder guarantee for these
fixed choices. The strong certified-expander/good-code gap remains separate.

## Reproduction and acceptance gates

```
python3 scripts/codegen/quantum_margulis.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-187/raw/certificates
python3 scripts/codegen/validate_quantum_margulis.py --out optimization/experiments/GH-187/raw/construction.json
python3 tests/test_codegen_quantum_margulis.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```

Existing files/certificates are never overwritten. Fresh directories give
12matrix+3complete-certificate byte reproduction.15new units cover source
conjugators, accidental projective quotient, wrong identity/action/inverse
transpose/actual matrix columns, changed commuting check basis, typed-Pauli
false split versus true hidden direct sum, false upper and explicit case
selection. Prior34units retain their original workloads/default selection.
No same(n,k) peers found across main/pinned published library branches;
direct/swapped rowspace checks and full inventory still run.

Three-case serial default MaxSAT and CC Linux60sCPU/90swall/4GiB pinned
smokes are pending at the construction checkpoint. Retain raw/source/binary/
input identities and independently check actual words and result consistency.
Missing numeric fields stay INCOMPLETE, new one-engine lower/exact values
PLAUSIBLE until independent completion. Heavy work becomes an unexecuted
server package. No stem/tier/solver/default/QDistSAT/main/gh-pages changes.
