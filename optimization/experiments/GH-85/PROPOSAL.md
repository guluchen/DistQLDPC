# GH-85 PROPOSAL — symmetry breaking inside interleaved CSS halves (GH-73 x GH-75 interaction)

Issue: https://github.com/guluchen/DistQLDPC/issues/85 (three proposals, selection A).
Agent/session: `mac-split-symbreak-20261009` (Mac host; Tier0 correctness only, no timing).
Baseline: corrected source `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (#62).
Branch: `experiment/gh-85-mac-split-symbreak` (from 72d1fe1).
Written before any implementation.

## Status: preregistered interaction experiment

The protocol forbids combining successful ideas without a separate interaction experiment.
This record registers the combination of GH-73 (interleaved CSS split, source `a1585b4`,
Tier1 OFF 0.485 / MTO 0.498, Tier2 LP340 25.6x / 17.6x on 72d1fe1) and GH-75 (code-
automorphism orbit symmetry breaking on the joint encoding, source `bbe5055`, Tier0 PASS).
The gate comparison is **vs the corrected baseline 72d1fe1**. Comparisons with GH-73 alone
(`-no-symbreak`, also byte-identical to a1585b4 by construction) are informational, for
attributing the interaction. PI approval for formulation/encoding changes: "可以改",
2026-10-09 (#71/#75).

## Mechanism (selected GH-85-A)

1. Cherry-pick GH-73 `a1585b4` onto 72d1fe1 unchanged (driver, `build_css_half`,
   `run_css_half`, engine hooks initLB/strictUB/startAtCap/stopAtFirstSolution, bound
   caps, per-instance former statics). Credit: GH-73.
2. Reuse GH-75's generic candidate permutation family (block/strided cyclic shifts, 2D
   translations, block swaps, half swap with group inverse) and GF(2) RREF verifier.
   Credit: GH-75.
3. For each half (X: Hpar = Hz, Glog = Gx; Z: Hpar = Hx, Glog = Gz) keep a candidate pi
   iff pi(rs Hpar) is contained in rs Hpar and pi(rs [Hpar; Glog]) is contained in
   rs [Hpar; Glog] (each permuted row reduces to zero; a permutation preserves rank so
   containment is equality). Plain maps only; XZ-dual maps are not considered.
4. Union-find orbits of the generated group on qubits, computed once per half (cached in
   the half record). In every `build_css_half` oracle instance of that half add the
   GH-75 orbit clauses on the half variables v: (v_{r_1} v ... v v_{r_k}) and, for
   1 < k < n, the orbit chain with k-1 prefix aux vars p_j <-> (supp meets O_1..O_j):
   p_j -> p_{j-1} v OR_{q in O_j} v_q; p_{j-1} -> p_j; v_q -> p_j (q in O_j);
   (-v_q v v_{r_j} v p_{j-1}) for q in O_j \ {r_j} (p_0 = false). k = 1: unit v_{r_1}.
   k = n: nothing.
5. Flags: default on in the split path; `-no-symbreak` = GH-73 split exactly;
   `-symbreak-report` prints per-half generators/orbits and exits; `-v` logs them.
   `-joint` path untouched (byte-identical to baseline; **no** joint symmetry clause),
   dumps and RoundingSat untouched.

## Soundness argument

F_half = ker(Hpar) \ ker([Hpar; Glog]) (nonzero follows from the nontriviality test).
A permutation preserves the dot product, so pi(rs M) = rs M implies pi(ker M) = ker M. A
verified pi therefore maps F_half onto F_half and preserves |v|; so does every element of
the generated group G. Orbits O_j are G-invariant. For feasible v, let j* be the first
orbit met by supp v and g in G move some q in supp v n O_j* to r_j*: g v is feasible,
|g v| = |v|, r_j* in supp(g v), supp(g v) misses O_1..O_{j*-1}; with p_j set to its
defining value it satisfies every added clause. Hence for every w: "exists feasible v with
|v| <= w" is unchanged, and every constrained solution is an unconstrained one. Every
GH-73 oracle call asks exactly such a capped existence/optimisation question (doubling
feasibility probes, tie-break probes at cap U-1, capped optimisation from a proven LB),
so FOUND/NONE/OPT, per-half LB/UB, all emitted global d_lb/d_ub and the final d are
unchanged in value and soundness. Per-half initLB = proven half LB remains valid.

XZ-dual maps send X-half solutions to Z-half solutions; they are not automorphisms of a
single half and are not used. Using them to prove dX = dZ and skip a half would be a
separate concept (GH-85-B / GH-78-B) and is excluded here.

## Expected per-code structure (to be measured, not assumed)

The half condition is weaker than GH-75's plain joint condition (only two of the four row
spaces), so G_half contains GH-75's plain group restricted to the half but not its dual
maps. Expected: BB/GB halves 2 orbits (block translations only) instead of GH-75's
transitive group, unless a plain block swap verifies; LP/PK/xu block-cyclic orbits as in
GH-75; TN layout dependent. Recorded for all 50 codes per half.

## Tier0 validation (preregistered; this agent)

1. Mac build `make -j2 CXX="c++ -Wno-reserved-user-defined-literal"` (no new warnings in
   `distqldpc.cc`); Linux GCC 13.3 build on yfclab2; `scripts/smoke_test.sh`.
2. Mandatory regressions: `python3 -B scripts/test_partition_soft_literals.py`;
   `tests/test_partition_soft_literals.cc` oracle (compile line from `.github/workflows/ci.yml`).
3. `-joint -v` traces byte-identical to the 72d1fe1 baseline `-v` traces (LP_34_20_2,
   BB_72_12_6, TN_36_8_4; default and `-no-card`).
4. `-no-symbreak -v` traces byte-identical to GH-73 a1585b4 default `-v` traces (same
   cases) — attribution control.
5. Per-half orbit report for all 50 codes (`-symbreak-report`), every kept permutation
   independently rebuilt from its description and re-verified by a Python-int GF(2)
   checker against the half conditions; orbit counts and representatives recomputed and
   compared. Any failure = REJECT.
6. Science sweep on yfclab2 (correctness only), GH-60 `tier0_science.py`, 50 codes x
   {default, no-card, card-mto, card-sinz}, 60 s, vs frozen baseline
   `~/mac-agent-20261009/frozen/gh73n/base/distqldpc` (72d1fe1): completed candidate
   values equal named and baseline completed values; every emitted d_lb <= d <= every
   emitted d_ub; plus a post-hoc check that **every candidate timeout emits at least one
   d_lb** (GH-73's anytime-LB property). Any violation = REJECT and escalate.
   Known data issue: TN_648_10_71 matrices contain logicals lighter than the named 71
   (hub PI escalation 2026-10-09); a d_ub < 71 there is reported, not blamed on the
   candidate, if the baseline shows the same.
7. QDistSAT cross-repo benchmark on one-commit branch `ci/xrepo-gh85` (candidate tree,
   parent 72d1fe1); scientific match must be YES.
8. Freeze the Mac candidate binary read-only outside build trees, with SHA256, for the
   coordinator's Tier1/Tier2 (vs 72d1fe1; GH-73 informational). No timing by this agent.
