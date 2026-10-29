# Periodic square toric CSS references (GH-168)

Proposed prefix TOR follows Kitaev's TOR notation. These are six finite
instances of A. Yu. Kitaev, *Fault-tolerant quantum computation by anyons*,
[quant-ph/9707021v1](https://arxiv.org/abs/quant-ph/9707021v1), Sec.1 Eq.(1),
[journal DOI](https://doi.org/10.1016/S0003-4916%2802%2900018-0).
The source defines the construction for every square side length, not a table
of these six examples. Lengths3,8,13,18,27,38 give n18,128,338,648,1458,2888,
k2 and published exact distance L. Unknown stems remain until PI tiering.

This adds closed genus-one topology alongside the planar k1 repetition-HGP
ladder. Toric codes are also a homological/product specialization; TOR denotes
provenance, not a claim of a disjoint new mathematical family. No disconnected
copies, gauge changes or removed logical sectors. These lengths form a small
anchor and a roughly increasing size ladder; no same-(n,k) peers were found
in the current 51 tiered/24 main untiered inputs or pending GH-160/164/165/166/167.
Exact branch identities for the latter review are retained in the raw record.

## Incidence and soundness

Coordinates x,y are in Z_L. Columns first enumerate horizontal edges
(x,y)->(x+1,y), then vertical edges (x,y)->(x,y+1), with index yL+x in each
block. Hx contains all vertex stars and Hz all face boundaries. Each row has
four distinct edges for L>=3; each edge meets two stars and two faces. A star
and face share zero or two edges, hence Hx Hz^T=0. The only star relation and
face relation are their respective total sums: primal and dual graphs are
connected, so rank(Hx)=rank(Hz)=L^2-1 and k=2L^2-2(L^2-1)=2.

Every edge set of zero syndrome is Eulerian on the respective primal/dual
graph and decomposes into cycles. A contractible cycle is a sum of faces;
the quotient is the two-dimensional homology of the square torus. A
nontrivial cycle has odd winding in at least one coordinate. Lifting to the
infinite square grid, that coordinate has displacement an odd multiple of L,
so it needs at least L unit edges. Straight primal/dual windings attain L,
giving dX=dZ=L. Independent GF(2) checks verify all four straight words,
their nontriviality, full logical detection and identity intersection matrix.

The independent checker imports neither generator nor logical builder. It
reconstructs matrix columns from edge endpoints and adjacent faces; checks
each face is a simple square, both incidence graphs connected, Euler
characteristic0, and every vertex link a single four-cycle, in both dual
orientations. It checks ranks, both logical quotients and full pairing.
Original logical bases come from compute_logicals.py --method bitset.

## Independent exact graph oracle

For each actual logical detector and every vertex root, BFS the signed double
cover of the actual parity-incidence graph: edge q changes the sheet by its
detector bit. A path root0->root1 is an odd-detected closed walk. Cancelling
repeated edges modulo2 gives a zero-syndrome nontrivial word of no larger
weight. Conversely every nontrivial Eulerian word has a simple-cycle component
detected by at least one of the complete detector basis rows, so the minimum
over all roots and detectors is exactly the quotient distance. Primal uses
Hx with detectors Gz; dual uses Hz with detectors Gx, following repository
matrix conventions. This is an original independent algorithm, no external
distance solver or downloaded certificate program.

The incumbent is always an actual odd-detected word. Pruning BFS depths
whose next edge cannot improve its weight cannot remove a shorter witness.
Returned supports are checked again for syndrome, stabilizer exclusion and
logical detection. This does not alter DistQLDPC bounds or substitute a
graph result for missing CLI output. Full six-case distance mode runs as a
bounded Linux check; Mac runs only generation/algebra and tiny unit examples.

Tests compare the graph oracle with exhaustive tiny binary supports in both
CSS quotients and randomized small graphs. They catch a parity row used as
a logical detector, seam corruption, dependent logical bases, and erroneous
walk length counting with repeated edges. Random qubit/vertex relabeling
preserves the oracle result and topology checks. Existing duplicate checks
include both X/Z orientations; suspected permutation equivalences are not
silently added.

## Reproduction and license

```sh
python3 scripts/codegen/toric.py --all --out /tmp/toric-rebuilt
python3 tests/test_codegen_toric.py
python3 scripts/codegen/validate_toric.py --output /tmp/toric-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/toric-validation.json
# bounded Linux independent distance verification:
python3 scripts/codegen/validate_toric.py --distance --output /tmp/toric-distance.json
```

All24 matrix files must reproduce byte-for-byte. Source paper uses arXiv's
perpetual nonexclusive license. No paper text, code or matrix files copied
or redistributed. Original mathematical implementation and generated inputs
are GPL-3.0-or-later, with author/title/source attribution in NOTICE. No CC BY
or MIT license is imputed to this paper.

Six serial 60s checks per engine use one allocated Linux core,4GiB cap,90s
wall backstop and stdin /dev/null. Actual results and identities are recorded
in GH-168/REPORT.md; missing numeric bounds remain incomplete gates even if
the graph oracle proves a known distance. Heavy CLI completion is packaged
for a PI-allocated server core, never longer CI or Mac solver runs. No stem
rename, tier assignment, QDistSAT mirror or main integration occurs here.
