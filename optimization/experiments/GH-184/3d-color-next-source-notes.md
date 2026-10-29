# Next-source investigation only: periodic3D stabilizer color/colex codes

Primary source: H. Bombin and M.A. Martin-Delgado, Exact Topological Quantum
Order in D=3 and Beyond: Branyons and Brane-Net Condensates, PRB75,075103
(2007), arXiv cond-mat/0607736v3. Source SecII.B Eqs1–5 specifies qubits
on colex vertices, X on3-cells, Z on faces, k=3h1; source discussion of T3
gives h1=3. AppendixB constructs colexes from arbitrary closed complexes by
cell inflation, with3-cells colored by original cell dimension. Source paper
arXiv assumed/nonexclusive distribution is not a source-code/data license.
Original mathematical reconstruction only; no author code/matrices/prose/
images or external distance solver used. This is a lead, not new matrices.

A concrete independent representation is the dual of the cell-poset order
complex of a periodic cubic T3 cellulation. Each maximal flag v<e<f<c is
one tetrahedron/qubit; original dimensions0/1/2/3 give four vertex colors.
Neighbors are the unique other flag differing in exactly one rank: alternate
edge endpoint, alternate edge in the same vertex/face, alternate face in
the same edge/cube, or alternate cube through the same face. The resulting
colored graph should be4-valent. Fixing one original cell yields a colex
3-cell (X row); fixing a comparable pair of original cells yields a colex
face (Z row). This is an original finite realization of the source inflation
construction, not an asserted source-published matrix or exact distance.

For rectangular periods>=2 and original cube count V, expected N=48V,
8V colex3-cells,56V colexfaces,96V colexedges, and k9 on T3. Expected
X check weights16/48 and Z check weights4/6/8; all are constants. Candidate
ladder (2,2,2),(2,2,3),(2,3,3),(3,3,3),(3,3,4),(3,4,4) would give
N384/576/864/1296/1728/2304 and k9. These are design expectations, not
validated finite ranks or bounds. No claim of actual distance/asymptotic
goodness, and no selected source exact-distance anchor has yet been located.

Critical finite-topology checks before acceptance: use explicit original
cell IDs (position and direction set), not just vertex subsets, because
period2 gives distinct parallel/wrapping cells. Verify every maximal flag,
missing-rank neighbor involution, proper four colors, all pair-color cycles,
all three-color components with spherical boundary (circular links/Euler2
and complete edge/face incidence), global T3 topology/Betti numbers by an
independent finite cellular chain implementation, and actual CSS ranks/full
logical quotient bases/pairing. Expected rankX=8V-3, rankZ=40V-6 must be
computed, not presumed. Independently reconstruct actual matrix columns
from flag incidence versus colored-graph residues. GF2-verify supplied-basis
upper words only; no quantum distance/support search on Mac.

Unequal X/Z spaces generally preclude an assumed XZ metric duality; do not
transfer the identity map used for2D closed color codes. No gauge/subsystem
operators, Clifford-deformed non-CSS construction, effective biased-noise or
circuit distance is substituted for static CSS distance. A2023 background
primary paper, DOI10.1103/PRXQuantum.4.030338, was located; only its original
CSS definition could be relevant, never its noise-dependent deformations.

No issue/branch/parameters frozen or matrices implemented for this next
family yet. Finish retaining GH184 results, refresh issues/remotes, record
three proposals and claim the next topic before implementation. Poor finite
distances/upper words must not trigger silent period or geometry reselection.

## PI selection priority (2026-10-29)

After the current collection batch, prioritize representative finite codes
whose exact distance is still unknown: published lower/upper intervals,
heuristic-only distance estimates, and reproducible construction instances
without a published individual exact distance. Check the actual selected
instance and source version before labeling it open. Distinguish source
claims, independently verified physical upper words, raw solver bounds and
independently completed exact proofs. Unknown publication status alone is
not evidence of an unsolved research problem. Retain a small number of known
exact-distance anchors for correctness and genuine family/size gaps; avoid
adding mostly easy known-distance variants merely to increase inventory.
This changes subsequent selection priority, not any frozen current inputs,
timeouts, scientific claims or completion gates.
