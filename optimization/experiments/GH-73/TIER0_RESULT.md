# GH-73 Tier0 result on corrected baseline 72d1fe1 — PASS

Candidate = 72d1fe1 + GH-73 delta (commit a1585b4; records up to the Tier1 launch record).
- Mandatory regressions (Mac clang and yfclab2 GCC 13.3, both base and candidate): smoke PASS;
  scripts/test_partition_soft_literals.py PASS (fixture optimum 5, 11 adjacent oracles);
  tests/test_partition_soft_literals.cc GH58_PARTITION_ORACLE_PASS cases=80.
- `-joint` byte-identical to baseline `-v` traces (BB90, LP238; Mac).
- Science sweep 50 codes x 4 modes, 60 s, on yfclab2 (Linux, GCC 13.3; base b943c2c9…, cand 8b522c08…;
  16 jobs; correctness only): **200/200 OK**, no unsound emitted bound. 52 both-complete identical named
  distances; 11 candidate-only completions (LP_340_56_8 all 4 modes 7.7–10.6 s; TN_108_2_12 x3; TN_200_10_10
  default/MTO/sinz; BB_144_12_12 sinz); 1 baseline-only (TN_200_10_10 no-card, base 35.9 s).
  Raw: raw/tier0-science-72d-yfclab2/. A partial Mac sweep (91/200 OK) was stopped when the server became
  available: raw/tier0-science-72d-mac-partial-stopped/.
- **Anytime lower bound restored** (GH-71's MAJOR): all 137 candidate timeouts emit d_lb; among 136 runs
  where both versions time out with an LB, the candidate's final LB is higher in 135 and lower in 1.
- Hosted QDistSAT cross-repo on ci/xrepo-gh73-72d (candidate tree parented on 72d1fe1): match YES.
- Independent code review: no blocker/major (REVIEW.md).
