The optional code-distance C search implements sparse incidence scans, input-checked cyclic actions, short syndrome filters, and the even-overlap and pair-row rules from GH-162 and GH-181. The upper-witness program searches randomized information sets with a fixed stream, reduces supports using same-type stabilizers, and tries pairs of light vectors. The verifier rereads both parity-check matrices and uses the witness only as an upper bound.

The packed certificate code instantiates the parent bounded-search proofs at 378 and 756 coordinates. The larger representations, cached row accessor, orbit and packing advice, and bounded-query report are maintained here. Verification and runtime dependencies are described in [README.md](README.md). Third-party idea attribution is in [NOTICE](NOTICE).

The optional C traversal for reversed BFS follows GH-183. The Coq lower-bound proof admits arbitrary advice indices and selects rows from the original check list.

For the packed verifier, sparse row advice follows GH-181. The verifier constructs the named sums and proves that they preserve the input kernel. The dynamic pair-packing check separately constructs an odd sum disjoint from a certified packing.
