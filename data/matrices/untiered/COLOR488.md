# Static triangular4.8.8 color codes

Original mathematical reconstruction from Noah Shutty,
*Denser Planar Color Codes*, [arXiv2609.21376v3](https://arxiv.org/html/2609.21376v3),
AppendixD. The latest v3 coordinate/face rules agree with the v1 research notes.
Background: Ashley M. Stephens, *Efficient fault-tolerant decoding of topological
color codes*, [arXiv1402.3037v1](https://arxiv.org/abs/1402.3037v1).
The4.8.8 lattice is a structural specialization of the existing COLOR family.

No external source code, circuits, matrices or source bundle were imported.
The cited paper's perpetual arXiv license is not a license to redistribute its
files. Following the PI's mathematics-reconstruction rule, all scripts and
new generated matrices are original GPL-3.0-or-later work with attribution.

| m | n (data only) | k | Published static d |
|---:|---:|---:|---:|
| 2 | 31 | 1 | 7 |
| 3 | 71 | 1 | 11 |
| 5 | 199 | 1 | 19 |
| 9 | 647 | 1 | 35 |
| 14 | 1567 | 1 | 55 |
| 19 | 2887 | 1 | 75 |

Only the published d=4m-1 coordinate subfamily is generated. Here
n=8m²-1=(d²+2d-1)/2. Ancillas, noisy circuits, decoder performance and
circuit-distance claims are outside these static CSS matrices. The m1
seven-qubit case is equivalent to the existing Steane input after a proved
column permutation; it appears only in tiny unit tests, not as a new code.

## Complete coordinate construction

Let R=-4m-1, j=0..4m-2 and L_j=R-min(2j+3,8m-2j-3)+1.
Sites are (x,6+2j), L_j<=x<=R, indexed by increasing y, then x.
Use four local face shapes:
Q={0,1}×{0,2}, O={0,1,2,3}×{0,2},
U={(0,2),(1,2),(2,0),(2,2)},
V={(0,0),(1,0),(2,0),(2,2)}.
Retain Q translated to data sites with x-y=3 mod4 and O at data sites with
x even and x=y mod4, only when all translated sites exist.
Additionally retain Q+(R-1,6+4h), h=0..2m-2;
U+(-4m-5-4h,6+4h), h=0..m-2; and
V+(-8m+1+4h,4m+4+4h), h=0..m-1.
All specified additional boundary faces must be wholly present.
Sort faces by minimum y, minimum x, size and sorted coordinate list.
Each binary face vector supplies both Hx and Hz.

The original constructor uses translations in (x,y). The independent
validator uses u=R-x and v=(y-6)/2: sites satisfy u>=0,0<=v<=4m-2,
u<=2v+2 and u+2v<=8m-4. It enumerates adjacent-rail rectangles and boundary
wedges in these reflected coordinates, then assembles rows from physical
column incidence. It does not import the constructor or logical builder.

## Soundness and validation

All faces have weight4 or8. Any distinct intersecting pair shares exactly2
sites, checked directly; hence Hx Hz^T=0. Finite-case binary elimination
confirms rank(Hx)=rank(Hz)=(n-1)/2, giving k=1. Both logical quotient bases
and their full pairing are checked. The face-intersection graph is connected
and admits three colors, independently found without constructor color labels.
Every site has degree1,2 or3.

The rightmost sites x=R form a boundary word of weight4m-1. Its intersection
with every face is even. The all-data vector also has zero syndrome because
all face weights are even. Their inner product is odd, so neither can be a
stabilizer: a stabilizer must be orthogonal to every zero-syndrome word.
This supplies GF(2)-verified X and Z upper witnesses at the published d for
every selected matrix. It does not supply a lower-bound proof. Published
exact claims remain distinct from internal search results and numeric fields.

```sh
python3 scripts/codegen/color488.py --all
python3 scripts/codegen/validate_color488.py --output /tmp/color488-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
python3 tests/test_codegen_color488.py
python3 scripts/codegen/color488.py --all --out /tmp/color488-fresh
```

Generation refuses to overwrite any matrix and computes Gx/Gz with the existing
bitset logical builder. Gx is ker(Hx)/row(Hz), representing Z words in this
repository; the matrices are self-dual here. No same-(n,k) peer exists for the
six selected cases across current tiers/untiered and inspected pending library
branches, so none can be a column-permutation duplicate of an existing input.
Units include tiny exhaustive distance3 after random relabeling, explicit
Steane equivalence, missing-boundary and changed-incidence mutants, and
stabilizer-as-logical rejection. All24 files must regenerate byte for byte.

Linux short-run evidence and any unresolved server jobs are recorded under
GH-172. Unknown stems and untiered placement remain until PI decisions.
