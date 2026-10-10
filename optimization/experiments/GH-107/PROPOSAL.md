# GH-107 PROPOSAL — dual-map bound sharing on main's interleaved split (no incremental solver)

Issue: https://github.com/guluchen/DistQLDPC/issues/107. Hub: #15.
Agent: Mac implementation/Tier0 agent (correctness only; wall-time comparisons by the coordinator under the
timing lock). Branch `experiment/gh-107-dualshare-noinc` from GH-92 candidate source `e226951`
(= main 7eadd54's interleaved CSS split with GH-85 per-half symmetry breaking, a fresh solver per probe, plus GH-87
dual-half elimination with A1). Written and pushed before any code change.

## Motivation

* GH-92 (main + dual-half elimination: X half only under a verified dual map) won on BB_144_12_12 / BB_144_14_14 /
  GB_144_12_12 card-mto (0.46-0.65 vs main) but GB_144_12_12 no-card was 1.95x slower: there the X half is much
  harder than the Z half, and elimination always keeps X.
* GH-102 (GH-89 incremental solver + both halves + shared LBs) kept the Z half's solution finding, but regressed
  GB_144_12_12 card-mto (1.34x) and inherits GH-89's incremental-solver regressions on non-dual codes.
* Main itself, on dual-map codes, duplicates every refutation: each Phase-1 NONE (caps 1, 2, 4, ...) and the final
  "no weight <= d-1" proof are done once per half.

## Hypothesis

Main's interleaved split (fresh solver per probe, no GH-76 incremental solver) with both halves racing exactly as in
main, plus bound sharing under a verified XZ-dual map, keeps most of the dual-map gains (duplicated refutations are
skipped) while avoiding the hard-half penalty (the easier half can still find the incumbent / do the final proof)
and avoiding GH-102's incremental trajectory effects. Codes without a verified dual map run main's search exactly
(detection only, milliseconds, plus one `-v` report line).

## Mechanism (flag `-dualmode=share|skip|off`)

1. Dual-map detection = GH-92's `find_dual_maps` (identity + generic GH-75 family, `candidate_family(n, true)`,
   GF(2)-verified: equal ranks; every permuted row of Hz lies in rs Hx and every permuted row of [Hz;Gx] lies in
   rs [Hx;Gz]). Unchanged code.
