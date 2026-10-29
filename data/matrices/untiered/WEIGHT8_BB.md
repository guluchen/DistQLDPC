# Weight-8-check BB representatives (GH-164)

Six cases from Lu, Yang and Guo, *Quantum bivariate bicycle codes with weight-8
checks surpassing the BB benchmark*, [arXiv:2609.06572v1](https://arxiv.org/abs/2609.06572v1),
Tables 1-3. Published parameters: [[72,14,8]], [[72,4,10]], [[144,16,10]],
[[144,10,12]], [[200,20,9]], [[200,8,10]]. The JSON case file identifies the
table/row, grid and both four-term polynomials. Published exact distances are
claims distinct from DistQLDPC observations. This is a BB structural extension,
not a new disjoint code family. It covers the paper's 72-200 range; no larger
parameters or exact distances are extrapolated.

With sites (x,y) in Z_l x Z_m, row t of a polynomial is its support translated
by t. Generate Hx=[A,B], Hz=[B^T,A^T]. Commuting translations give
Hx Hz^T=AB+BA=0. Coordinates use x*m+y; transposition negates exponents.
All four matrices are generated from published mathematics with original
GPL-3.0-or-later code. No external implementation, matrix files, paper text or
third-party distance tools are redistributed or run. See NOTICE.

Reproduction (Python standard library):

```
python3 scripts/codegen/weight8_bb.py --all --out /tmp/weight8-fresh
python3 tests/test_codegen_weight8_bb.py
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
python3 scripts/codegen/validate_weight8_bb.py --output /tmp/weight8-construction.json
```

Compare all 24 fresh files byte for byte. Gx/Gz are computed by the repository's
`compute_logicals.py --method bitset`. The independent validator constructs
separate one-dimensional shift matrices and dense Kronecker products; it does
not import the generator. Shared checks validate GF(2) ranks, quotient logical
bases and full pairing. Tests catch a missing transpose, wrong grid axis and
GF(2) term-collision errors. An independent support oracle is checked against
literal enumeration on small random matrices.

The same-(n,k) existing TN_72_14_4 is provably inequivalent, including arbitrary
column permutations and X/Z swap: exhaustive pair-syndrome collisions exclude
all nontrivial words of weight <=4 in both BB halves, while the TN halves have
verified nontrivial supports [0,2,56,58] and [0,6,19,57]. Every support of weight
<=4 splits into two supports of size <=2, so the exclusion is exhaustive and
includes singletons, pairs, triples and quadruples. Stabilizer membership is
checked separately. Other selected (n,k) pairs have no existing peers.

Linux-only serial 60-second smoke runs and both-engine witness audits are
provided by `.github/workflows/weight8-bb-library-smoke.yml`. Default MaxSAT
argv remains implicit; `--engine cc` selects independent CC search. Each run
is pinned to one allocated Actions core with a 4 GiB address-space cap and
90-second wall backstop. Source, binary and all input hashes and exact raw
logs are retained. No solver runs execute on the PI Mac. Results remain
NOT_RUN until the GH-164 report and manifest contain actual evidence.
