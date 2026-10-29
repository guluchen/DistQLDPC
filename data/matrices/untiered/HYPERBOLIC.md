# Closed hyperbolic surface codes (GH-165)

Proposed prefix HYP. Four explicit {5,4} cases are reconstructed from
Breuckmann and Terhal, [arXiv:1506.04029v2](https://arxiv.org/abs/1506.04029v2),
[DOI:10.1109/TIT.2016.2555700](https://doi.org/10.1109/TIT.2016.2555700),
Sections III-A/B, IV-A and Table I. Published (n,k,d) are (60,8,4),
(160,18,6), (360,38,8), (1800,182,10). These are connected closed surfaces,
not repeated copies or planar surface-code specializations. Source claims
remain distinct from independently observed distances. Stems stay unknown.

## Original reproducible construction

Let r=rho, R=rho^-1, s=sigma, S=sigma^-1. The orientation-preserving
triangle group has r^5=s^4=(rs)^2=1. `hyperbolic_cases.json` records the
expanded compactifying words and source table row. For these four cases,
quotienting by their normal closure with reflection conjugates gives the same
quotient as the oriented normal closure. Conjugation by the reflection c
inverts both r and s, because rho=bc, sigma=ca and a,b,c are involutions.

The original bounded enumerator allocates formal right-generator paths,
closes defining relator loops, and merges only rows forced equal by those
relations or their inverse transitions. At completion every inverse and every
relator is checked at every state. Canonical BFS labels remove intermediate
allocation-order dependence. Full quotient orders are 120,320,720,3600.
Faces, vertices and edges are right-rotation orbits of r, s, rs. Coset
intersection gives face-edge and vertex-edge incidence. Set Hx=vertex-edge
and Hz=face-edge; every face meets a vertex on zero or two boundary edges,
so Hx Hz^T=0. The full CSS homology is retained, no gauge selection.

Original code and generated matrices are GPL-3.0-or-later. No external source
code, matrix files, paper text or distance solver copied or executed. Generator
uses only Python standard library and the repository's logical builder.

```
python3 scripts/codegen/hyperbolic_surface.py --all --out /tmp/hyp-fresh --certificates /tmp/hyp-quotients
python3 tests/test_codegen_hyperbolic.py
python3 scripts/codegen/validate_css.py --output /tmp/hyp-validation.json
python3 scripts/codegen/validate_hyperbolic.py --output /tmp/hyp-topology.json
```

Gx/Gz use `scripts/compute_logicals.py --method bitset`. All 16 matrix files
and four complete quotient certificates must reproduce byte for byte.
The independent topology validator imports neither enumerator nor generator.
It reconstructs cells from explicit permutation cycles, verifies every group
relation, connectedness, simple polygon boundaries, opposite face orientations
on each edge and circular vertex links. It checks negative even Euler
characteristic, genera 4,9,19,91, k=2g and all independent GF(2)/logical tests.
There are no same-(n,k) existing peers at this snapshot; shared validation
also compares stabilizer row spaces in both X/Z orientations if peers appear.

## Independent distance verification

The Linux-only full oracle constructs primal/dual graphs from parity columns
of weight two and detects homology by complete logical-pairing bases. For each
root it builds a BFS tree and considers nonzero-homology fundamental cycles.
Every nontrivial cycle decomposes into simple cycles. A shortest nontrivial
cycle C, rooted at one of its vertices, is a sum of those fundamental cycles;
one has nonzero homology. For each edge uv in C,
`dist(root,u)+dist(root,v)+1 <= |C|`, so the minimum candidate over all roots
has the exact homological distance. Tree backtracks cancel in GF(2) to produce
a verified support. Check its syndrome and exclusion from stabilizer row space
before reporting it. Complexity is O(V*(V+E)) per half after detector labels;
no external distance solver or unconstrained support sweep is used.

The Mac runs only the n=60 oracle as a short unit test, plus a six-edge graph
against literal support enumeration. Linux full checks have a 30-second
per-half budget, a 150-second wall backstop and 4 GiB cap. A verification
budget failure becomes a server package, not an unbounded run. The solver
smoke uses MaxSAT and CC independently, serial 60 seconds per input, one
allocated core and 4 GiB cap. Raw source/binary/input hashes, bounds, witnesses
and independent-oracle outputs are retained. See GH-165/REPORT.md for actual
execution status. Actual Linux graph results exactly reproduce primal/dual
(6,4), (8,6), (8,8), (10,10). Both internal engines solve the first three
cases exactly at 4,6,8. n=1800 remains an incomplete numeric smoke gate:
default MaxSAT produces no bounds; CC produces UB=10 only; finder-off
MaxSAT gives LB=5 only; a one-second pre-pass attempt produces no bounds.
These compatible observations are retained as missing/partial, not promoted
to a complete solver result. No further CI extensions are attempted.
Optional two-engine long reproduction jobs are prepared, not executed, in
GH-165/runner/ for a PI-assigned server core. The n=1800 matrix construction
and independent exact graph proof pass, but its DistQLDPC numeric smoke
acceptance remains open. Main integration is not performed.

## Unresolved source issue: Table I row n=1920

That row is present in the JSON with status AWAITING_PI_ORIENTATION_DECISION;
the generator refuses it. No matrix files for it have been added. The paper's
Table I word has oriented quotient order 3840, consistent with n=1920, but
adding reflection conjugates as another passage describes reduces the order
to 120. The mirrored word moves all 3840 oriented quotient elements, so the
two interpretations are distinct. Reverse relator scan order produces identical
canonical tables for each interpretation. PDF page 10 and HTML were checked
for transcription agreement. This is a construction-definition ambiguity,
not a DistQLDPC result discrepancy or a claim that the paper's distance is wrong.

```
python3 scripts/codegen/diagnose_hyperbolic_orientation.py --output /tmp/hyp-orientation.json
```

Raw diagnostic, expanded words and tests are retained under GH-165. PI was
asked whether to authorize the explicitly oriented version conditional on
independent topology and distance checks. Until that decision arrives, this
row and the broader continuous goal remain open. The four unaffected cases
are validated separately. No external author was contacted.
