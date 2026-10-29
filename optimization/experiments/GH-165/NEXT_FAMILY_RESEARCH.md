# Next separate construction: nonabelian ZSZ-LP

Primary source opened: Y. Hong, arXiv:2607.27644v1, Sections 2.1-2.4,
Table 1 (quantum claims) and Table 3 (all group/trinomial parameters).
Six explicit cases at n=160,240,320,390,550,775. This is a research lead,
not generated inputs or a passed validation gate.

Group elements use canonical x^a y^b with a metacyclic twist. Implement the
published group multiplication directly and independently reconstruct regular
permutation matrices. Left and right actions must remain distinct; inverse
and transpose conventions matter. Use the exact five-block matrices in Eq.1,
not an abelian two-block approximation or a toy cyclic replacement. Verify
noncommutativity of the underlying group, associativity/presentation, left/right
commutation, classical seed ranks, full quantum CSS ranks and logical pairing.
The paper's normal candidate family has n/5 logicals, subject to rank checks.
The separate fold-symmetric table changes trinomials and distances: do not
mix its n=390 upper bound with the ordinary Table 3 case. Published heuristic
upper estimates must stay upper bounds, not exact expected distances.

Original code/math-only reconstruction; no third-party data or solver code.
Some source paper statements involve surgery gadgets and gauge logicals;
exclude those from a direct full CSS stabilizer-distance library batch.
Select original data codes, not surgery/gauge projections. Check same-(n,k)
peers across current main and pending reviewed library branches before adding.
Use the BP upper-bound claim parser or an explicitly tested generalization,
never force the exact-claim smoke parser onto an estimated-distance case.

After completing GH-165 unaffected cases: recheck issues and branches, open a
separate Codex issue with three proposals, implement one-family work branch.
Keep n=1920 hyperbolic interpretation pending until PI replies. It must not
silently block independent work or be marked complete in the coverage ledger.
