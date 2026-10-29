# Periodic four-dimensional toric CSS inputs (GH-175)

## Construction and provenance

Original mathematical reconstruction of N. P. Breuckmann, K. Duivenvoorden,
D. Michels and B. M. Terhal, *Local Decoders for the 2D and 4D Toric Code*,
[arXiv:1609.00510v2](https://arxiv.org/html/1609.00510v2), Sec.2/Fig.1,
Quantum Information & Computation17(3-4),181–208(2017).
The source supplies the cubic family [[6L^4,6,L^2]]. The three unequal-side
cases below are original rectangular extensions, not individually published
exact parameters. No third-party constructor, matrix files, decoder, paper
text or images are redistributed. The arXiv perpetual/nonexclusive paper
license is not a software license; the journal retains its copyright.
Our original scripts and matrices are GPL-3.0-or-later.

| Sides L0,L1,L2,L3 | n | k | Published claim | Independently certified dX=dZ |
|---|---:|---:|---|---:|
|2,2,2,2|96|6|cubic formula exact4|4|
|2,3,3,3|324|6|individual rectangular d not published; membrane upper6|6|
|3,3,3,3|486|6|cubic formula exact9|9|
|3,4,4,4|1152|6|individual rectangular d not published; membrane upper12|12|
|4,4,4,4|1536|6|cubic formula exact16|16|
|4,5,5,5|3000|6|individual rectangular d not published; membrane upper20|20|

TOR is the existing periodic-toric prefix, here a higher-dimensional
specialization rather than an additional disjoint family. The connected
four-dimensional cell complex differs from the k=2 two-dimensional toric
inputs on the GH-168 branch. All new stems retain `_unknown` pending PI
naming/tiering decisions. These fixed-k codes do not claim finite rate.

## Matrix convention

Coordinates x are in the product of Z/L_a, every L_a>=2. Last coordinate
varies fastest; face orientation pairs and cube triples are lexicographic.
Physical qubits are faces (ij,x), i<j, giving n=6V, V=product L_a.
Hx has one row for each edge (i,x), with incident faces (ij,x) and
(ij,x-e_j) for each j!=i. Hz has one row for each cube (ijk,x), its six
faces (ij,x),(ij,x+e_k), and the other two analogous pairs. Binary addition
is XOR. Each half has4V rows, row weight6 and column degree4.
Every edge/cube intersection has even cardinality, so Hx Hz^T=0.
Actual finite matrix elimination verifies rank(Hx)=rank(Hz)=3V-3 and k=6;
both supplied logical bases are complete quotient bases with full pairing.
Both check Tanner graphs are connected; no disconnected copies are used.

The independent incidence verifier constructs columns: a face (ij,x) meets
edges (i,x),(i,x+e_j),(j,x),(j,x+e_i), and cubes (ijk,x),(ijk,x-e_k).
This differs from the generator's row construction. Axis translations are
verified on actual row sets. The explicit dual permutation maps (ij,x) to
(kl,x-e_k-e_l), where kl is the complementary pair; it interchanges the two
row sets and preserves weight. Its square translates every coordinate by
-1: it is not generally an involution. Distance equality below also has
separate certificates for both halves and does not assume an involution.

## Soundness of the finite lower-bound certificates

Let P be the actual parity matrix of a half, S its stabilizer matrix, and
L a validated basis of ker(P)/row(S) of dimension k. A detector family
consists of nonempty physical supports f_1,...,f_m, pairwise disjoint, with
f_1 orthogonal to S and every f_j+f_1 in row(P). Suppose the k family
references have full-rank pairing against L. Then every nontrivial logical
w has odd intersection with the reference of at least one family: pairing
is unchanged by adding S, and the reference pairings separate all nonzero
quotient classes. Since P w=0, every member of that family has the same
odd intersection. Disjointness forces weight(w)>=m. Thus
weight(w)>=min_family m for every nontrivial logical, with no restriction
to connected words or a chosen logical class. These are properties of the
actual finite matrices, not an asserted topological formula.

For Z words (P=Hx,S=Hz,L=Gx), detector family ij fixes coordinates i,j
and varies the complementary two coordinates in the ij face block. There
are L_i L_j disjoint fibers. For X words (P=Hz,S=Hx,L=Gz), the family
fixes complementary coordinates and varies i,j, giving L_k L_l disjoint
planes. The finite receipt includes every support. Actual row-space
membership verifies all homology relations; full logical pairing verifies
all six classes. Minimum family cardinality is min_{i<j} L_i L_j in
both halves, proving that lower bound independently for X and Z.

For upper bounds take a minimum-area coordinate plane as a Z word and a
minimum-area complementary fiber as an X word. Each has zero actual
syndrome, is outside the actual stabilizer row space, and has weight
min_{i<j} L_i L_j. Canonical planes/fibers pair as the6x6 identity.
Independent GF(2) word verification therefore completes dX=dZ=min L_i L_j.
No code or assertion from an external distance solver is used.

The primary implementation uses high-pivot elimination, bit intersections
and the independent column reconstruction. A second standalone checker
imports none of the generator, logical builder, primary verifier, shared
CSS algebra or solvers. It parses actual files, uses low-pivot elimination,
column syndromes and Python sets for support disjointness, and rechecks
quotient completeness, homology, pairing and both upper words. Its receipt
SHA and all four matrix SHA256 values bind the exact result to finite inputs.
Tiny exhaustive-support cases and random column permutations exercise the
lemma; mutants remove homology, disjointness, completeness, incidence and
logical validity. Random tiny span enumeration checks the second algebra.

## Reproduction and evidence

```
python3 scripts/codegen/toric4d.py --all --out /tmp/toric4d-rebuilt
python3 scripts/codegen/validate_toric4d.py --output /tmp/toric4d-construction.json
python3 scripts/codegen/verify_toric4d_certificate.py --out /tmp/toric4d-independent.json
python3 tests/test_codegen_toric4d.py
```

The generator calls the unchanged compute_logicals.py --method bitset.
Compare all24 matrix files byte for byte. Full inventory validation checks
same-(n,k) row spaces including X/Z swap, and the report records separate
work-branch peer inspection. n,k distinguish these inputs from all existing
and pending peers; no suspected permutation equivalence was found.

Mac work is generation, algebra and tiny proof units only. Linux Actions
runs one serial60s per case/engine with one allocated pinned core,4GiB and
90s wall backstop; no large scientific search or timing claim. CLI numeric
fields remain raw even though the independent certificate is complete.
See GH-175/REPORT.md, raw certificates, logs and the smoke audit. A missing
CLI numeric field is an incomplete smoke gate, never filled by this proof.
No solver, encoding, pruning, bound, default or tier semantics change.
