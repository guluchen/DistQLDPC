# GH-69 Tier0 result — local PASS (hosted cross-repo pending, see below)

Candidate src 40d875f; frozen binaries in `frozen-binaries.sha256` (re-verified after runs).
1. Build/smoke PASS, same warning count.
2. Check build (`-DLKSKIP_CHECK`): LP34/LP136/BB90/GB144/BB108/LP238 x OFF/MTO 12/12 clean, correct
   distances; via maxcdcl on Tier1 dumps: skipped visits BB90 102.2M / GB144 41.3M / BB108 90.4M /
   LP238 33.1M, reason checks 4.2–9.7M, no skipped clause ever used as lookahead reason/conflict,
   optima correct (`raw/tier0-check-01`). Deviation: the preregistered "all lookahead literals undone
   at lookahead exit" assertion was not implemented (exit paths legitimately keep real-level
   assignments); the reason/conflict assertions cover the soundness-relevant property.
3. Science sweep 50 codes x 4 modes, 60 s: 200/200 OK; 58 both-complete identical named distances,
   1 candidate-only completion (TN_200_10_10 sinz, d=10), none baseline-only, no unsound bound.
4. Exhaustive oracle (unit softs, GH-22 contract, seeds 800000+): base/cand/check 3000/3000 correct.
5. Hosted: ordinary CI SUCCESS. The PR conflicts with current main, so pull_request workflows did not
   run; the QDistSAT cross-repo workflow was dispatched on `ci/xrepo-gh69` = candidate source tree
   parented directly on baseline 24572d6 (so the workflow's HEAD^ baseline is the pinned baseline).
