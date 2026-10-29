# Static three-dimensional color CSS inputs (GH-185)

Seven fixed cases: one published small anchor and six original finite
periodic specializations. These are static stabilizer CSS matrices, with
X on volumes and Z on faces. They are not gauge/subsystem, circuit-distance
or noise-biased Clifford-deformed inputs.

## Sources and redistribution boundary

H. Bombin and M. A. Martin-Delgado, *Exact Topological Quantum Order in D=3
and Beyond: Branyons and Brane-Net Condensates*,
[cond-mat/0607736v3](https://arxiv.org/abs/cond-mat/0607736v3),
Phys. Rev. B 75, 075103 (2007),
[DOI](https://doi.org/10.1103/PhysRevB.75.075103), Sec. II.B Eqs. (1)–(5),
Sec. III.B and Appendix B. This supplies the static colex construction,
projective-space example, inflation procedure and homological dimension.
M. Vasmer and D. E. Browne, *Three-dimensional surface codes: Transversal
gates and fault-tolerant architectures*,
[1801.04255v2](https://arxiv.org/abs/1801.04255v2),
Phys. Rev. A 100, 012312 (2019),
[DOI](https://doi.org/10.1103/PhysRevA.100.012312), Fig. 12 and accompanying
discussion, gives the cube [[8,3,2]] anchor.

Only published mathematics is used. Original implementation and generated
matrices are GPL-3.0-or-later. No author code, matrix file, paper prose or
image is redistributed; no external distance or topology solver is used.
The source arXiv nonexclusive distribution licenses are not interpreted as
permission to copy software or matrix datasets.

## Finite specification and soundness

For the anchor, vertices are binary triples. Four edge involutions add
100, 010, 001 and 111. This is the source projective-space colex. Three-color
components give four volume rows; two-color components give twelve square
face rows. Independent GF(2) row-space comparison identifies exactly the
same stabilizer as X on all eight cube vertices and Z on the six ordinary
cube faces. Actual ranks are 1 and 4, so k=3. The published exact distance 2
is an anchor to reproduce, not an assumption used to generate logicals.

For the periodic cases, start from the actual cubical cellulation of T3 with
opposite faces glued by translations of the three fixed periods. A cell is
identified by its start position and direction subset. Distinct parallel
edges and faces at period two retain distinct IDs even if vertex sets agree.
Take the order complex of this regular cell structure and its dual. A
maximal chain vertex < edge < face < cube gives one tetrahedron and hence
one physical qubit of the dual colex. An edge of color i replaces only the
rank-i element of the flag by its unique other incident choice. This is a
finite dual realization of the cited cell-inflation mathematics.

The colex volume associated with one original cell consists of flags
containing it; its color is that cell's dimension. A colex face is the flags
containing a comparable pair of original cells. The generator builds these
incidences directly. The independent validator reconstructs all three-color
and two-color graph components and checks exact agreement, including their
missing colors, rather than trusting matrix dimensions or incidence counts.

Every flag facet has exactly two incident tetrahedra, all four neighbor
involutions are distinct and fixed-point free, and the entire graph is
connected and bipartite. In each cubic three-color component, alternating
two-color cycles are simple polygons; every edge belongs to exactly two
faces and every vertex link is a triangle. The inherited bipartition orients
the surface; connectedness and Euler characteristic 2 then prove that each
volume boundary is a sphere. These checks exclude proper four-colored
graphs whose three-color components are tori. The finite coordinate gluing,
complete primal flags and these local checks supply the manifold identity;
Betti numbers alone would not establish homeomorphism.

An independent downward primal boundary implementation checks exact integer
boundary-squared-zero and GF(2) Betti numbers [1,3,3,1]. The checker also
builds all actual colex edge/face/volume boundaries, verifies both composed
boundaries vanish and computes their ranks and homology. The anchor instead
has GF(2) Betti numbers [1,1,1,1]. No external topology package is involved.

Each X-volume and Z-face share at least one edge color: a shared vertex is
paired with the other endpoint of that color's fixed-point-free involution,
which stays in both supports. Their intersection therefore has even size,
proving CSS commutation. Actual matrix multiplication verifies this again.
Complete logical quotient bases, both kernel conditions, stabilizer
exclusion, full pairing and k=n-rank(Hx)-rank(Hz) are checked independently.
The reduced stabilizer-space support is connected, excluding hidden physical
direct sums after mixing check rows. No identity X/Z metric map is assumed:
the volume and face spaces have different ranks.

| Periods | n | k | rank Hx | rank Hz | Actual supplied-basis upper |
|---|---:|---:|---:|---:|---:|
| anchor RP3 | 8 | 3 | 1 | 4 | 2 |
| 2,2,2 | 384 | 9 | 61 | 314 | 4 |
| 2,2,3 | 576 | 9 | 93 | 474 | 4 |
| 2,3,3 | 864 | 9 | 141 | 714 | 4 |
| 3,3,3 | 1296 | 9 | 213 | 1074 | 6 |
| 3,3,4 | 1728 | 9 | 285 | 1434 | 6 |
| 3,4,4 | 2304 | 9 | 381 | 1914 | 6 |

For original cube count V the actual colex counts are 48V vertices, 96V
edges, 56V faces and 8V volumes; ranks 8V-3 and 40V-6 give k=9. Volume
weights are 16/48 and face weights 4/6/8. These were computed from actual
finite incidences. They give constant-weight checks, not constant rate.

The last column is an independently verified existing logical-basis word,
not a minimum. No source individual exact distance is asserted for these
six original periodic specializations, and no globally unsolved research
problem is claimed from its absence. No weight-support or distance search
is used to select periods or words: choose the lightest existing supplied
basis row, check its syndrome/stabilizer exclusion/logical detection, and
retain it as an upper. The fixed cases remain even if later easily solved.

## Reproduction and validation

```
python3 scripts/codegen/color3d.py --all --out data/matrices/untiered --certificates optimization/experiments/GH-185/raw/certificates
python3 scripts/codegen/validate_color3d.py --out optimization/experiments/GH-185/raw/construction.json
python3 tests/test_codegen_color3d.py
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
```

The builder refuses existing matrices/certificates. Use fresh output paths
to reproduce all 28 matrix files and seven complete certificates byte for
byte. Fourteen new tests include topology, local incidence, wrong matrices,
wrong X/Z assignment, false upper words and hidden direct-sum mutants;
the prior 34 tests retain their original explicitly selected workloads.
All published pending-library branches and main have no same-(n,k) peers
for these seven cases at the retained snapshot. Direct/swapped row-space
checks and full inventories still run.

Linux gates select precisely seven cases with both internal engines,
serial default seed, 60 s CPU / 90 s wall / 4 GiB / pinned allocated runner
CPU. Source/binary/input identities, raw results and actual words are
retained and independently audited. No source/basis value fills missing raw
fields. A new one-engine exact distance or raised lower bound is PLAUSIBLE
until independently checked. See GH-185/REPORT.md for terminal evidence;
Linux is pending at this construction checkpoint. Long work, if needed,
becomes an unexecuted dedicated-server package. Unknown stems, tiers and
main remain unchanged.
