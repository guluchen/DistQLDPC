# Literature survey: exact and heuristic minimum-distance computation for CSS / qLDPC codes (state as of 2026-10-18)

Prepared for the next DistQLDPC optimization round. Scope: (a) exact / certified distance computation
(connected-cluster searches, Brouwer-Zimmermann and information-set variants, SAT / MaxSAT / ILP, symmetry
reduction, certification); (b) randomized upper-bound finders; (c) 2026 distance results on BB and TN-type codes;
(d) the algorithmic content of C. Crocker's Zenodo records (described from the public README only).
Emphasis on Oct 2025 - Oct 2026, plus the classics.

What was read: arXiv abstract pages and (where the HTML was available) the full text of every paper below; the
public Zenodo landing pages and the public README / ZENODO_DESCRIPTION / CHANGES files of records 23445463 and
23352655 (local copy under `ext/zenodo-23445463/unz/`); the READMEs of dist-m4ri (v0.14.5, 2026-10-14),
QDistRnd, codeDistancePYPI, the Rowshan-Devitt and Lee companion repositories and the qldpc-challenge board;
DistQLDPC's own README ("Connected-cluster (CC) engine"), MODIFICATIONS.md, GH-124 S1_REPORT.md and GH-130
REPORT.md, the GH-124 Tier-5 CC logs and the team's `ext/zenodo-verify` runs. No code was changed.

Notation: "CC" = connected / irreducible-cluster search (Dumer-Kovalev-Pryadko). "Level w" = the exhaustive
search for a nontrivial logical of weight w. "pack / excl / orbf / mrv" = DistQLDPC's CC rules.

---

## 1. Annotated bibliography (newest first)

### 1.1 Oct 2025 - Oct 2026

