# GH-78 preregistration: single-XOR decomposition of CSS halves via verified code automorphisms

Owner/session `mac-xordecomp-20261009` (Mac-host agent, independent). Issue
https://github.com/guluchen/DistQLDPC/issues/78 , hub #15. Baseline = corrected source
`72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (#62). Branch `experiment/gh-78-mac-xordecomp`.
Formulation change covered by the PI approval ("可以改", 2026-10-09, recorded in #71/#75).
Tier0 correctness only on this host (no timing); Tier1/Tier2 by the coordinator.

## Concept (GH-78-A, selected)
For a CSS code d = min(dX, dZ) (#71/#73). X half: dX = min{|x| : Hz x = 0, Gx x != 0}; Z half
uses (Hx, Gz). Per half (Hpar, Glog), R = rowspace(Hpar), T = span(Glog):
1. Candidate qubit permutations: the generic family published by #75 (bbe5055,
   `symmetry_candidates`: block shifts, strided shifts, 2D translations, half swaps with inverse),
   reused with credit. A candidate is kept iff every permuted row of Hpar reduces to zero
   against an echelon basis of R (GF(2); equal rank => sigma(R) = R).
2. Choose rows g_1..g_r of Glog greedily (max closure gain for k <= 64, otherwise in file
   order) until W = closure_A(R + span{g_i}) contains every Glog row; W is the smallest
   generator-invariant subspace, i.e. R + span of the A-orbits of the g_i (A finite).
   Containment is re-checked row by row at encode time.
3. Use the decomposition for the half iff r <= RMAX (= 4, `-xor-rmax=N`) and r < k; otherwise
   the half is one part with the existing OR formulation (GH-73 `build_css_half`).
4. Subproblem i: Hpar x = 0, XOR(g_i . x) = 1, soft -x_q (weight 1). No a_j, no OR clause.
Proof (both directions) is in the issue body: dX = min_i d(g_i) and every feasible point of a
subproblem is a nontrivial X logical, so every UB is valid and LB = min over parts is valid.

Driver (generalises GH-73's 2-half interleaved search to N parts, all subproblems of both halves):
- Phase 1, m = 1, 2, 4, ...: capped feasibility probe (stop at first solution, LB hidden) on every
  part without incumbent and with lb <= m; NONE => lb = m + 1; emit global LB = min part lb.
  Stop after the round in which any part found a solution (or m >= n).
- Phase 2: parts by (incumbent, index); a part with lb >= U is finished; otherwise optimise under
  strict cap U - 1 from its proven lb (found => U decreases; refuted => part >= U). Engine bounds
  are forwarded capped by LB <= min(U, other unfinished parts' lb), UB <= U.
- Result d = U, emitted as LB = UB = U, RESULT OPTIMAL. Unknown oracle result => RESULT UNKNOWN.
Engine hooks (initLB, strictUB, startAtCap, stopAtFirstSolution, boundsLbCap/UbCap/HideLB,
per-instance former statics) are taken unchanged from GH-73 a1585b4 (credit).
Flags: default on; `-joint` restores the baseline path (byte-identical); `-no-xordecomp` OR halves
in the same driver; `-xordecomp-report` prints per-half verified generators, r, chosen rows, and exits.

## Unselected
- GH-78-B: XZ-dual half elimination (verified sigma mapping Hx-space to Hz-space and the logical
  test spaces accordingly => dX = dZ, solve one half).
- GH-78-C: residual symmetry breaking (stabiliser of g_i) inside each subproblem; depends on A and #75.

## Tier0 (pass/fail rules fixed before running)
1. Build `make -j2 CXX="c++ -Wno-reserved-user-defined-literal"`; smoke `bash scripts/smoke_test.sh`;
   `python3 -B scripts/test_partition_soft_literals.py`; tests/test_partition_soft_literals.cc oracle
   (CI compile line). All must pass.
2. `-joint -v` stdout byte-identical to the frozen baseline `-v` on LP_34_20_2, TN_36_8_3, BB_72_12_6
   (MaxCDCL path with `-joint` must be unchanged).
3. `-xordecomp-report` for all 50 codes; an independent Python GF(2) checker
   (`verify_xordecomp.py`, int-bitset arithmetic, no code shared with the C++) re-verifies every
   reported generator (preserves rowspace(Hpar)) and the spanning claim, and recomputes r with
   the same rule. Any mismatch = FAIL.
4. GH-60 `tier0_science.py --limit 60 --jobs 1`, baseline = frozen 72d1fe1 binary
   (frozen73n/base/distqldpc), 50 codes x {default,no-card,card-mto,card-sinz}: completed values equal
   named distance and completed baseline value; every emitted d_lb <= d <= every d_ub. Any problem = STOP/REJECT.
5. Cross-repo QDistSAT benchmark on one-commit branch `ci/xrepo-gh78` parented on 72d1fe1;
   scientific match must be YES.
Per-code log: r_X, r_Z, generators used, decomposition/fallback. No timing claims.
