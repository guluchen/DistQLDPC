The optional code-distance C search implements sparse incidence scans, input-checked cyclic actions, short syndrome filters, and the even-overlap and pair-row rules from GH-162 and GH-181. The upper-witness program searches randomized information sets with a fixed stream, reduces supports using same-type stabilizers, and tries pairs of light vectors. The verifier rereads both parity-check matrices and uses the witness only as an upper bound.

The packed certificate code instantiates the parent bounded-search proofs at 378 and 756 coordinates. The larger representations, cached row accessor, orbit and packing advice, and bounded-query report are maintained here. Verification and runtime dependencies are described in [README.md](README.md). Third-party idea attribution is in [NOTICE](NOTICE).

The optional C traversal for reversed BFS follows GH-183. The Coq lower-bound proof admits arbitrary advice indices and selects rows from the original check list.

For the packed verifier, sparse row advice follows GH-181. The verifier constructs the named sums and proves that they preserve the input kernel. The dynamic pair-packing check separately constructs an odd sum disjoint from a certified packing.

The 189-bit specialization uses the existing three-word Coq algebra and shares the checked search templates and C advice with the larger verifiers.

Added an independent C proposer for sheared inversions and reversed cyclic blocks. Raw row images are checked in both directions using the existing raw duality lemma. The packed theorem transports the lower bound to the opposite half and preserves the original Pauli side of the witness.

Added a C proposal for disjoint representatives of one logical coset and a Coq proof that checks disjointness, the coset and completeness of the detector family. Added a checked grid-translation proposal for root coverage. The proposals use the PCM and the weight of the in-process upper witness.

For different generator lists of the same permuted subspaces, added a C row-space isometry adviser. Its permutation is passed to the existing checked packed isometry test.

Implemented a certificate-producing saturated erasure check in C and proved the arbitrary-row-sum packing rule in Coq. The erasure-region idea follows the GH-195 attribution to Qubitserf 04b9349 by Serban Cercelescu (MIT).

Added checked parity-of-weight tests on the check-row span and the detecting quotient, with positive and negative controls including redundant generators.

- Extended the checked packed representation to two 756-bit children and
  specialized the C advisers and witness search for 1,512 coordinates.