**[Crocker-LP] C. Crocker, "Exact minimum distances of five lifted-product quantum codes from Cain et al. (2026),
Xu et al. (2024) and Panteleev-Kalachev", Zenodo, doi:10.5281/zenodo.23445463, v1.0 14 Oct 2026, v1.1 17 Oct 2026.
Text/data CC BY 4.0, code MIT (Python 3.10+, NumPy, Numba).**
- Result: [[2610,744,16]], [[1122,148,20]] (Cain et al. lp16 / lp20), [[714,100,16]], [[1020,136,16]] (Xu et al.
  l=21 / l=30), [[1054,140,20]] (PK_31). v1.1 credits DistQLDPC's earlier posting (11 Oct 2026) of d=16 for the two
  Xu et al. codes and says the codes are identical to DistQLDPC's up to the relabelling i -> -i inside each
  circulant block (DistQLDPC's exponents are theirs negated). It states that for lp16, lp20 and PK_31 no exact value
  was previously established "as far as we can find".
- Algorithm, as the README describes it ("program 1", `cluster4.py`; "program 2", `lpcheck2.py`, written blind):
  branch-and-bound over supports in the irreducible-cluster tradition (DKP), following the "anchored adaptation" of
  Rowshan-Devitt. Four ingredients: (1) *minimality lemma* - a minimum-weight logical contains no nonempty proper
  zero-syndrome subset, so a zero-syndrome node is a leaf (reported if nontrivial, discarded if a stabilizer);
  (2) *anchoring* - Z_l shifts every block at once, so a minimum logical exists whose first block (lowest index met)
  contains offset 0; one run per block b, anchored at qubit (b,0), all qubits of blocks < b excluded (= DistQLDPC's
  orbit seeds with earlier orbits forbidden); (3) *branching* on an unsatisfied check with the fewest free qubits;
  child i adds q_i and excludes q_1..q_{i-1} ("exactly one child is consistent with T, so the search is complete and
  has no duplicates" = DistQLDPC's `excl` + `mrv`); (4) *pruning*, program 1: the degree bound
  ceil(syndrome weight / max column weight), a greedy packing of unsatisfied checks with disjoint free qubits
  (= DistQLDPC `pack`), and a **parity bound used only when every column has odd weight** (true for these LP codes:
  column weights 3, 5, 7). Program 2: a **block-grid bound** - every qubit meets each l-row check block at most once
  and the check blocks form a grid indexed by qubit types, so the number of added qubits is at least the optimum of a
  small integer program over the per-block counts of unsatisfied checks (asserted structurally before use).
  Leaf test: odd overlap with one of k dual logical representatives (multiword bitmasks, k up to 744).
  "Syndrome-weight pruning" in the Zenodo description = the degree bound + packing + parity bound above.
- Scale (one core, Intel i7-1185G7 laptop, 165-190 MB): program 1 (X+Z): [[2610,744]] no logical <= 15 in 47 s;
  [[1122,148]] <= 19 in 65 s; [[714,100]] <= 15 in 5 s; [[1020,136]] <= 15 in 4 s; [[1054,140]] <= 19 in 73 s.
  Program 2 (weaker bound) 76 s - 5.1 h, up to 1.9e10 nodes. Log tails show per-orbit node counts of ~1e7 - 3.5e7
  per half at the last refuted level (e.g. PK_31 Z: 34.9e6 nodes, 279 s; lp16 Z: 13.6e6 nodes, 118 s).
- Limitations stated by the author: no independently checkable certificate; AI-written code without expert review.
- Cross-check: DistQLDPC's CC engine (Mac, `ext/zenodo-verify/cc_summary.txt`) gives the same values:
  cain1122 d=20 in 28 s, cain2610 d=16 in 8 s, pk31 d=20 in 32 s, xu21/xu30 d=16 in ~1 s. So our engine is on par
  with program 1 on these codes, with two pruning ideas (parity bound, block-grid bound) that we do not have.

**[Crocker-BB360] C. Crocker, "Exact distance of the [[360,12]] bivariate bicycle code of Bravyi et al.: d = 24",
Zenodo, doi:10.5281/zenodo.23352655, 13 Oct 2026, v1.2, CC BY 4.0 (release_bb360.zip, 72.5 kB).**
- Two separately written exhaustive searches for X-logicals find none of weight <= 22; **all X-logicals have even
  weight because each column of H_Z has weight 3**, so d_X >= 24; an explicit weight-24 X-logical; Bravyi et al.'s
  duality lemma extends the bound to Z. Anchored cluster search per Rowshan-Devitt.
- Runtimes: one core each, 1.17e9 nodes in ~79 min and 2.90e9 nodes in ~2.2 h. (DistQLDPC CC: d=24 in 1706 s on a
  contended EPYC core; GH-124 S1.) This is an independent confirmation of our BB_360_12_24.
- The same programs give d=14 for the (disconnected) [[360,16]] and [[360,20]] codes of arXiv:2606.02418.

**[Lee26] J. Y. Lee, "Designing Group-Valued Codes with Full Regular Low-Weight Bases", arXiv:2610.06820, 5 Oct
2026. Companion repo github.com/yeon-lee/public-regular-logical-frames (Python + C++17; no license file seen).**
- Exact distance certification of LP / "pair-partition" codes above 1000 qubits by an exhaustive B&B (Appendix A):
  node = (support T, syndrome s, available coordinates); branch on an unsatisfied check, child i includes q_i and
  forbids q_1..q_{i-1}; restricted to support-irreducible kernel words; translation reduction for cyclic lifts (root
  (b,0) per block, earlier blocks forbidden). Pruning: (i) wt(s) > b * w_c (degree bound); (ii) an unsatisfied check
  with no available neighbour; (iii) **p unsatisfied checks with pairwise disjoint available neighbourhoods and
  p > b** (= our `pack`, independently published); (iv) **stabilizer-overlap rule**: a shortest nontrivial logical z
  has |supp(z) ∩ supp(g)| <= wt(g)/2 for every same-type stabilizer generator g (else z+g is lighter); overlap only
  grows along a branch, so partial supports violating it are discarded. (v) a "λ-odd" variant: search the lightest
  word with λ(z)=1 for a logical functional λ (per-logical search; roots only in selected blocks). (vi) a verified
  sector-exchange symmetry transfers X exclusions to Z. Lower-bound *filters* on constituent/quotient codes only
  screen candidates (constituent distance is an upper bound on quantum distance). Parallel workers with a partition
  checker ("each subtree assigned exactly once").
- Scale: LP [[1088,128,22]]: exclusion through weight 21, 7.82e8 nodes, 258 s wall on 4 workers; PP [[1024,256,24]]
  (one-sided λ=1 exclusion through 24: ~26.7 h single-thread total); smaller LP runs 36 s / 7.4 min on an M3 Pro.
  Table 1 of the paper lists these as exact.

**[CruzBenito26b] J. Cruz-Benito, "LLM-Guided Discovery of Weight-Five Bivariate Bicycle Codes", arXiv:2610.06623,
5 Oct 2026.** Certifies [[96,4,10]], [[140,6,10]], [[180,4,14]] and seven Lin-Pryadko constructions; the challenge-
board PR #2829 derived from it posts [[432,4,23]] as a witness-backed *upper bound*. No new algorithm.

**[Schneider26] N. Schneider, E. Nachmani, "Distance Prediction for Quantum Codes", arXiv:2610.18130, 13 Oct 2026.**
BB-Net, attention network predicting BB distances from heuristic-ub labels (96.4 % on the test set, 98.9 % on the
subset with certified exact distances). Screening tool only; no bound semantics. Not usable for certification.

**[GJS25] E. Grigorescu, V. Jha, E. Samperton, "On the hardness of approximating minimum distances of quantum
codes", arXiv:2509.21469 (v2 3 Oct 2026, FSTTCS 2025).** NP-hardness of computing/approximating CSS distance via a
direct reduction from classical codes through hypergraph products; a "square-root barrier" for additive
approximation on HGP codes. Background only.

**[RD26] M. Rowshan, S. Devitt, "Logical Operator Decomposition for Distance Analysis of Bivariate Bicycle Codes",
arXiv:2609.39395, 30 Sep 2026 (v2 1 Oct). Repo github.com/mohammad-rowshan/BB-Codes-Distance-Logical-Decomposition
(Python + C, MIT).**
- Algebra: the Z-logical quotient K/S over F2[x,y]/(x^l-1,y^m-1) sits in a short exact sequence with an annihilator
  quotient (kernel) and a colon quotient (cokernel); d_Z = min(d_A, d_C); r_A = r_C = k/2 for every BB code
  (Frobenius structure). Lemma: a minimum-weight logical has no nonempty proper zero-syndrome subset; this holds in
  the colon component, not the annihilator component.
- **Translation-anchored cluster search**: two anchors (left-block origin, right-block origin), branch on the
  lowest-index unsatisfied check over its qubits not yet in T; prune when the syndrome is zero (Lemma 2) or when
  |T| + ceil(u/c) > W with u = syndrome weight, c = max(wt(a), wt(b)) (degree bound). Node bound ~2 Σ_{j<=W}
  (wt(a)+wt(b)-1)^{j-1} = O(5^W) for weight-6 checks, nearly independent of n.
- Scale (Table IV, radius W = d-1): [[288,12,18]] 455,504,708 nodes, 7-13 s in C on one core (README);
  [[144,12,12]] 284,281 nodes < 0.1 s. Enumerates all minimum-weight classes (84 for [[288,12]]). "Each extra unit of
  radius costs roughly a factor 2 to 6". Future work named: canonicalisation under a larger automorphism group; the
  two anchors and first-level branches are independent jobs for several cores.
- Note the absence of packing / sibling exclusion: their [[288,12]] radius-17 search costs 4.6e8 nodes; DistQLDPC's
  CC with pack+excl+orbf solves BB_288 in ~1 s (GH-124 S1 tier3 cell).

**[LYG26] L. Lu, R. Yang, G. Guo, "Quantum bivariate bicycle codes with weight-8 checks surpassing the BB
benchmark", arXiv:2609.06572, 6 Sep 2026.** Weight-8 BB census at n=144; d_X = d_Z proven; distances "computed
exhaustively by a cross-validated bit-mask verifier" (no algorithmic detail on the abstract page; Lemma 3.16 gives an
exact-certification criterion for d_X). Largest: [[144,16,10]], [[144,10,12]], [[144,6,d>=15]] (lower bound only).

**[SCM26] E. Sabo, M. B. Can, D. Marquis, "Spectral Theory of Semisimple Bivariate Bicycle Codes",
arXiv:2608.27565, 27 Aug 2026.** Frobenius-orbit idempotents give logical dimensions and "lower bounds on minimum
distances" (algebraic, BCH-like); block-monomial symmetry subgroup. Not checked whether the bounds reach 24/34 for
[[360,12]] / [[756,16]]; algebraic BCH-type bounds are typically far below the true distance for these codes.

**[MACK26] F. A. Mian, V. L. Addala, A. Meraj, A. Chadha, S. Krastanov, "Quantum Tanner Codes at Moderate
Blocklength", arXiv:2608.12509, 12 Aug 2026 (QuantumExpanders.jl, open source).** QT codes from non-abelian
SmallGrp groups, n in [500,1000]: [[480,8,(<=21,<=21)]], [[504,4,(<=36,<=27)]], [[672,4,(<=48,<=28)]],
[[720,6,(<=30,<=30)]], [[864,8,(<=39,<=31)]], check weights 9-20; bounds from up to 3.5e8 trials of the randomized
estimator sQetch (an information-set-type sampler; no description found elsewhere). **No lower bounds**: nobody has
certified a TN-type distance above ~18 in the literature; DistQLDPC's TN lower bounds 20-24 (6 h) appear to be the
best public certified TN lower bounds at n > 200.

**[LGLY26] L. Lu, G. Guo, Y. Liu, R. Yang, "Quantum Bicycle LDPC Codes with High kd^2/n from Divisor-Driven
Search", arXiv:2608.09115, Aug-Sep 2026.** Cyclic two-block codes; distance certified exactly via the Calderbank
correspondence to additive F4 codes (i.e. Magma-style weight enumeration); n <= 90. Small scale; no new pruning.

**[Hong26] Y. Hong, "Quantum LDPC codes with design rate 1/5 and good performance below 1000 physical qubits",
arXiv:2607.27644, 30 Jul 2026.** ZSZ-LP codes; exact distances by pySATDist (Webster's PySAT-based SAT method) up to
[[320,64,14]]; [[390,78,<=16]], [[550,110,<=18]], [[775,155,<=22]] from QDistEvol with 1e6 iterations. Automorphism
orbits of minimum-weight codewords used for logical bases (App. C.4), not for pruning.

**[OK26] K. Okada, K. Kasai, "Pair-Partition Constructions for CPM-Based Quantum LDPC Codes", arXiv:2607.14091,
15 Jul 2026 (v4 13 Aug). Project page kasai.ict.eng.isct.ac.jp with distance-search records, logical vectors and a
GitHub repo (construction, exponent search, girth, distance verification).** Abstract: an algorithm verifying lower
bounds on the quantum distance of a fixed CSS lift, "rigorously valid pruning rules", and **cyclic symmetry makes the
support-enumeration bound independent of lift size**. E.g. [[472,122,14]]: complete exclusion through weight 12 plus
the even-weight property gives d >= 14; weight-14 non-stabilizer representatives give d = 14. Zheng et al.
arXiv:2607.28605 (4 Oct 2026 v2) cite this "complete low-weight-codeword search" for d = 20 of a canonical LP code
and list Cain et al.'s [[1122,148,<=20]]. A follow-up ("Low-Weight Canonical Logical Bases from Pair-Partition
Codes", [[320,80,14]], [[448,112,18]], [[2048,512,24]]) is announced but I could not confirm an arXiv id.

**[DMT26] V. R. Danilko, I. Yu. Mogilnykh, Ya. A. Tikhomolov, "Minimum distances of LDPC codes in 5G standard",
arXiv:2607.04716, 6 Jul 2026 (classical).** Quasi-cyclic 5G LDPC codes: [9984,8448] d in 8..14, [25344,8448] d in
22..57; lower bounds from a "modular" Brouwer-Zimmermann for QC codes, upper bounds from a Vontobel-Smarandache-type
lemma. Relevant only as evidence that BZ-type lower bounds stay weak on long sparse codes.

**[CJL26] Y.-F. Chen, S. M. R. Jafari, C.-Y. Lai, "SAT, MaxSAT, and SMT for QLDPC Distance Computation: A
Large-Scale Empirical Study", arXiv:2606.12445, 29 May 2026 (QDistSAT, DistQLDPC repos).** 46 solver
configurations (CDCL via PySAT, CryptoMiniSat XOR, MiniCard/Gluecard, Z3/CVC5, unsat-core MaxSAT, MaxCDCL /
DistQLDPC) vs GurobiDist, MIPDist, Magma, dist_m4ri_CC on 27 CSS instances (BB/GB 72-360, LP 34-1768, TN 36-360),
2 h limit. Findings: cardinality handling matters more than XOR reasoning; BZ loses its classical advantage on qLDPC;
branch-and-bound MaxSAT (MaxCDCL) beats unsat-core MaxSAT; BB_288/BB_360 unsolved by all 46 configurations;
dist_m4ri_CC competitive on small BB, times out on BB_144_14_14. (The PI's own paper; listed for completeness.)

**[CBCKF26] J. Cruz-Benito, A. W. Cross, D. Kremer, I. Faro, "Evolutionary Discovery of Bivariate Bicycle Codes
with LLM-Guided Search", arXiv:2606.02418, 1 Jun 2026.** Exact distance = 2k MILP instances (one per logical
generator, HiGHS via scipy), exact only when all reach MIP gap 0; [[288,16,12]] in 80 min (32 logicals),
[[144,12,12]] in 13 min; n <= 360. Confirms MILP-per-logical is ~2 orders of magnitude slower than CC on BB codes.

**[Lean-QEC] M. Ehatamm, Y. Lee, X. Wu, R. Tao, "End-to-End Formalization of Quantum Error Correction",
arXiv:2605.16523, 15 May 2026.** Lean 4 library; machine-checked distance certificates via a verified reduction of
the distance condition to SAT (error-location encoding with k ceil(log2 n) variables; BitVec flattening). Largest
certified: [[90,8,10]] BB; scales to 144 qubits outside the kernel. Shows that *checkable* lower-bound certificates
for qLDPC distances currently stop at n ~ 100.

**[Cain26] M. Cain et al., "Shor's algorithm is possible with as few as 10,000 reconfigurable atomic qubits",
arXiv:2603.28627, 30 Mar 2026.** Defines lp16 [[2610,744,<=16]] and lp20 [[1122,148,<=20]] (App. A.1); bounds from
BP-OSD distance estimation with >= 25,000 trials. Now exact per [Crocker-LP] and per our CC runs.

**[WJH26] M. Webster, A. Jacob, O. Higgott, "Distance-Finding Algorithms for Quantum Codes and Circuits",
arXiv:2603.22532, 23 Mar 2026 (v2 14 Aug 2026). Package codeDistance, github.com/m-webster/codeDistancePYPI, MIT.**
- Exact methods: Brouwer-Zimmermann (Magma `MinimumWeight`/`MinimumWord`, own BZDistMW, QubitserfBZ), connected
  cluster (dist_m4ri_CC wrapper, pure-Python connectedClusterMW; Algorithm 10: BFS extension by qubits in
  supp(E H2) \ E with H2 = Hx^T Hx, complexity O([2(m-1)]^d), "partial lower-bound results are not available if the
  C run is terminated early"), MaxSAT (CASHWMaxSAT-CorePlus via PySAT; CLISAT), MIP (Gurobi, SCIP), meet-in-the-
  middle (Qubitserf MM). Heuristics: random information set (dist_m4ri_RW, QDistRnd, QDistRndMW), syndrome decoders
  (BP-OSD/BP-LSD/tesseract), Stim undetectable errors, and **QDistEvol** (evolutionary search over column
  permutations; fitness = (min weight, mean nontrivial weight); mu=10 parents, lambda=100, 100 generations, only
  mutation by random transpositions, pMut = n/50).
- Benchmark (8 h limit): LP CSS (19 codes, 34-3230 qubits): Gurobi 6 completed < 8 h and correct partial results on
  all 19; m4riCC 6 completed, 13 no result. BB CSS (20 codes, 72-3024 qubits): Gurobi/SCIP/CLISAT/m4riCC each
  completed 5, Magma 1; "lowest distances are not known with certainty". **Quantum Tanner (22 codes, 36-684 qubits,
  row weight 9)**: Gurobi 5, SCIP 4, CLISAT 4, m4riCC 4, Magma 3 completed; Magma best overall (36 %). QDistEvol was
  the most accurate heuristic (LP 19/19, BB 13/20, TN 8/22 at the lowest known value).
- **756-qubit BB code: "the best estimate for the distance is 34"**; QDistRndMW finds 34 in only 2 % of runs;
  QDistEvol reaches ~50-60 % with 1000 generations / pMut=15. This is Bravyi et al.'s [[756,16,<=34]], i.e. our
  BB_756_16 (our basis-row ub is 52; our certified lb 27).
- The TN set (36-684, weight 9) coincides with the family DistQLDPC benchmarks; Webster's `paper results`
  spreadsheets hold their best ub per code (worth extracting for BB_864_4, BB_1080_4 and the TN `ge9` stems).

**[SRB25] B. C. B. Symons, A. Rajput, D. E. Browne, "Sequences of Bivariate Bicycle Codes from Covering Graphs",
arXiv:2511.13560, 17 Nov 2025 (v3 6 Aug 2026).** h-cover BB codes; k_h >= k; for odd h, d_h <= h d and (if k_h = k)
d <= d_h. Table 1 lists [[360,12,24]] (l=30, m=6, h=5 cover of [[72,12,6]]), [[432,12,<=24]], [[288,12,18]]; the
listing without "<=" for 360 could not be traced to an exact computation in the text I could read. The cover bound
d_h >= d is a *structural lower bound* usable as a free initial `d_lb` for cover codes (weak: 6 for BB_360).

### 1.2 Classics and tools (pre-Oct 2025)

**[LLSC25] Z. Liang, K. Liu, H. Song, Y.-A. Chen, "Generalized toric codes on twisted tori for quantum error
correction", arXiv:2503.03827, PRX Quantum 6, 020357 (2025).** Gröbner-basis analysis of BB codes; weight-6 codes
[[120,8,12]], [[186,10,14]], [[210,10,16]], [[248,10,18]], [[254,14,16]], [[294,10,20]], [[340,16,18]],
[[310,10,<=22]], [[360,12,<=24]]. Distances computed (method not on the abstract page; Crocker reproduces d=18 for
[[248,10]]). Good Tier-5 candidates in the d 16-20 range with k=10-16.

**[HQG24] F. Hernando, G. Quintana-Ortí, M. Grassl, "Fast Algorithms and Implementations for Computing the Minimum
Distance of Quantum Codes", arXiv:2408.10743 (v2 Jul 2025), ACM TQC 7(2):12 (2026).** Three BZ variants for the
symplectic distance of stabilizer codes (Saved_1_Gamma, Saved_2_Gamma over F4 with "packages", Saved_isometry via
(a,b)->(a,b,a+b)); saved row sums; lower bound L = g+1 (+ package correction); up to 45x faster than Magma on one
core, 8-core parallel; browser WebAssembly demo, no repository / license stated. BZ with K ~ n/2 gives ~1 bound unit
per enumerated weight per information set: useless for qLDPC beyond d ~ 12 (confirmed by [CJL26] and our Qubitserf
study).

**[dist-m4ri] L. P. Pryadko, W. Zeng, dist-m4ri v0.14.5 (2026-10-14), github.com/QEC-pages/dist-m4ri, GPL-2.0+.**
Multithreaded C: RW (random information set with Method-of-Four-Russians elimination, Lee-Brickell/Stern p=2
"pairs", QDistRnd-style `min_hits` convergence), CC (DFS from each start column using only larger columns; clusters
extended by the columns of the *first* unsatisfied row; rows sorted by increasing weight; **bitset syndrome with a
hash lookup for the last column**: "the syndrome left after the next-to-last column must equal a column of H" -
3-5x on CSS codes, 5-20x on circuit DEMs; `start=` columns for quasi-cyclic symmetry, `cbeg/cend` splitting across
machines, per-round time extrapolation with growth clamped to [2,10]), and a "bracketing" mode balancing CC and RW
threads from the current [d_min, d_max]. No packing bound, no sibling exclusion beyond the column order, no
stabilizer-overlap rule. Also handles Stim DEMs (exact column merging, detector dropping).

**[QDistRnd] L. P. Pryadko, V. A. Shabashov, V. K. Kozin, "QDistRnd: a GAP package...", JOSS 7(71):4120 (2022),
arXiv:2308.15140, GPL.** Random information sets over GF(q); empirical convergence criterion P_fail ~ e^{-<n>}
(mean hits per minimum-weight codeword). Upper bounds only.

**[Qubitserf] S. Cercelescu (Quantinuum), github.com/Quantinuum/Qubitserf, commit ab96b9c (2026-07-30), MIT.**
`cc` = plain DKP cluster search (seed = minimum qubit, branch on lowest-index odd check, closed-cluster dead end; no
budget pruning, no duplicate elimination, no symmetry); `bz` = Brouwer-Zimmermann with matroid-partition
information sets, vectorized CPU / Metal / CUDA enumerator; `mm` meet-in-the-middle; `codeaut` automorphisms via
nauty. Evaluated in `ext/QUBITSERF_REPORT.md`: weaker than DistQLDPC main as shipped; the only GPU code in this
space, and GPU-BZ is irrelevant for qLDPC.

**[Bravyi24] S. Bravyi et al., "High-threshold and low-overhead fault-tolerant quantum memory", Nature 627, 778
(2024), arXiv:2308.07915.** Defines the BB family and the pipeline *BP-OSD upper bound as a screen, then ILP for the
exact distance*; lists [[360,12,<=24]] and [[756,16,<=34]]; the X/Z duality lemma used by everyone since.

**[DKP17] I. Dumer, A. A. Kovalev, L. P. Pryadko, "Distance verification for classical and quantum LDPC codes",
IEEE Trans. Inf. Theory 63(7), 2017, arXiv:1611.07164; [DKP14] "Numerical techniques for finding the distances of
quantum codes", ISIT 2014, arXiv:1405.0348; [KDP13] "Linked-cluster technique for finding the distance of a
quantum LDPC code", arXiv:1302.1845.** The support of a minimum-weight codeword is a connected ("linked") cluster
in the qubit graph (two qubits adjacent iff they share a check); enumerate clusters of size w from each start
vertex using only later vertices; complexity exponent F_LC = delta (z_eff-1) H2(1/(z_eff-1)) ~ delta log2(e(z_eff-1)),
linear in the relative distance delta (vs delta log(1/delta) for information-set methods), so CC beats RW when
1-R <~ 1/(e z_eff). Irreducible clusters (no zero-syndrome proper subset) in [DKP17] Sec. V.

**[BZ] Brouwer-Zimmermann (Zimmermann 1996; Grassl's Magma implementation); G. White's generalisation of Brouwer's
cyclic-code improvement to quasi-cyclic codes / codes with known large-cycle automorphisms (Magma `MinimumWeight`
accepts partial automorphism groups); Lisonek-Trummer matroid-partition information sets; Quintana-Ortí et al.
Algorithm 994/1033 (vectorized, distributed BZ).** Standard references for the "enumerate under automorphisms"
idea; GPU versions of BZ exist only for classical codes (and a GPU genetic-algorithm RREF heuristic, Pegalajar
Cuéllar et al. 2023).

**[Board] unitaryfoundation/qldpc-challenge (Apache-2.0).** Public Pareto board; a distance witness certifies an
*upper bound*; "claiming a distance is exact additionally requires server certification" (a "refutation engine" in
the pinned validation stack, algorithm unspecified). Entries seen: [[360,12,25]] weight-7 BB (RIS upper bound,
PR #2206; a *different* code from BB_360_12_24), [[360,12,20]] non-CSS PBB (deep-MILP incumbent, 0/24 proven),
[[432,4,23]] weight-5 BB (upper bound). Crocker notes his [[360,12]] matches a board entry filed as an upper bound.

### 1.3 Items searched for and not found
- No GPU implementation of an exact cluster search for quantum codes (only Qubitserf's GPU BZ; GPU heuristics for
  classical codes).
- No proof-logging (VeriPB / DRAT) pipeline for qLDPC distance lower bounds; QMaxSATpb (2022) shows VeriPB proofs
  for MaxSAT are feasible, but MaxCDCL has no proof logging and the cluster tools emit none. Lean-QEC is the only
  machine-checked route and stops near n = 100.
- No published lower bound for BB_756_16 beyond ub 34; nothing on BB_864_4 / BB_1080_4 (check Webster's results
  spreadsheets); no certified TN distances above 18.
- No 2025-2026 paper by Pryadko/Kovalev on new cluster pruning; dist-m4ri's README is the current state.

---

## 2. 2026 distance results touching DistQLDPC's stems

| Stem | Our status (GH-124 S1 / GH-130) | Literature (2026) |
|---|---|---|
| BB_360_12_24 | d=24 (CC 1706 s; MaxSAT lb 17 / ub 24 at 6 h) | Crocker 13 Oct 2026: d=24, two programs, 79 min / 2.2 h one core; Liang et al. 2025 and Bravyi 2024: <=24; Symons et al. list 24 |
| BB_756_16 | lb 27 (6 h), ub 52 (basis rows) | Bravyi 2024 / Webster 2026: ub 34 (QDistEvol; RIS finds it in 2 % of runs). No published lb |
| BB_864_4, BB_1080_4 | lb 27 (6 h), ub 108 / 66 | nothing found; possibly in Webster's BB set (72-3024 qubits), check `paper results/` |
| TN_252_2_21 | dX=21 found by the prototype (5 h); lockstep CC: lb 21, ub 28 at 6 h | Webster TN set (36-684): exact solvers finish <= 5/22 in 8 h; no TN lb > 18 published |
| TN ge9 / ge17 stems | lb 20-24 (6 h) | Webster QDistEvol gives an ub per code (not extracted here) |
| LP_714 / LP_1020 | d=16 (ours, 11 Oct) | Crocker v1.1 credits DistQLDPC; independent recomputation agrees |
| LP_1054_140_20 | d=20 (CC 123 s) | Crocker 14 Oct: d=20 (73 s laptop, program 1); Webster: Gurobi/SCIP/Magma 8 h timeouts at 20 |
| new candidates | - | [[1122,148,20]], [[2610,744,16]] (Cain/Crocker; our CC 28 s / 8 s), [[1088,128,22]] (Lee), [[472,122,14]], [[2048,512,24]] (Okada-Kasai), Liang et al. weight-6 codes d 16-20, Mian et al. QT codes n 480-864 (ub only) |

---

## 3. Pruning / bounding techniques vs what DistQLDPC already has

| Technique | Where published | In DistQLDPC CC? | In DistQLDPC MaxSAT path? | Comment |
|---|---|---|---|---|
| Connected growth from a seed; closed cluster = dead end | DKP 2013-2017; Qubitserf; dist-m4ri | yes | frontier rule approximates it (GH-129/130) | - |
| Level-by-level exhaustive search, each empty level a certified lb | DKP; dist-m4ri; Crocker; Lee | yes (lockstep both halves) | global bound search (GH-73) | - |
| Branch on the qubits of one unsatisfied check | all CC tools | yes | frontier branching (odd row, fewest unassigned) | - |
| Fewest-free-qubit check (MRV) | Crocker, Lee ("fewest free qubits") | optional `mrv` | yes (fewest unassigned) | - |
| Sibling exclusion (child i forbids q_1..q_{i-1}) | Crocker, Lee; dist-m4ri (column order) | yes `excl` | n/a | - |
| Degree bound ceil(wt(s)/max col weight) | RD26, Crocker, Lee, dist-m4ri | implied by `pack`? (pack is usually stronger; the degree bound is cheaper and not always dominated) | no | add as a 1-line extra prune |
| Disjoint odd-check packing bound | Crocker (greedy packing), Lee (rule iii) | yes `pack` (DistQLDPC 2026-10-15; Lee 2026-10-05: independent) | no (GH-130 notes a "parity-packing propagator" idea) | not novel any more |
| **Even-weight / parity bound when all column weights are odd** | Crocker (BB360: level skipping; cluster4 parity bound); classical fact | **no** | **no** | applies to all BB and LP stems (col weights 3 / 3,5); not to TN, GB |
| **Stabilizer-overlap rule** supp(z) ∩ supp(g) <= wt(g)/2 | Lee 2026 (rule iv) | yes `overlap` (GH-138, with forbidding of the rest of a tight row; BB 0.20-0.47x nodes, LP Z halves 0.5-0.7x, TN 0.67-0.96x) | no (could be a learned-clause family) | monotone along branches; safe at every level; even-weight ties must not be cut |
| Block-grid / structured IP bound | Crocker lpcheck2 (LP) | no | no | LP only; TN analogue unpublished |
| Translation / orbit anchoring, earlier orbits forbidden | RD26 (two anchors), Crocker, Lee, dist-m4ri `start=` | yes `orbf` (GF(2)-verified per-half automorphisms, general not only translations) | orbit clauses (GH-85) | ours is more general |
| Canonicalisation under the point stabilizer (2nd-level symmetry) | RD26: named as future work | no | no | novel if done |
| X/Z duality (single-half search) | Bravyi lemma; Crocker App. B; Lee sector exchange | yes (verified dual map) | yes (GH-87/107) | - |
| Per-logical (lambda-odd) search / MILP per logical | Lee (v); CBCKF26; Bravyi ILP | no | no | useful only for small k |
| Hash lookup for the last qubit (syndrome == column) | dist-m4ri | **no** | n/a | 3-5x in dist-m4ri's plain CC |
| Rows sorted by weight (light rows first) | dist-m4ri | partly (`mrv`) | fewest unassigned | - |
| Parallel CC over start columns / first-level subtrees with a partition checker | dist-m4ri, Lee, RD26 README | **no** (single thread) | no | server policy: one core per process |
| Concurrent RW upper bound ("bracketing") | dist-m4ri method=3; Webster (exact + heuristic) | **no** (ub only from basis rows) | no (MaxSAT finds its own ub) | TN_252 hit-level problem |
| QDistEvol-style permutation evolution for ub | WJH26 | no | no | ub 34 on BB_756 |
| Witness verification by an independent GF(2) test | Crocker (three routines), Lee, ours | yes | yes | - |
| Machine-checkable lb certificate | Lean-QEC (n <= 144) | no | no (MaxCDCL has no proof logging) | out of reach at our n |
| Time-extrapolated round scheduling | dist-m4ri (growth clamped 2-10) | no (lockstep: cheaper half first) | no | minor |

---

## 4. Ranked, implementable ideas for DistQLDPC

Expected effects are estimated from the GH-124 S1 Tier-5 logs (per-level costs: BB_360 level 22 = 366 s, level
23 = 1159 s, level-24 hit = 6.6 s; BB_756 level 24 = 808 s, 25 = 2997 s, 26 = 7000 s, level 27 unfinished after
10 350 s (lb N in the log means level N-1 is complete);
TN_252 levels 18/19/20 = 540 / 1971 / 7305 s, growth ~3.5x; LP_1428 level 23 = 1909 s) and from the published
numbers above. "Novel" = not found in the literature read here.

### Rank 1 - Even-weight parity shortcut and parity bound (BB, LP halves with all-odd column weights)
- **Fact.** If every column of the half's parity matrix H has odd weight, then sum_i (Hv)_i = |v| (mod 2), so every
  vector of ker H - every logical and every stabilizer - has even weight. All BB stems (col weight 3) and all LP
  stems (col weights 3, 5) qualify (checked on all 49 bundled codes; TN and GB do not).
- **CC engine.** (a) Skip odd levels entirely, and after refuting an even level 2t report `d_lb = 2t+2`.
  (b) At every node: remaining budget b must satisfy b ≡ wt(s) (mod 2) (column weights all odd ⇒ each added qubit
  flips the syndrome parity); when the parity mismatches, raise every lower bound (pack, degree) by one. (c) The
  general form for mixed degrees: the number of odd-degree qubits in a kernel vector is even, i.e. the remaining set
  must contain ≡ wt(s) (mod 2) odd-degree qubits - weak for TN but free.
- **MaxSAT path.** Probe caps can skip odd values: refuting weight <= 2t already refutes <= 2t+1, so the final (most
  expensive) refutation at cap d-1 (d even) is replaced by cap d-2 (BB_288: refute 16 instead of 17). Optionally add
  the summed parity row as a redundant XOR (cheap for the solver).
- **Expected effect.** BB_360: 1706 s -> ~550 s (level 23 skipped, hit at 24 unchanged). LP_1428: 2884 -> ~980 s;
  LP_1054, LP_1768 similar (~3x). **BB_756 / 864 / 1080: lb 27 -> 28 at 11 250 s with no extra work, and the
  remaining ~10 000 s go into level 28 (needs ~6e4-1e5 s single-core at the observed 2.6-3.4x growth, so lb 30 only
  together with Rank 3/4/5).**
  MaxSAT path: ~2-3x on the proof part for BB/LP. TN: nothing.
- **Effort** low (1-2 days incl. mutation tests: a mutant that skips odd levels on a code with an even column weight
  must change an answer; test on GB_144 / BB_144_14_14 which have even column weights). **Risk** very low (theorem).
- **Novelty:** the fact is classical and Crocker uses it (release_bb360: "all X-logicals have even weight because
  each column of H_Z has weight 3"; cluster4's "parity bound"). Its use in the lockstep level schedule, the stop
  rule and the MaxSAT cap sequence is ours - an engineering contribution, not a publishable idea.

### Rank 2 - In-house randomized upper-bound witness finder (RW / QDistRnd-style, optionally QDistEvol) feeding the stop rule
- **What.** A GF(2) random-information-set search (random column permutation, elimination, dual-row candidates and
  pair sums, nontriviality by bitmask against the dual logical basis) run as a time-boxed pre-pass or a side thread
  inside DistQLDPC; every witness goes through the existing GF(2) verification; its weight becomes `d_ub`. Not an
  external solver: ~400-600 lines of our own code (dist-m4ri's M4RI trick is optional).
- **Why it matters for the hard cases.** TN_252: both halves refute level 20 at 10 045 s; the lockstep then spends
  > 11 500 s in level 21 trying to *find* the weight-21 X-witness. With a weight-21 witness already known, the stop
  rule gives d = 21 at ~10 050 s (2.8 h instead of 5-6 h). Same for every future "hit level" case. For BB_756 the ub
  drops from 52 to (very likely) 34 (Webster: QDistEvol finds 34; RIS 2 % per run, so give it minutes, or use the
  permutation-evolution variant); BB_864 / BB_1080 ub 108 / 66 -> realistic values; the TN `ge9` stems get an ub.
  Stems move from `geN` to `NtoM`.
- **Effort** medium (3-5 days). **Risk** low (witnesses are verified; wrong ub impossible; only the time budget is a
  tuning question). **Novelty:** published (dist-m4ri bracketing, QDistRnd, Webster's QDistEvol). Interacts with
  Rank 7 (low-weight dual logicals from the same search).

### Rank 3 - Stabilizer-overlap pruning (Lee 2026) plus overlap-derived forbidden qubits
- **Rule.** For the X half, every minimum-weight X-logical v satisfies |supp(v) ∩ supp(g)| <= wt(g)/2 for every row g
  of Hx (same-type stabilizer generator): otherwise v + g is a lighter representative of the same class. Along a
  branch the overlap only grows, so prune a node as soon as |T ∩ g| > floor(wt(g)/2) for some g. At level d all
  minimum-weight logicals survive (they all satisfy the rule); at levels < d nothing exists anyway; so the level
  verdicts stay exact and the first hit is still d. Automorphisms preserve rs(Hx), so `orbf` is unaffected.
- **Our addition (not in Lee):** when |T ∩ g| = floor(wt(g)/2), every remaining qubit of g becomes *forbidden*;
  feed those forbidden qubits into `pack` (fewer candidates per odd check -> more disjoint sets) and into the branch
  lists (smaller branching factor). For BB (wt 6) the cap is 3 qubits per X-check; for LP (wt 8) 4; for TN (wt 9) 4
  - TN clusters are locally dense (6-25 Tanner 4-cycles per row, GH-130), so the cap should bite early there.
  Low-weight stabilizers beyond the generators (e.g. weight-6 sums found by the Rank-2 search) can be added as extra
  rows g.
- **Expected effect.** No ablation exists in the literature. Guess: 1.3-2x on BB/LP, possibly 2-3x on TN refutations
  (the family where we need it most). Must be measured (GH-124-style per-level node counts, `-cc-stats`).
- **Effort** low-medium (per-row overlap counters, incremental; 2-3 days with tests). **Risk** low-medium: the only
  subtlety is the "exactly the level d" argument above; a mutant with cap floor(wt(g)/2) - 1 must prune witnesses
  and change answers at d (good mutation test). **Novelty:** rule published 5 Oct 2026 (Lee); the forbidden-qubit
  propagation into the packing bound is ours.

### Rank 4 - Leaf hash lookup and budget-2 meet (dist-m4ri's `smax=0` trick)
- **What.** Keep a hash set of the columns of H (as bitset hashes). At a node with budget 1 the syndrome s must
  equal one column that is still available (and in the branching row): one lookup instead of branching. At budget 2:
  for each candidate a of the chosen odd row test s ⊕ col(a) in the hash set (and availability), instead of
  descending. Leaves and depth-1 nodes are the majority of the tree (growth ~3x per level), so this cuts the
  per-node constant where it matters.
- **Expected effect** 1.3-2x on every family (dist-m4ri reports 3-5x on CSS codes for its plain CC, whose leaves are
  less pruned than ours). Combines multiplicatively with Rank 1 and 3. **Effort** low (1-2 days). **Risk** very low
  (pure implementation; brute-force tests exist). **Novelty:** published (dist-m4ri).

### Rank 5 - Parallel CC with a verified partition (seeds and first-level subtrees as work units)
- **What.** Orbit seeds are already independent (the forbidden earlier orbits are static); within a seed the
  first-level children with sibling exclusion are disjoint subtrees. Distribute (seed, first-level child) units over
  threads with an atomic counter (dist-m4ri), reduce node counts deterministically, and emit a *partition record*
  (unit list + per-unit node count + verdict) that an independent checker re-runs unit by unit (Lee's partition
  checker; also a cheap, replayable certificate matching the PI's cross-verification policy).
- **Expected effect** near-linear: BB_756 level 28 (~1e5 core-s) finishes in ~1.7 h on 16 cores -> **lb 30**; each
  TN refutation level costs ~3.5x, so 16 cores ≈ +2 levels within the same 6 h (TN stems lb 20-24 -> 22-26). Default
  stays single-threaded, so the tier timings and the one-core policy are untouched; multi-core would be a separate
  "certification mode" the PI has to allow on yfclab2 (current rule: one pinned core per process).
- **Effort** medium (4-6 days). **Risk** low for correctness (disjoint cover + checker), policy risk as noted.
  **Novelty:** published (dist-m4ri, Lee, RD26 README); the replayable partition certificate is a modest novelty.

### Rank 6 - Full automorphism discovery (Tanner-graph canonical labelling) and second-level canonicalisation
- **What.** Compute the automorphism group of each half's Tanner graph (nauty/bliss/Traces, Apache-2.0, or an own
  partition-refinement) instead of the GH-75 candidate family, verify each generator with the existing GF(2) checks,
  then (a) orbit seeds as now, and (b) under the point stabilizer of the seed, canonicalise the second qubit (one
  representative per orbit of the stabilizer on the seed's candidate set), recursively for depth <= 2.
- **Why.** TN codes (quantum Tanner codes on a left-right Cayley complex) carry the group G as automorphisms acting
  freely on squares (qubits), so |Aut| can be far larger than what the current family finds (orbit gain on TN is only
  2-3x vs 10-18x on BB/LP). A one-off nauty run on the TN matrices settles the potential before any engineering.
  For BB codes translations act freely, so (b) gains only where extra automorphisms (x <-> y swaps, inversions)
  exist; RD26 names "canonicalisation under a larger automorphism group" as the open problem.
- **Expected effect** on TN: between 1x and ~|Aut|/current-orbit-size (unknown until measured; could be 2-10x);
  BB/LP: small. **Effort** medium-high (nauty integration + depth-2 canonical form + tests). **Risk** medium (duplicate
  elimination must stay exact; depth-2 only to keep the overhead bounded). **Novelty:** orbit seeds are published;
  second-level canonicalisation in a CC distance search is not in the literature read here.

### Rank 7 - Per-logical ("lambda-odd") pseudo-check for small-k codes (TN_252 k=2, TN_1xx k=2, BB_864/1080 k=4)
- **What.** A nontrivial logical has odd overlap with some dual logical representative x_i. Run k searches (or
  k work units of Rank 5), each adding x_i as an *odd pseudo-check row* at the root (target parity 1): it joins the
  packing bound and the branching candidates from the start, and (where orbits are weak, i.e. TN) the seed set can
  be restricted to supp(x_i) with "earlier qubits of supp(x_i) forbidden". Use minimum-weight x_i (from Rank 2) so
  that the pseudo-row is short.
- **Expected effect** uncertain: 1-3x on TN_252-type codes, nothing on BB (orbits already leave 2 seeds). **Effort**
  medium. **Risk** medium (completeness argument per unit must be written down; exactness tests over all k units).
  **Novelty:** per-logical searches are published (Lee's lambda-odd variant, Bravyi/Cruz-Benito MILP per logical);
  using the dual row as a propagating odd check inside a cluster search is not described anywhere I found.

### Rank 8 - Structure-aware packing for TN (and LP): group odd checks by Tanner-code vertex / LP block
- **What.** In a quantum Tanner code every qubit (square) meets checks at exactly two X-check vertices; contract the
  odd checks of one vertex into one "odd vertex": remaining qubits >= ceil(#odd vertices / 2), and pack *vertices*
  with disjoint square-neighbourhoods. For LP codes, Crocker's block-grid IP bound. Both are detected structurally
  (row groups with identical candidate sets / block structure) and asserted before use, never from the code name.
- **Expected effect** speculative 1.2-2x on TN refutations (where `pack` is weakest because odd checks share
  candidates through 4-cycles). **Effort** medium. **Risk** medium (bound validity must be proven from the detected
  structure; per-node cost). **Novelty:** LP block-grid bound published (Crocker lpcheck2); the TN vertex-group bound
  is novel as far as I can tell.

### Not recommended now
- Brouwer-Zimmermann / information-set lower bounds (Hernando et al., Qubitserf bz, 5G modular BZ): K ~ n/2 gives
  ~1 bound unit per level; confirmed useless for qLDPC by CJL26 and our Qubitserf study.
- GPU cluster search: no prior art, high effort; the search is branchy and bitset-small; CPU parallelism (Rank 5)
  first.
- Proof logging: MaxCDCL has none; a VeriPB-emitting MaxSAT run would need a different solver; Lean-QEC stops at
  n ~ 144. The replayable partition record of Rank 5 is the practical substitute.
- MILP per logical / Gurobi: 10-100x slower than CC on BB/LP (CBCKF26, WJH26); Gurobi was the best exact method on
  TN in WJH26 (5/22 in 8 h) but still far behind our CC (TN_180 257 s, TN_216 696 s, lb 20-24 elsewhere).
- Algebraic BB bounds (SCM26, SRB25 cover bound): free but weak initial `d_lb` only.

### Suggested round order
Rank 1 + 4 together (both tiny, both exact by construction, both testable with the brute-force oracle), then
Rank 3 (measure on TN first), then Rank 2 (closes TN_252 and fixes the ub stems), then Rank 5 as a PI decision on
multi-core certification runs. Ranks 6-8 need a measurement step (automorphism group sizes; TN vertex structure)
before committing.

---

## 5. Sources (URLs)

- arXiv:2610.18130 https://arxiv.org/abs/2610.18130 ; arXiv:2610.06820 https://arxiv.org/html/2610.06820v1 ;
  arXiv:2610.06623 https://arxiv.org/abs/2610.06623 ; arXiv:2609.39395 https://arxiv.org/html/2609.39395v2 ;
  arXiv:2609.06572 https://arxiv.org/abs/2609.06572 ; arXiv:2608.27565 https://arxiv.org/abs/2608.27565 ;
  arXiv:2608.12509 https://arxiv.org/abs/2608.12509 ; arXiv:2608.09115 https://arxiv.org/abs/2608.09115 ;
  arXiv:2607.27644 https://arxiv.org/html/2607.27644v1 ; arXiv:2607.14091 https://arxiv.org/abs/2607.14091 ;
  arXiv:2607.28605 https://arxiv.org/html/2607.28605 ; arXiv:2607.04716 https://arxiv.org/abs/2607.04716 ;
  arXiv:2606.12445 https://arxiv.org/html/2606.12445v1 ; arXiv:2606.02418 https://arxiv.org/html/2606.02418 ;
  arXiv:2605.16523 https://arxiv.org/abs/2605.16523 ; arXiv:2603.28627 https://arxiv.org/abs/2603.28627 ;
  arXiv:2603.22532 https://arxiv.org/html/2603.22532v2 ; arXiv:2511.13560 https://arxiv.org/abs/2511.13560 ;
  arXiv:2509.21469 https://arxiv.org/abs/2509.21469 ; arXiv:2503.03827 https://arxiv.org/abs/2503.03827 ;
  arXiv:2408.10743 https://arxiv.org/html/2408.10743v2 ; arXiv:1611.07164 ; arXiv:1405.0348 ;
  arXiv:1302.1845 https://ar5iv.labs.arxiv.org/html/1302.1845 ; arXiv:2308.15140 ; arXiv:2308.07915.
- Zenodo: https://zenodo.org/records/23445463 ; https://zenodo.org/records/23352655 .
- Code: https://github.com/QEC-pages/dist-m4ri (GPL-2.0+) ; https://github.com/QEC-pages/QDistRnd (GPL) ;
  https://github.com/m-webster/codeDistancePYPI (MIT) ; https://github.com/mohammad-rowshan/BB-Codes-Distance-Logical-Decomposition (MIT) ;
  https://github.com/yeon-lee/public-regular-logical-frames (no license seen) ; https://github.com/Quantinuum/Qubitserf (MIT) ;
  https://github.com/unitaryfoundation/qldpc-challenge (Apache-2.0).
- Local: `ext/zenodo-23445463/unz/{README.md,NOVELTY.md,ZENODO_DESCRIPTION.txt,CHANGES_v1.1.md}`,
  `ext/zenodo-verify/cc_summary.txt`, `ext/QUBITSERF_REPORT.md`, `main-new/README.md`, `main-new/MODIFICATIONS.md`,
  `main-new/optimization/experiments/GH-124/S1_REPORT.md` and `S1/server/tier5/*.cc.log`,
  `main-new/optimization/experiments/GH-130/REPORT.md`.
