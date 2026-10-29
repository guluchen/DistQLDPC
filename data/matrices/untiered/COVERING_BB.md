# Bivariate bicycle codes with explicit covering maps (GH-176)

## Source, claims and attribution

B. C. B. Symons, A. Rajput and D. E. Browne,
*Sequences of Bivariate Bicycle Codes from Covering Graphs*,
[arXiv:2511.13560v3](https://arxiv.org/html/2511.13560v3),
Tables7/8 and Theorems3.1/3.3. Source licensed
[CC BY4.0](https://creativecommons.org/licenses/by/4.0/).
Changes: original binary-matrix reconstruction, new physical ordering,
independently computed logical bases, graph/chain verification and benchmark
packaging. No third-party program, matrix files, decoder, paper prose or
images copied. Our original scripts/matrices are GPL-3.0-or-later.
This is a BB cover-structure/provenance specialization, not a disjoint family.

| n | k | lattice(l,m) | h | Base | Source claim |
|---:|---:|---|---:|---:|---|
|64|14|8,4|1|64|exact8, Table8|
|128|14|8,8|2|64|exact12, Table8|
|192|14|8,12|3|64|upper estimate16, Table8|
|216|14|18,6|3|72|upper estimate20, Table7|
|256|14|16,8|4|64|upper estimate22, Table8|
|288|14|12,12|4|72|upper estimate24, Table7|

The exact claims are published ground-truth anchors; larger labels are
heuristic upper estimates and remain such until an actual word is checked.
All eight monomial exponent pairs, source table and cover base are frozen
in scripts/codegen/covering_bb_cases.json. No distance-based seed selection,
search or resampling occurs. Use the published size range; no invented
large-distance scaling. Other large sizes/families remain in the coverage
ledger, with PI priority on unknown exact distances after this batch.
The base72 is constructed internally to verify covers but not added as a
library file; existing/pending base or exact144 BB cases are not duplicated.

## Original construction and independent verification

Coordinates are (x,y) in Z/l times Z/m, index x*m+y; left qubits precede
right qubits. A monomial x^a y^b is the permutation with row(x,y) at
column(x+a,y+b). Hx=[A B], Hz=[B^T A^T]. Commutativity of translations
makes A B+B A=0 in GF(2), proving CSS commutation. Actual matrix elimination
checks n=2lm, k=n-rank(Hx)-rank(Hz)=14, both logical quotient bases and
full-rank Gx Gz^T pairing. Each check has weight8, each physical column
has degree4 per half; both Tanner graphs are connected.

An independent implementation constructs inverse incidences from physical
columns: left qubit(x,y) is incident on Hx rows(x-a,y-b) for A and Hz
rows(x+a,y+b) for B; right swaps A/B. It imports no constructor or logical
builder. Actual row-set checks confirm both translations and the involutive
XZ dual map left(x,y)<->right(-x,-y); no distance result assumes this map
without verifying both row spaces. Logicals come from the unchanged
compute_logicals.py --method bitset and are independently verified.

## Soundness of the actual cover checks

Let base sides be (b_l,b_m), cover sides integer multiples (u*b_l,t*b_m),
h=u*t. Reduce each physical coordinate modulo the base sides, retaining
its left/right class; reduce both X and Z check coordinates likewise.
The verifier checks every fiber has cardinality h. Source monomial residues
match the base multiset, but congruence alone is not the acceptance test.

For EVERY actual cover check, project its full physical neighbor list and
require a bijection with its base check's actual neighbors. Separately, for
EVERY physical qubit and each check type, require a bijection of its actual
check-neighbor list to the base qubit's check-neighbor list. Thus all vertex
stars map bijectively, proving a graph covering on the full X/check/left/
right/Z incidence structure. Connectedness excludes disconnected copies.
Repeated/missing projected edges and same-fiber local rewiring are rejected.
The primary construction has8 neighbors per check and4 per qubit/half, so
these tests inspect6lm actual vertex stars (2lm checks plus4lm qubit-half
stars), not a sample.

With boundaries d1=Hx,d2=Hz^T, projection p maps each cell basis vector to
its base cell. Transfer T sends each base cell to the sum of its full fiber.
Neighborhood bijections imply p0*d1_cover=d1_base*p1 and
p1*d2_cover=d2_base*p2; the analogous identities hold for T in the opposite
direction. The script checks binary columns AND rows explicitly for both
halves, independently checking projected and transferred incidence vectors.
Finally p*T=(h mod2)I in all three cell degrees. These are finite matrix
identities. This package does not assert distance preservation for even
covers, apply the paper's conjecture as a theorem, or silently use h times
a base distance as a certified distance of these codes.

## Reproduce and inspect

```
python3 scripts/codegen/covering_bb.py --all --out /tmp/covering-bb-rebuilt
python3 scripts/codegen/validate_covering_bb.py --output /tmp/covering-bb-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/covering-bb-inventory.json
python3 tests/test_codegen_covering_bb.py
```

Compare all24 files byte-identically. All same(n,k) entries in the tiered
and untiered directories are checked for equal row spaces, including XZ
swap. Current pending library branches are also inspected; no same(n,k)
peer was found for the six added inputs. Distinct n prevents equivalence
within the batch. No source file is redistributed under an inferred license.

Mac work is generation, algebra and tiny units only. Linux performs selected
serial60s per case/engine, one allocated pinned core,4GiB,90s wall backstop,
unchanged solver/default seed. Every actual word is GF(2)-checked against
syndrome, stabilizer quotient and logical detectors. Two-engine exact proofs
can cross-check a new result; one-engine exact/lower improvements remain
PLAUSIBLE. Missing numeric fields stay empty and incomplete. Literature
estimates never fill absent CLI bounds. See GH-176/REPORT.md and retained raw
logs. Any contradiction to an exact source anchor is a scientific escalation.
