# GH-87 PROPOSAL — dual-half elimination (dX = dZ via a verified XZ-dual map) in the interleaved CSS split

Issue: https://github.com/guluchen/DistQLDPC/issues/87 (three proposals, selection A).
Agent/session: `mac-dualskip-20261009` (Mac host; Tier0 correctness only, no timing).
Baseline: corrected source `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (#62).
Branch: `experiment/gh-87-mac-dualskip` (from 72d1fe1). Hub registration:
https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6079727234.
Written before any implementation.

## Status: registered extension of GH-73

GH-73 (#73, interleaved CSS split with global bound search, source `a1585b4`; Tier1 OFF
0.485 / MTO 0.498, Tier2 LP340 25.6x / 17.6x on 72d1fe1) is cherry-picked unchanged and
credited. Exactly one new concept is added: eliminating one half when a verified XZ-dual
permutation proves dX = dZ. The gate comparison is **vs the corrected baseline 72d1fe1**;
comparison with GH-73 (`-no-dualskip`, byte-identical to a1585b4 by construction) is
informational, for attribution. Per-half symmetry breaking (GH-85) is **not** included.
PI approval for formulation changes: 2026-10-09 (#71). Source of the idea: unselected
proposal GH-78-B (#78, "XZ-dual half elimination"); detection code (candidate family,
GF(2) RREF verifier) reused from GH-75 `bbe5055` / GH-85 `cc7e5ea` with credit.

## Mechanism (selected GH-87-A)

1. Cherry-pick GH-73 `a1585b4` onto 72d1fe1 unchanged.
2. In `min_distance_css_interleaved`, before the first oracle call and only when both
   halves have logical rows (Gx, Gz nonempty): compute RREF bases of rs Hx and of
   rs [Hx; Gz]; require rank(Hz) = rank(Hx) and rank([Hz;Gx]) = rank([Hx;Gz]); test the
   candidates in a fixed order — identity first, then the GH-75 generic family
   (block/strided cyclic shifts, 2D translations, half swap, half swap with group inverse
   for 1D/2D groups) — and accept the first pi with pi(row) in rs Hx for every Hz row and
   pi(row) in rs [Hx;Gz] for every row of [Hz;Gx].
3. If a map is accepted, the Z half is marked eliminated (treated like an absent half by
   the driver): GH-73's doubling probes, (now vacuous) tie-break rounds and capped
   optimisation run on the X half only; the anytime global LB is the X half's proven LB,
   the UB the X half's best weight, the final d = dX. No change to the engine.
4. If no map is accepted (or a half has no logical rows), behaviour is exactly GH-73.
5. Flags: default on in the split path; `-no-dualskip` = GH-73 exactly (no detection,
   no extra output); `-dualskip-report` prints, per code, ranks, the number of candidates,
   every verified dual map (the first is the one used) and detection CPU, then exits;
   `-v` prints one `c dualskip:` line. `-joint`, dumps and RoundingSat untouched.

## Soundness argument

GH-73 half instances: F_X = ker(Hz) \ ker([Hz;Gx]), F_Z = ker(Hx) \ ker([Hx;Gz]); the soft
unit literals count Hamming weight, d = min(dX, dZ) (#71/#73).
For a permutation pi, <pi a, pi b> = <a, b>. If rs B = pi(rs A) then
ker B = {w : <pi a, w> = 0 for all a in rs A} = {w : <a, pi^-1 w> = 0} = pi(ker A).
Inclusion of the permuted rows in rs B plus rank(A) = rank(B) gives rs B = pi(rs A)
(permutation preserves rank). With A = Hz, B = Hx and A = [Hz;Gx], B = [Hx;Gz]:
pi(ker Hz) = ker Hx and pi(ker [Hz;Gx]) = ker [Hx;Gz], so v -> pi v is a bijection
F_X -> F_Z with |pi v| = |v|. Hence dX = dZ, F_X empty iff F_Z empty, and d = dX.
Therefore every LB proven for the X half alone (no X logical of weight < lb) is a global
LB, every X solution is a nontrivial logical (global UB), and the final value is d.
Timeouts: the anytime LB/UB stream keeps GH-73's semantics (only proven global bounds).

## Expected per-code findings (to be measured, not assumed)

GH-75 found XZ-dual maps for all 10 BB codes and GB_144_12_8 / GB_144_12_12 (half swap +
group inverse) and TN_36_8_4 (XZ-dual block maps) under its stronger four-space condition;
the two-space half condition admits at least these. LP / PK / xu / most TN: probably none
in the generic family (then identical to GH-73). Recorded for all 50 codes and re-verified.
Expected effect: on codes with a map, GH-73's halves tie and both are probed/optimised;
eliminating Z removes that duplicated work (up to ~2x fewer oracle calls); no effect
elsewhere apart from microseconds-to-milliseconds detection.

## Risks

* A wrong accepted map would give a wrong d if dZ < dX: mitigated by the exact GF(2)
  checks and an independent Python verifier of every reported map (and of the absence of
  maps for the other codes, by re-enumerating the family).
* Search-path change: the X half's searches themselves are unchanged (same instance, same
  order of probes until a UB), but the global UB caps passed to the Z half disappear;
  per-code effects may be uneven (GH-73 sometimes finished a half early via the other
  half's UB). Timing is for the coordinator only.
* Detection cost: O(#candidates x rows x rank x n/64) word operations; GH-75/85 measured
  <= 0.03 s CPU on the largest code.

## Tier0 validation (preregistered; this agent)

1. Mac build `make -j2 CXX="c++ -Wno-reserved-user-defined-literal"` (no new warnings in
   `distqldpc.cc`); Linux GCC 13.3 build on yfclab2; `scripts/smoke_test.sh` on both.
2. Mandatory regressions: `python3 -B scripts/test_partition_soft_literals.py`;
   `tests/test_partition_soft_literals.cc` oracle (compile line from `.github/workflows/ci.yml`).
3. `-joint -v` traces byte-identical to 72d1fe1 `-v` (LP_34_20_2, BB_72_12_6, TN_36_8_4;
   default and `-no-card`).
4. `-no-dualskip -v` traces byte-identical to GH-73 a1585b4 default `-v` (same cases).
5. Default vs `-no-dualskip` on codes without a dual map: identical modulo the
   `c dualskip:` line.
6. `-dualskip-report` for all 50 codes; independent Python GF(2) checker
   (`check_dual_maps.py`): rebuild every reported map from its description, check it is a
   permutation, check ranks and both row-space equalities with its own elimination;
   re-enumerate the whole candidate family and require the accepted set to equal the
   reported set for every code.
7. Science sweep on yfclab2: unmodified GH-60 harness copy `tier0_science.py`, 50 codes x
   {default, no-card, card-mto, card-sinz}, 60 s, `--jobs` <= 4 (<= 8 solver processes,
   only with idle > 60 %), baseline `~/mac-agent-20261009/frozen/gh73n/base/distqldpc`
   (72d1fe1). PASS iff every completed distance equals the named distance and the
   baseline value, every emitted d_lb <= d <= every emitted d_ub, and every candidate
   timeout emits an LB. TN_648_10_71's name is known to be wrong (true d <= 52, PI
   escalation): any value there is reported, not "fixed".
8. Hosted CI + QDistSAT cross-repo benchmark on one-commit branch `ci/xrepo-gh87`
   (candidate tree, parent 72d1fe1); scientific match required.

Stop after Tier0 + cross-repo. Freeze a read-only Mac candidate binary outside build trees
for the coordinator (Tier1/Tier2 timing vs 72d1fe1; GH-73 informational).
