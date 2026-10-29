# Next-source research while GH191 Linux validation runs

PI priority: useful individual exact-distance-unconfirmed targets; no global
open claim from an old interval. No new selection/input/issue in these notes.
Current GH191 fixed A1/A5 are retained regardless of eventual easy results.

## Next independent construction target: PK2021 GHP interval references

Panteleev–Kalachev [1904.02703v3](https://arxiv.org/pdf/1904.02703v3),
AppendixB sectionB itemsB1/B3, PDFp20 (zero-based19), Table1.
B1: [[882,24,18<=d<=24]], l63, A is7x7 circulant-block matrix:
A[i,i]=x27, A[i,(i-1) mod7]=x54, A[i,(i-2) mod7]=1.
B=(1+x+x6)I7. B3: [[1270,28,16<=d<=46]], l127,
A polynomial exponents (null is a zero block):
[[0,null,51,52,null], [null,0,null,111,20],
 [0,null,98,null,122], [0,80,null,119,null],
 [null,0,5,null,106]], B=(1+x+x7)I5.
Hx=[A B], Hz=[B^T A^T]; preserve first-column circulant convention.
These are concrete QC GHP/LP specializations, not generic HGP resizings.
Original scripts should reconstruct actual columns through two distinct
coordinate orders; full GF2/logicals, typed physical space and actual-word
source-upper gates remain required. Source mathematics CC BY4.0; no author
implementation or matrix file needed. Displayed matrix layout should be
visually rechecked before freezing selection; current PDF screenshot tool
returned cache miss, not contrary scientific evidence. No guessed changes.

## Additional interval-valued GB lead, lower priority than GHP coverage

Olai Å. Mostad, Eirik Rosnes and Hsuan-Yin Lin, *Asymptotically Good
Generalized Quantum Tanner Codes*, IEEE JSAIT6,367–382(2025),
[DOI10.1109/JSAIT.2025.3594310](https://doi.org/10.1109/JSAIT.2025.3594310).
Primary author-hosted accepted manuscript:
https://hsuanyin-lin.com/docs/papers/OAMostad-ERosnes-HYLin_25JSAIT.pdf
TableII reports GB [[688,30,d>=19]], l344,
a=[0,17,77,97,125,145,146,265],
b=[0,4,116,120,196,207,214,282]. SecIV describes exhaustive low-weight
lists then stabilizer filtering. Published lower is not our own proof.
No exact/upper value established by this source check. Paper file is not
assumed openly licensed; rebuild mathematics only, no copied files/prose.
Separate later-source/version/claim/coordinate checks before selection.

Related Mostad–Lin–Rosnes–Lee–Lai
[2505.06157v1](https://arxiv.org/abs/2505.06157), *Advancing Finite-Length
Quantum Error Correction Using Generalized Bicycle Codes*, has onlyv1
listed, CC BY-NC-ND4.0. No code/matrix/prose redistributed. It is an
unselected mathematical-source lead; no inherited license or automatic
finite-distance claim. Primary tables/proof status still need review.

Preliminary same(n,k) search across GH191's30 pinned refs found no
882k24/1270k28/688k30 peer; recheck coordination and current refs at selection.
Earlier APM source interpretation hold and stronger certified-expander/
cosheaf finite-hypothesis gaps remain open, not hidden by these additions.
