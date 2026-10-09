# GH-79 proposal — implied conjugate-coset clauses (mac-conjclauses-20261009)

Issue: https://github.com/guluchen/DistQLDPC/issues/79 (hub #15 registration
https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6077123404).
Baseline: corrected source `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (#62).
Branch: `experiment/gh-79-mac-conjclauses`. Written before implementation.

PI approval: encoding/formulation changes approved by the user/PI on 2026-10-09
(recorded in #71). This change adds only *implied* hard clauses; the optimum,
the distance definition, Pauli weight, logical-operator semantics, bound
interpretation, timeout handling and output format are unchanged.

## Hypothesis (GH-79-A, selected)

In `build_stabilizer_instance`, the X side defines `a_j <-> Gx_j . x` with
`Hz x = 0` hard. For every `h` in rowspace(Hz), `h . x = 0`, so for every
`u` in `Gx_j + rowspace(Hz)`, `u . x = a_j`; hence `(-a_j v OR_{i in supp u} x_i)`
is implied. Symmetrically for the Z side with `Gz_j + rowspace(Hx)` and z.
MaxCDCL lower bounds are disjoint UP-inconsistent soft subsets; under `a_j = 1`
the existing XOR chain already acts as one core of size |Gx_j|, and every
additional verified representative is another ready-made core (pairwise-disjoint
ones are additive). The bundled logical rows are often much heavier than the
lightest representative. Prediction: stronger lookahead LBs in `a_j = 1`
subtrees -> fewer nodes; benefit largest where several disjoint light reps exist
(BB_90, BB_108, BB_144_12_12, GB_144_12_8, TN_144); possible slowdown from extra
propagation in lookahead (~70% of runtime).

## Intended change (one concept)

`src/core/distqldpc.cc` only (application layer, no `src/solver/` change):

1. New `add_conjugate_coset_clauses` (called from `build_stabilizer_instance`
   right after the global `OR_j a_j` clause, MaxCDCL solve path only).
2. Per side (X: G = Gx, H = Hz, vars x; Z: G = Gz, H = Hx, vars z), with 64-bit
   word bitsets: an exact echelon basis of rowspace(H) (natural pivot order) for
   verification; T deterministic information-set permutations (splitmix64,
   fixed seed, own Fisher–Yates; T = clamp(budget / cost, 4, 32), budget fixed)
   giving a pivot-reduced coset representative per row, then greedy descent by
   single H rows while weight decreases; the original row is also descended.
3. Every candidate u is verified: `reduce(u xor g, exact basis) == 0`; failing
   candidates are dropped and counted (expected 0).
4. Selection per row: candidates of weight <= 2 * wmin, sorted (weight, words);
   greedy pairwise-disjoint packing first, then the lightest remaining; the
   original row g itself is excluded (its XOR chain already enforces it); at most
   4 clauses per row. Rows that are empty are skipped (a_j already forced false).
5. Clause `(-a_j v OR_{i in supp u} v_i)` added as a hard clause.
6. `-no-conj` CLI flag restores the baseline instance exactly. `-dump-only`
   (WCNF/OPB dumps) and the RoundingSat path build the baseline instance.
   `-dump-wcnf` combined with a MaxCDCL solve dumps the instance being solved
   (with the implied clauses), as before.
7. With `-v`, one `c conj-clauses:` summary line (counts, weights, verify failures).

Bounded size: <= 4 * (|Gx| + |Gz|) clauses of length <= 2*wmin+1.

## Offline evidence (pure linear algebra, see offline/)

`offline/conj_offline.py` (Python, 400 permutations, n <= 400; `offline/*.json`).
Key results are in issue #79. Lighter reps exist for most codes (LP_340 max row
78 -> 56; GB_144_12_12 median 36 -> 21); only 1–5 pairwise-disjoint reps per
row; the union of best reps over all rows is a single root-level hitting set
(greedy found exactly one disjoint union per code) -> attaching to the global
OR gives root LB <= 1; attach to a_j instead.

## Unselected proposals

- GH-79-B: global-OR erasure hitting-set clauses `OR_{i in S} w_i` — offline
  predicts root LB <= 1; documented negative prediction.
- GH-79-C: replace each logical row by its lightest verified coset rep in the
  XOR definition of a_j (same semantics, shorter chains) — separate follow-up.

## Correctness risk and Tier0 plan (preregistered)

Risk: an unverified/incorrect u would add a non-implied clause and could raise
the optimum (unsound). Mitigation: construction is g + rows of H by design and
every u is re-verified by exact reduction; the science sweep compares against
named distances and the frozen baseline. Determinism: own PRNG/shuffle.

Tier0 (correctness only, no timing comparison):
- build `make -j2 CXX="c++ -Wno-reserved-user-defined-literal"` (clean build);
- `bash scripts/smoke_test.sh`; `python3 -B scripts/test_partition_soft_literals.py`;
  tests/test_partition_soft_literals.cc oracle with the CI compile line;
- in-binary verify-failure count 0 on all bundled codes (`-v`, `-cpu-lim=1`);
- `-no-conj` instance identical to baseline (`-dump-wcnf` byte compare on small codes);
- science sweep: GH-60 `tier0_science.py --limit 60 --jobs 1` (copy with a
  TIMING_LOCK/load-average guard before each solver run), baseline = frozen
  72d1fe1 binary; every completed value equals named and baseline values; every
  emitted d_lb <= d <= every emitted d_ub; any mismatch => REJECT + PI escalation;
- QDistSAT cross-repo dispatch on one-commit `ci/xrepo-gh79` (parent 72d1fe1).
Tier1/Tier2 timing: coordinator only (frozen candidate binary + SHA256 provided).
