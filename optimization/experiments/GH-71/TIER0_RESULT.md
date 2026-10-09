# GH-71 Tier0 result — PASS (local + hosted)

Candidate src 6805148 (CSS X/Z split, PI-approved), frozen c89b243c…; baseline ac43af52….
1. Build/smoke PASS, same warning count. `-joint` reproduces the baseline `-v` trace byte-identically
   (BB90 OFF), so the original path is preserved.
2. Spot checks: LP34/LP136/BB90/GB144/BB108/LP238 x OFF/MTO correct; -v shows per-half dX, dZ and min.
   Diagnostic WCNF check before implementation: min(dX,dZ) = named d on 8 small codes.
3. Science sweep 50 codes x 4 modes, 60 s: 200/200 OK, no unsound emitted bound anywhere.
   56 both-complete with identical named distances; 6 candidate-only completions (LP_340_56_8 all 4
   modes 17–52 s, d=8; LP_442_68_10 default/MTO 43 s, d=10); **2 baseline-only completions**
   (TN_200_10_10 default and card-mto: baseline ~12 s, candidate > 60 s). Informational (4-way
   parallel, not evidence): median-ratio geomean 0.465 over 28 both-complete runs > 0.5 s.
4. Hosted: CI SUCCESS; QDistSAT cross-repo dispatched on `ci/xrepo-gh71` (candidate tree parented on
   24572d6): scientific match YES (LP136/BB108 x OFF/MTO; informational times 0.36–0.67x).
Note for Tier1/learning: TN_200 shows the split can be slower on some codes (to be examined).
