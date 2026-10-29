# X-cube deferred family certificate design — not implemented

Source: Sagar Vijay, Jeongwan Haah and Liang Fu,
*Fracton Topological Order, Generalized Lattice Gauge Theory and Duality*,
[1603.04442v1](https://arxiv.org/abs/1603.04442v1), PRB94,235157(2016),
[DOI](https://doi.org/10.1103/PhysRevB.94.235157), TableI and AppendixB.
Static physical links, X on12cube edges, Z on4coplanar vertex edges.
EqB8's displayed k=6L-3 derivation has an odd-L qualification. Do not use
Floquet/gauge, circuit or energy-barrier results as a static distance.
No author implementation read or used. Source-license review still needed
before acceptance; original mathematical reconstruction only.

Additional primary lead: Brown–Williamson, *Parallelized quantum error
correction with fracton topological codes*, PRResearch2,013303(2020),
DOI10.1103/PhysRevResearch.2.013303, Fig6 discusses one-dimensional logical
supports. Its physical convention may use dual faces; establish an explicit
qubit/type mapping before transferring any operator. No published exact d
is yet extracted or asserted from that source here.

Possible fixed odd-L ladder3/5/7/9 gives n3L^3=81/375/1029/2187 and expected
k15/27/39/51. This is a genuine mainstream type-I/foliated construction
gap, not an unknown-distance headline or another Haah Code1 instance.
Parameters are not frozen and no new cases are counted yet.

## Original finite distance-certificate idea to verify

For an actual CSS half, suppose a complete opposite logical-detector basis
is supplied. For EACH detector, supply L pairwise support-disjoint operators
in its same stabilizer coset. A nontrivial kernel word has odd pairing with
some detector; commuting with the stabilizers forces odd pairing with all
L equivalent representatives, so its physical weight is at least L.
An actual verified word of weight L then supplies the matching upper.
The checker needs only GF2 kernel/quotient/pairing/membership and actual
support disjointness, no quantum distance/support enumeration.

For the proposed periodic edge convention:

1. X logicals: a full axis-i edge line at fixed transverse coordinates(u,v).
   A complete candidate detector set per orientation uses u0, all v, plus
   v0, all nonzero u (2L-1 lines). For the base line at(u,v), choose L-1
   distinct u'!=u and distinct v'!=v, paired bijectively. The product of
   three lines(u',v),(u,v'),(u',v') should differ from the base line by
   a product of cube-X checks filling the transverse rectangle and entire
   periodic axis. These L-1 triple-line representatives plus the base line
   are pairwise disjoint. Verify actual stabilizer membership, not merely
   a picture or equal topological labels.
2. Z logicals: a transverse ribbon of parallel axis-i edges, at one axis-i
   coordinate and one fixed other transverse coordinate, running across the
   remaining direction. Translating the ribbon through all L axis-i
   coordinates gives disjoint representatives. Adjacent ribbons should
   differ by a product of coplanar vertex-Z checks along the ribbon. Again
   check actual row-space membership. Such ribbon candidates have weight L.

Compute actual full kernel/quotient bases and certify that the proposed
line/ribbon detector sets are complete with full-rank pairing. A geometric
line or ribbon by itself is not a distance proof. All membership,
disjointness, completeness and upper checks must pass on the actual
matrices. Independent incidence and finite ranks, source conventions,
same(n,k) peers/duplicates, full typed stabilizer-space connectivity,
regeneration/mutants and Linux internal-engine checks still apply.

This is an unimplemented design, not an accepted proof or numerical result.
Refresh coordination, write three proposals and preregister before building.
Retain current incomplete numeric/proof jobs separately; no extra scientific
CI reruns or Mac/support search to fill those gaps.

PI steering2026-10-30: after GH-187, prioritize unresolved individual distances.
This known-structure coverage/control lead is deferred behind suitable
published-bound or heuristic-estimate targets; it is not the selected next batch.
