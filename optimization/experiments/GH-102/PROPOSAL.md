# GH-102 PROPOSAL — GH-89 + dual-map bound sharing (keep both halves, share LB via dX = dZ)

Issue: https://github.com/guluchen/DistQLDPC/issues/102. Hub: #15.
Agent: Mac implementation/Tier0 agent (correctness only; Tier1+ wall-time comparisons by the coordinator under
the timing lock). Branch `experiment/gh-102-dualmap-bound-sharing` from GH-89 candidate source `09d8bc2`
(= 72d1fe1 + GH-73 interleaved CSS split + GH-76 persistent/incremental half solvers + GH-85 per-half symmetry
breaking). Written and pushed before any code change.

## Motivation

GH-94 (= GH-89 + GH-87 dual-half elimination, source `d01a7e5`) beat GH-89 on dual-map codes (Tier1 vs GH-89:
BB_90 0.59/0.51, GB_144_12_8 0.45/0.42) but regressed BB_108_8_10 no-card 1.59x (GH-94 TIER1_RESULT.md). The
GH-89 trace on BB_108 no-card shows why: after both halves find weight 16 in Phase 1, the Phase-2a tie rounds let
the Z half find weight 12 under cap 13, the Z half then optimises from 12 to OPT 10 (proving "no weight <= 9"),
and the X half finally re-proves the same refutation (`X half cap 10 optimize -> OPT 10`). GH-94 drops the Z
half, so the X half alone descends 16 -> 14 -> 12 -> 10, and its UB=11 step needs ~4x the conflicts of GH-89's
Z-half step. The second half's value on this code is solution finding (an early, different incumbent), not
refutation. What GH-89 wastes on dual-map codes is the duplicated refutations: every Phase-1 NONE (caps 1, 2, 4,
8 on BB codes) and the final "no weight <= d-1" proof are done once per half.

## Hypothesis

When a verified XZ-dual permutation proves dX = dZ, keeping both halves in GH-89's interleaved global search but
sharing lower bounds removes the duplicated refutations while keeping the second half's solution finding. It
should keep most of GH-94's gain on BB_90 / GB_144 (whose GH-89 cost is dominated by duplicated NONE probes),
remove the BB_108 no-card regression (GH-89's trajectory minus the duplicate final proof), and equal GH-89
exactly on codes without a dual map (LP, PK, xu, most TN): detection only (milliseconds) and one report line.

## Mechanism

1. Dual-map detection exactly as GH-94 (`find_dual_maps`, GH-92 dedup `candidate_family(n, with_identity)`,
   ported verbatim from `d01a7e5`): a qubit permutation pi from the generic GH-75 family (identity first; none
   assumed) is accepted iff ranks match and every permuted row of Hz reduces to zero in an RREF basis of rs Hx
   and every permuted row of [Hz;Gx] reduces to zero in an RREF basis of rs [Hx;Gz] (GF(2), verified).
2. If a map is verified (`dualshare` on, both halves present), both halves stay in GH-89's driver (Phase 1
   doubling, Phase 2a tie rounds, Phase 2b optimise), with these changes only:
   * **LB sync:** after every half probe, L = max(lb_X, lb_Z) is written into both halves (`lb` is the proven
     "every solution of this half has weight >= lb"). The global LB min(lb_X, lb_Z) therefore becomes the max.
   * **Implied refutations are skipped:** the existing GH-89 skip tests already do this once lb is synced:
     Phase 1 skips a half with lb > m (a NONE at cap m in one half is a NONE at cap m in the other); Phase 2a/2b
     mark a half done when lb >= U. No new probe kinds and no new caps are introduced.
   * **UBs stay global** (U = best witness of either half, unchanged).
   * Pipe LB cap: under sharing a half's own proven LB is global, so the emitted-LB cap of Phase-2 probes is U
     (GH-89 caps it at the other half's lb as well). Reporting only.
   * Consistency guard: should a synced lb ever exceed U (impossible with a verified map) the driver returns
     UNKNOWN (`RESULT -1`), never a value.
3. Variant B (flag `-dualshare-b`, documented and kept off by default unless the work counts below argue
   otherwise): refutation (possibly-NONE) probes run on the leader half X only; the follower half Z only runs
   probes that are guaranteed to find a solution:
   * Phase 1 as in A (the follower probes cap m only after the leader found a solution of weight <= m there, so
     by pi the follower has one too).
   * Phase 2: loop while the leader is not done: leader probes cap U-1 first-only (NONE proves lb = U for both:
     finish); then, if the follower's incumbent is worse than U, the follower probes cap U first-only (a pi image
     of the incumbent exists, so this is FOUND, possibly with weight < U, which improves U). A follower NONE at
     cap >= U contradicts the map: UNKNOWN.
   Expected trade-off: B never lets the follower refute, but forces it to re-find weight <= U (hard near d) and
   gives up GH-89's Phase-2b continuous descent on the half with the better incumbent (on BB_108 GH-89's win came
   precisely from the Z half's descent). A is a strict sub-schedule of GH-89's probe kinds. **Default: A**; B selectable with `-dualshare-b` for the coordinator.
4. Flags: `-joint` (= main/72d1fe1 joint encoding), `-no-symbreak`, `-symbreak-report`, `-dualskip-report`
   (GH-94/GH-92 report mode, unchanged), new `-no-dualshare` (= GH-89 exactly: no detection, `-v`
   byte-identical to frozen89), new `-dualshare-b` (variant B), new `-dualshare-stats` (prints one work-count
   line `c dualshare stats: ...` at the end of the split driver in any mode, for informational work counts;
   off by default so `-no-dualshare -v` stays byte-identical).

## Soundness

