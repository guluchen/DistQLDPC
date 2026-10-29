# Interval-valued QC generalized hypergraph product references (GH-192)

Two fixed PK2021 GHP references add practical unconfirmed-exact-distance
instances under the existing LP prefix. This is the QC GHP specialization
of lifted products, not ordinary HGP rescaling or a disjoint new family.
No parameter screening/scaling or replacement after observing results.

Source: Pavel Panteleev and Gleb Kalachev, *Degenerate Quantum LDPC Codes
With Good Finite Length Performance*, [1904.02703v3](https://arxiv.org/abs/1904.02703v3),
Quantum5,585(2021), [DOI10.22331/q-2021-11-22-585](https://doi.org/10.22331/q-2021-11-22-585),
Sec4.2/AppendixB sectionB itemsB1/B3/Table1. Latest version checked2026-10-30.
Publisher PDFp20 was rendered and visually checked: zero blocks, constant1,
monomial exponents and intervals agree with extracted text. Source CC BY4.0;
original mathematics-only scripts/generated matrices GPL3+, NOTICE credit.
No author implementation/matrix files/prose/images copied, no external
distance program run. Later primary references still use B1 upper24;
source review is not an exhaustive global-open or novelty certificate.

| item | n | k | l | square base size | scalar b support | published interval |
|---|---:|---:|---:|---:|---|---|
|B1|882|24|63|7|0,1,6|18..24|
|B3|1270|28|127|5|0,1,7|16..46|

B1 A[i,i]=x27, A[i,(i-1) mod7]=x54, A[i,(i-2) mod7]=1.
B3 A monomial exponents below; null is a zero block, integer0 constant1:
```
[[0,null,51,52,null],
 [null,0,null,111,20],
 [0,null,98,null,122],
 [0,80,null,119,null],
 [null,0,5,null,106]]
```
B=b(x)I. Hx=[A B], Hz=[B^T A^T]. Source circulants use coefficients in the
first column: a block x^e has entry(r,h)=1 iff r-h=e mod l. Physical columns
are two halves, base index then cyclic coordinate. Original constructor
translates rows; independent validator enumerates incident check roots
from each physical column, and separately instantiates P^e tensor |i><j|
in layer-major coordinates before an explicit row/column pullback. Scalar
B commutes with all circulant A blocks, giving AB+BA=0 over GF2; full actual
commutation is checked, not merely inferred from the source assertion.

Binary ranks429/621 in both halves agree with k24/28. Full computed Gx/Gz
quotient bases, kernel conditions and nonsingular pairing pass. Actual typed
physical stabilizer row spaces have no product partition; cyclic lift
translation is a checked physical automorphism. No arbitrary A-to-A^T
permutation, X/Z weight map or one-half distance equivalence is presumed.
No same(n,k) peer across31pinned main/library refs; direct/swapped rowspace
checks also run. Prior24manifest rows/300matrix files preserved, branch
26untiered/77total. Initial basis X/Z uppers32/24 and64/256 are actual GF2
words; B1 already materializes source upper24, B3 source46 still pending.
Published lower18/16 remains a source claim, not our certified lower bound.

Reproduce in a fresh directory (overwrite refused):
```
python3 scripts/codegen/reference_ghp.py --all --out /absolute/new/matrices
python3 scripts/codegen/validate_reference_ghp.py --out /absolute/new/construction.json
python3 tests/test_codegen_reference_ghp.py
python3 scripts/codegen/validate_css.py --output /absolute/new/validation.json
```
14new units include30tiny randomized independent coordinate/commutation
checks, source zero/constant/transpose/commuting-wrong-matrix/logical/entry/
shape/support mutants,8matrix byte reproduction and overwrite/CLI/audit
raw-number/actual-word guards. Mac algebra/construction/tiny tests only.
Linux40927713672/job123637551888 passes all48units, full construction/
inventory comparisons,8matrix byte regeneration and four serial60sCPU/
90swall/4GiB/defaultseed/pinned allocated CPU attempts. MaxSAT raw[18,24]/
[18,48], CC exact24/[24,64]. Actual verified upper words24/48. Numeric gates
PASS; strongest CC exact/lower24 PLAUSIBLE pending independent proof.
B1 source24 actual-word PASS, B3 source46 INCOMPLETE: the found48 word is
weaker, not a contradiction. Do not replace raw CC64 with48 or verified48
with source46. Full366565-character job log/14engine files/audit retained;
local actual-word replay byte-identical. Three default proof jobs and one
explicit supplemental B3 -ub-pre=3600 actual source-upper-word job are
frozen unexecuted in GH192/runner. Preserve raw missing fields as INCOMPLETE; no source-filled bounds.
New exact/lower results PLAUSIBLE until independent proof plus actual GF2
minimum words. Heavy unresolved work becomes frozen unexecuted yfclab2
packages requiring explicit PI allocation. No solver/default/tier/name/
main/QDistSAT/PR changes.