2. `-dualmode=share` (new default). If a map is verified (both halves present), both halves stay in main's driver
   (Phase 1 doubling, Phase 2a tie rounds, Phase 2b optimise in incumbent order, cap U, fresh solver per probe).
   Changes, ported from GH-102 variant A (69f91c1):
   * **LB sync:** after every half probe, L = max(lb_X, lb_Z) is written into both halves (`lb` = proven "every
     solution of this half has weight >= lb"; it is the fresh solver's `initLB`).
   * **Implied refutations skipped** by main's own skip tests once lb is synced: Phase 1 skips a half with
     lb > m (a NONE at cap m in one half is a NONE at cap m in the other); Phase 2a/2b mark a half done when
     lb >= U (in particular the second half's final optimise after the first half's OPT). No new probe kind and no
     new cap: each half's probe sequence is a subsequence of main's for the same U history.
   * **UBs stay global** (U = best witness of either half, as in main).
   * Emitted-LB cap of Phase-2 probes: under sharing a half's proven LB is global, so the cap is U (main caps it at
     the other unfinished half's lb as well). Reporting only.
   * **Guard:** a synced lb above U (impossible under a verified map) makes the driver refuse to answer
     (`RESULT -1` UNKNOWN), never a value.
   * GH-87 A1 (cap U-1 for a half holding the incumbent) is *not* used in share mode: main's schedule is kept.
3. `-dualmode=skip` = GH-92 exactly (X half only under a verified map, A1). `-dualmode=off` = main 7eadd54 / GH-85
   search exactly: no detection, no extra output (`-v` byte-identical to frozen-main7e). The GH-92 flag
   `-no-dualskip` stays as an alias of `-dualmode=off`; `-dualskip-report` unchanged.
4. `-dualshare-stats` (informational, with any mode, off by default): one final `c dualshare stats:` line with probes
   per half, engine conflicts per half, implied skips. Since `-dualmode=off` and `-dualmode=skip` run main's and
   GH-92's searches exactly, their stats lines are main's and GH-92's work counts.

## Soundness

* **Verified pi => dX = dZ, and every half bound is global.** F_X = ker(Hz) \ ker([Hz;Gx]),
  F_Z = ker(Hx) \ ker([Hx;Gz]). A verified pi with pi(rs Hz) = rs Hx and pi(rs [Hz;Gx]) = rs [Hx;Gz] preserves dot
  products, so pi(ker Hz) = ker Hx and pi(ker [Hz;Gx]) = ker [Hx;Gz]; v -> pi v is a weight-preserving bijection
  F_X -> F_Z. Hence for every w, F_X has an element of weight <= w iff F_Z has one: a NONE at cap c proven in one
  half is a NONE at cap c in the other, any proven half LB is an LB of the other half, and dX = dZ = d. So the
  shared lb max(lb_X, lb_Z) is a true lower bound of d and of both half optima.
* **Orbit clauses (GH-85).** Each half's orbit clauses come only from verified plain automorphisms of that half
  (never from the dual map) and preserve, for every w, the existence of a half solution of weight <= w. Chain:
  (F_X + S_X none <= c) <=> (F_X none <= c) <=> (F_Z none <= c) <=> (F_Z + S_Z none <= c). Bounds proven on one
  symmetry-broken instance transfer to the other.
* **Shared LB in the engine.** The fresh half solver receives the half's lb as `initLB` (main already passes the
  half's own previous lb the same way). The engine uses it only as a proven lower bound of the instance optimum;
  since the shared lb is one (above), every FOUND/NONE/OPT answer stays exact.
* **Skipped probes** are exactly those whose answer is implied (NONE at cap m when lb > m; a half is finished when
  lb >= U because it cannot beat U). Witnesses: U always comes from a half solver's solution, d = U with lb = U
  proven by the half that proved it and transferred by pi.
* Without a verified map nothing is shared (mode share degrades to main's search).

## Tier0 validation (preregistered; this agent; no timing claims)

1. Build `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"`, no new warnings in distqldpc.cc.
2. `scripts/smoke_test.sh`; `python3 -B scripts/test_partition_soft_literals.py`; GH58 oracle (`cases=80`).
3. New `tests/test_split_dualshare.cc` (adaptation of GH-102's `test_incremental_dualshare.cc` / GH-94's
   `test_incremental_dualskip.cc` to the non-incremental driver): production driver in a forked child with the
   production bounds pipe; configurations {share, skip, share without symbreak, off}; d = brute-force min(dX, dZ),
   every emitted LB <= d <= UB, sharing/skip reported iff a map is verified; 20000 instances, 0 failures. Mutants
   that must be caught: m1 sharing without a verified map, m2 shared lb + 1.
4. Trace identities `-v -cpu-lim=120` on BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, LP_34_20_2, BB_72_12_6,
   TN_36_8_4 x {no-card, card-mto, default}: `-dualmode=off` == frozen-main7e byte-identical; `-dualmode=skip` ==
   frozen92; `-joint` == main `-joint`; LP/TN codes without a map: default == main except the one dual report line;
   final `o` = named distance everywhere.
5. Checkers `verify_half_autos.py` and `check_dual_maps.py` ALL_PASS (50 codes).
6. Science sweep (GH-102's `tier0_science.py`, 50 codes x 4 modes, 60 s, `--jobs 4`, 2 GB cap via memlimit) vs main
   7eadd54 under the Mac timing lock: zero unsound bounds, every completed value = named distance.
7. Cross-repo one-commit branch `ci/xrepo-gh107` (candidate tree, parent 72d1fe1) + "QDistSAT cross-repo
   benchmark" workflow: scientific match YES.
8. Informational work counts (no timing): per-half probes, implied skips, conflicts on BB_90_8_10, BB_108_8_10,
   GB_144_12_8 (and GB_144_12_12 with cpu-lim 300), share vs off (= main) vs skip (= GH-92).
Any unsound answer or identity failure that cannot be fixed soundly = FAIL, recorded honestly.
