# GH-78 Tier0 result: PASS (correctness only; no timing claims)

Candidate source `879bdcd` (branch experiment/gh-78-mac-xordecomp), baseline corrected source
`72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7`. Cross-repo branch `ci/xrepo-gh78` = `aa41b61` (one commit,
parent 72d1fe1, tree of 879bdcd). Draft PR #80, issue #78.

## Binaries (frozen outside build trees)
| host | role | path | SHA256 |
|---|---|---|---|
| Apple M6 Mac, Apple clang 21.0.0, `make -j2 CXX="c++ -Wno-reserved-user-defined-literal"` | candidate | scratch-2026-10-08-ce0ddb/frozen78/cand/distqldpc | 1bf025c2680eba4ca4c73ff481ef362493b0b165e7a2122b27bf62e37d163458 |
| Mac | baseline 72d1fe1 | scratch-2026-10-08-ce0ddb/frozen73n/base/distqldpc | 3f2fbc4215e17c4a5b5e62d1f10f99619bdf6efaea7881acb46157effe78c9dc |
| yfclab2, Linux 6.8.0-139, GCC 13.3.0, `make -j8` | candidate | ~/mac-agent-20261009/frozen/gh78/cand/distqldpc | 2a05756c3993a5354d343dbe437ee390f2dae8153da5ab22c6a279c9a850b390 |
| yfclab2 | baseline 72d1fe1 | ~/mac-agent-20261009/frozen/gh73n/base/distqldpc | b943c2c94d67574505112a06e1bb806aec378fbbc79e9edca4a1c5236283e00e |

## Gates (preregistered in PROPOSAL.md)
1. Mandatory regressions, both hosts: smoke PASS; `python3 -B scripts/test_partition_soft_literals.py` PASS
   (11 adjacent oracles); tests/test_partition_soft_literals.cc `GH58_PARTITION_ORACLE_PASS cases=80`.
   Mac build: 0 warnings. (raw/tier0/)
2. `-joint -v` stdout byte-identical to baseline `-v` on LP_34_20_2, TN_36_8_3, BB_72_12_6, on both hosts
   (raw/tier0/joint/ for the Mac). `git diff a1585b4 879bdcd -- src/solver` is empty (GH-73 hooks unchanged).
3. `-xordecomp-report` for all 50 codes (raw/reports/), re-verified by the independent Python checker
   `verify_xordecomp.py`: **ALL_OK** on both hosts; reports byte-identical between Mac and Linux
   (except plan_cpu). raw/verify_xordecomp.{txt,json}.
4. Science sweep (GH-60 tier0_science.py, server copy sha256 41ee9dfc..., unchanged GH-60 harness),
   50 codes x 4 modes, `--limit 60 --jobs 4` on yfclab2 (coordinator moved correctness work to the server;
   a Mac run with `--jobs 1` was stopped after its first baseline cell and is not used):
   **ALL_OK, problems 0**; both_done 52, only_cand_done 10, only_base_done 1. Every completed value equals
   the named distance and the completed baseline value; every emitted d_lb <= d <= every d_ub.
   Status differences (60 s wall cap on a shared host; correctness information, not timing):
   cand-only completions BB_144_12_12 card-sinz, LP_340_56_8 x4, TN_108_2_12 x3 (default, mto, sinz),
   TN_200_10_10 default/mto; baseline-only TN_200_10_10 no-card.
   Anytime LB: all 138 candidate timeouts emit a d_lb (both-timeout cells: final candidate LB higher in
   133/137, lower in 4/137; LB height is not a gate). raw/tier0-yfclab2/science/.
5. Cross-repo QDistSAT benchmark, run 37904438145 on ci/xrepo-gh78: scientific match **YES**.

## Per-code decomposition (r = spanning-set size, equal for X and Z halves in every code)
Decomposed (13/50): BB_72_12_6, BB_90_8_10, BB_108_8_10, BB_144_12_12, BB_288_12_unknown, BB_360_12_unknown,
BB_756_16_34, GB_144_12_8, GB_144_12_12 (r = 2); BB_144_14_14 (r = 3); BB_864_4_40, BB_1080_4_54, TN_216_4_18
(k = 4, r = 2). Generators: block cyclic shifts and 2D translations (4-13 verified per half).
Fallback OR: TN k=2 codes (r = k = 2), TN_324/360/396/468/540 (r = k = 4), other TN, all LP, PK_31, xu_30/42
(r > 4; LP cyclic lift alone needs >= 5 orbits under the greedy).

## Risks / limitations
- Search-changing formulation: performance unknown (Tier1/Tier2 by coordinator only). More parts => more
  probes in phase 1; single-XOR parts may also be harder individually than the OR half.
- Greedy spanning-set choice is heuristic (r may not be minimal); candidate permutation family is generic
  (GH-75) and can miss automorphisms (e.g. LP).
- `-no-xordecomp` is not byte-identical to GH-73 (driver generalised: phase 2 caps U-1).