* **Dual map => every half bound transfers.** Half X feasible set F_X = ker(Hz) \ ker([Hz;Gx]), half Z
  F_Z = ker(Hx) \ ker([Hx;Gz]). A verified pi with pi(rs Hz) = rs Hx and pi(rs [Hz;Gx]) = rs [Hx;Gz] preserves
  dot products, so pi(ker Hz) = ker Hx and pi(ker [Hz;Gx]) = ker [Hx;Gz], hence v -> pi v is a
  weight-preserving bijection F_X -> F_Z. For every w: F_X has an element of weight <= w iff F_Z has one. So
  every statement a probe proves about one half ("no solution of weight <= c", "lb = L") holds verbatim for the
  other, and dX = dZ.
* **Orbit clauses (GH-85).** Each half's orbit clauses S_X, S_Z come only from verified *plain* automorphisms
  of that half (never from the XZ-dual map) and preserve, for every w, the existence of a solution of weight
  <= w. Chain: (F_X u S_X has none <= c) <=> (F_X has none <= c) <=> (F_Z has none <= c) <=> (F_Z u S_Z has none
  <= c). So bounds proven on a symmetry-broken half instance transfer to the other symmetry-broken instance.
* **Shared LB fed to the engine.** `run_css_half` passes the half's `lb` as `knownLB` to `incProbe`, which
  raises `inc_inf` / `infeasibleUB`. The engine uses these only as proven lower bounds of the instance's optimum
  (early NONE when inc_inf > cap, OPT when inc_sup <= inc_inf, `infeasibleUB >= UB` stop after a solution of
  cost UB). A shared lb is a true lower bound of the instance's optimum by the two bullets above, so every
  engine answer stays exact. GH-89 already passes externally derived (previous-probe) lbs the same way.
* **Witnesses.** U always comes from a witness of one half re-checked by GH-76's `css_witness_ok`; the final
  answer d = U with lb_X = lb_Z = U proven (by the half that proved it, transferred by pi).

## GH-76 incremental contract

Contract (Solver::incProbe): before a half's first solution, caps may rise (fail-path reset between levels);
after it, the search target may only fall to at most the previous probe's ceiling (`inc_ceil`), otherwise
`INC_REBUILD` and a fresh identical instance. A: sharing adds no probe and no cap; it only (i) removes probes
whose answer is implied (Phase-1 NONE probes on a half without a solution, and the last probe of a half that is
then marked done), and (ii) raises `knownLB`. Removing a Phase-1 probe of a half that has no solution keeps that
half's caps rising (its next cap is the next doubling value). In Phase 2 a half marked done receives no later
probe, so no other half's cap sequence changes shape: each half's cap sequence is a subsequence of the one GH-89
would issue for the same U history, with the same rise/fall pattern. Raising knownLB changes no UB. GH-94's A1
(single-half cap U-1) is not needed: both halves remain, so no half is solved alone under a verified map.
B: the leader's Phase-2 caps are U-1 <= ub_X - 1 (falls after its first solution, target <= inc_sup <= inc_ceil);
the follower's Phase-2 cap U < ub_Z gives target capU+1 <= ub_Z - offs = inc_sup = inc_ceil (no raise). Any
unforeseen raise would still be caught by `incProbe` (`INC_REBUILD`, GH-76 rebuild path in `run_css_half`).

## Tier0 validation (preregistered; this agent; no timing claims)

1. Build `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"`, no new warnings in distqldpc.cc.
2. `scripts/smoke_test.sh`; `python3 -B scripts/test_partition_soft_literals.py`;
   `tests/test_partition_soft_literals.cc` oracle (`cases=80`).
3. GH-76 `tests/test_incremental_probes.cc` and GH-89 `tests/test_incremental_symbreak.cc` unchanged, 20000
   each, 0 failures (counts equal to GH-89/GH-94 records).
4. New `tests/test_incremental_dualshare.cc` (port of GH-94's dual-path oracle to the sharing path): production
   driver in a forked child, configurations {A, B, A without symbreak, -no-dualshare}; d = brute-force
   min(dX, dZ), every emitted LB <= d <= UB; 20000 instances, 0 failures. Mutants that must be caught: m1 shares
   bounds without a verified map (sharing whenever both halves exist); m2 shares lb+1 (off by one).
5. Trace identities `-v -cpu-lim=120` on BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, LP_34_20_2,
   BB_72_12_6, TN_36_8_4 x {no-card, card-mto, default}: `-no-dualshare` == frozen89 byte-identical; `-joint` ==
   main 7eadd54 `-joint` (and 72d1fe1); LP codes default == frozen89 except the `c dualshare:` report line;
   final `o` equal to the named distance everywhere.
6. Checkers `verify_half_autos.py` and `check_dual_maps.py` (from GH-94) ALL_PASS on the 50 codes;
   `-symbreak-report` / `-dualskip-report` identical to GH-94's binary (cpu fields masked).
7. Science sweep `tier0_science.py` (50 codes x 4 modes, 60 s, `--jobs 4`, every solver process under the
   2 GB cap via scratchpad/coord/memlimit.py) vs main 7eadd54 under the timing lock: zero unsound bounds, every
   completed value = named distance.
8. Cross-repo one-commit branch `ci/xrepo-gh102` (candidate tree, parent 72d1fe1) and the
   "QDistSAT cross-repo benchmark" workflow: scientific match YES.
9. Informational work counts (no timing claims): probes per half, conflicts per half, refutation probes skipped,
   on BB_108_8_10, BB_90_8_10, GB_144_12_8 (no-card, card-mto) for -no-dualshare (= GH-89), A, B.
Any unsound answer or identity failure that cannot be fixed soundly = FAIL, recorded honestly.
