# Adjudication: cc_proto's tier5 distance claims

- Date: 2026-10-15, 17:30 CST.
- Subject: claims in `ext/QUBITSERF_REPORT.md` §4-5, made by the connected-cluster prototype `ext/qs-scripts/cc_proto.cpp` (binary `qs-build/cc_proto5`).
- Inputs:
  - the witness GF(2) check (`verify/witness-gf2`);
  - three audits (`verify/search-audit`, `verify/orbit-audit`, `verify/impl-audit`);
  - two clean-room reimplementations (`verify/reimpl-A`, `verify/reimpl-B`);
  - my own spot re-checks (§4).
- Scope of my changes: nothing in any repository was modified or pushed. My only new files are this document and `verify/adjudication/`.

## 摘要（繁體中文）

- **五個新的精確距離全部判定為 CONFIRMED**：BB_360_12 d=24、TN_252_2 d=21（dX=21、dZ≥22）、LP_1054_140 d=20、LP_1428_184 d=24、LP_1768_224 d=22。依據有三：
  - 見證向量都通過獨立的 GF(2) 檢查；
  - 兩個彼此獨立、從零寫起（clean-room）的實作（A、B）都重現了相同的下界；
  - 三份稽核都沒有找到任何未解決的正確性（soundness）問題。
- **不用軌道（orbit）也能重現大部分下界**：BB_360、TN_252、LP_1054、LP_1768 都已在不用軌道的情況下重現。LP_1428 只有 Z 半邊的 w=23 這一層仍須依賴軌道，而這些軌道已經多次獨立驗證。
- **其他 17 個 tier5 代碼的新下界判定為 PLAUSIBLE**：目前只有原型跑過，A、B 都還沒有重現，但也沒有任何反證。
- **建議**：
  - 先用 A 或 B 在伺服器上補跑這 17 個下界，每個代碼不超過 1 小時；
  - 把 CC 引擎正式做進 DistQLDPC，用 DistQLDPC 自己重現這 5 個距離，再請 PI 決定是否改 stem 名稱。

## 1. Verdicts

| Stem | Claim | Verdict |
|---|---|---|
| BB_360_12_17to24 | d = 24 | **CONFIRMED** |
| TN_252_2_17to28 | d = 21 (dX = 21, dZ >= 22) | **CONFIRMED**: d = 21 and dX = 21 exact, dZ >= 22. The exact value of dZ is open and is not needed for d. |
| LP_1054_140_17to32 | d = 20 | **CONFIRMED** |
| LP_1428_184_ge17 | d = 24 | **CONFIRMED**. Only the Z half at w = 23 depends on orbit seeding. |
| LP_1768_224_ge17 | d = 22 | **CONFIRMED** |
| 17 other tier5 codes | new lower bounds, listed in §3 | **PLAUSIBLE** (aggregate). Neither reimplementation covered them. |

Three conditions make a claim CONFIRMED:

- every claimed witness is valid;
- at least one clean-room implementation reached the same lower bound in every half (here both A and B did);
- no soundness finding remains unrefuted (§5).

Nothing was REFUTED or found UNSOUND. Across all runs, no implementation found a nontrivial logical lighter than any claimed d.

## 2. Evidence for each claim

Notes on the table:

- "lvl" means every weight level up to that value was proven empty, in both halves unless a half is named.
- In A's split runs ("split"), each level is checked on its own: a level counts as empty only when all K parts report EMPTY. The parts' owned-node counts add up exactly to the common total; I re-summed them.

| Stem | Upper bound (witness) | Prototype | Reimpl A, with orbits | Reimpl B, with orbits | Lower bound without orbits |
|---|---|---|---|---|---|
| BB_360_12 | X and Z, weight 24, valid. B's three extra weight-24 witnesses are also valid (I checked them). | lvl 23, then FOUND at 24, in 3037 s. MRV run agrees (3424 s). | lvl 23 in both halves, then FOUND at 24, in 6422 s. | lvl 23, then FOUND at 24: X 1694 s, Z 1764 s. Re-runs with `--order 0` and `--paranoid` agree. | **Yes, d >= 24.** A split level 23: X with K=6 (9.7e10 nodes) and Z with K=6 (1.16e11 nodes), all parts EMPTY. B reached lvl 22. |
| TN_252_2 | X, weight 21, valid (the report's witness). A and B both found a second, different weight-21 X logical, also valid (I checked it). | 4 threads: X lvl 20 and Z lvl 21, then X FOUND at 21, in 9787 s. 1 thread: X lvl 19, Z lvl 20. | Primary run: lvl 20 in both halves (19084 s), then the 6 h cap during X21. Split runs: X20 EMPTY (K=4), Z20 EMPTY (K=3), Z21 EMPTY (K=6), X21 FOUND. | X lvl 20, then FOUND at 21 (9512 s). Z lvl 21 (20101 s). Single-level re-runs: X20 EMPTY, Z21 EMPTY with exactly the same node count (20,212,508,587). | **Yes, dX >= 21 and dZ >= 22.** A split runs without orbits: X20 EMPTY (K=6), Z20 EMPTY (K=3), Z21 EMPTY (K=16). |
| LP_1054_140 | X and Z, weight 20, valid. | lvl 19, then FOUND at 20, in 76 s. Without orbits: 1357 s. | lvl 19, then FOUND at 20, in 140 s. | X 47 s, Z 61 s. `--order 0` and `--paranoid` agree. | **Yes, d = 20 exact.** A: 2864 s. B: 730 s. |
| LP_1428_184 | X and Z, weight 24, valid. | lvl 23, then FOUND at 24, in 3013 s. MRV run agrees (3505 s). | lvl 23, then FOUND at 24, in 5816 s. Split Z23 EMPTY (K=6). | X 1427 s, Z 1846 s. `--order 0` and `--paranoid` agree. | **Partly.** dX >= 24 (A split X23 EMPTY, K=2). dZ >= 23 (B without orbits, lvl 22). Z at w = 23 has been refuted only with orbits, by three implementations. |
| LP_1768_224 | X and Z, weight 22, valid. | lvl 21, then FOUND at 22, in 327 s. MRV run agrees (351 s). | lvl 21, then FOUND at 22, in 637 s. | X 158 s, Z 219 s. | **Yes, d = 22 exact.** B without orbits: 4759 s. A: X21 EMPTY (single run) and Z21 EMPTY (K=6). |

**Independence.** The upper bounds are certificates. Each witness passed the from-scratch pure-Python checker (`witness-gf2`), which confirms that H e = 0 and that the rank rises by one. Separately:

- A and B each re-check every witness inside the program.
- B's independent Python checker re-checked 144 witnesses with 0 failures.

For the lower bounds, the two reimplementations share no code with the prototype or with each other, and each decides nontriviality its own way:

- **A** uses rank against rowspace(Hstab). It does not use the G files.
- **B** builds and verifies its own dual basis.

Before any claim run, both passed all 27 tier0-4 and solved-tier5 validation codes with and without orbits: 54/54 runs each. Both also agree with brute force on random small codes:

- A: 160 random codes plus 9 tier0 codes.
- B: 2560 comparisons on 160 random codes.

## 3. New lower bounds for the other 17 tier5 codes (aggregate)

I re-derived these from `ext/logs/proto_t5/*.log`. Each code ran single-threaded with `excl,pack,orbf`, capped at 30 minutes (TN) or 60 minutes (BB). The levels run without gaps from w = 1 in both halves.

| Stem | Prototype lb (Z / X reached) | Orbits per half |
|---|---|---|
| TN_288_2_ge9 | >= 18 (19 / 18) | trivial |
| TN_324_4_ge9 | >= 18 (19 / 18) | trivial |
| TN_432_8_ge9 | >= 19 (19 / 19) | trivial |
| TN_540_4_ge9 | >= 19 (19 / 19) | trivial |
| TN_576_2_ge9 | >= 20 (20 / 20) | trivial |
| TN_648_14_ge9 | >= 19 (20 / 19) | trivial |
| TN_648_10_9to52 | >= 19 (20 / 19) | trivial |
| TN_684_2_ge9 | >= 20 (20 / 20) | 36 |
| TN_360_4_ge17 | >= 20 (21 / 20) | 36 |
| TN_396_4_ge17 | >= 20 (21 / 20) | 36 |
| TN_468_4_ge17 | >= 20 (21 / 20) | 36 |
| TN_496_2_ge17 | >= 20 (20 / 20) | 16 |
| TN_504_2_ge17 | >= 21 (22 / 21) | 36 |
| TN_612_2_ge17 | >= 22 (22 / 22) | 36 |
| BB_756_16_ge17 | >= 25 (25 / 25) | 2 |
| BB_864_4_ge17 | >= 25 (25 / 25) | 2 |
| BB_1080_4_ge17 | >= 25 (26 / 25) | 2 |

**Verdict: PLAUSIBLE.** What supports these bounds:

- The binary and rule set are the same ones whose five hard results A and B reproduced independently.
- The orbit audit recomputed the orbit partitions of all 17 codes and found them identical to DistQLDPC's `-symbreak-report`.
- The search audit and the implementation audit found no soundness defect.
- Seven of the codes have a trivial symmetry group, so their bounds use only CC + excl + pack, the most heavily tested part.

They stay PLAUSIBLE, not CONFIRMED, because no clean-room run has reproduced them yet. Report §0 says "13 other open tier5 codes", but §4 lists 17; 17 is correct.

## 4. What I re-checked myself

- **Server and Mac matrices are byte-identical.** I compared the sha256 of all 20 matrix files under `~/mac-agent-20261009/main-398054e/data/matrices/tier5` (the files A and B used) with the hashes in `witness-gf2/check_witnesses.log` for the Mac files. All 20 match.
- **No leftover server processes.** None of `cc_exact`, `ccb`, `cc_proto` or `aux_witness` is running on yfclab2.
- **The extra witnesses are valid.** I re-checked the reimplementations' witnesses that differ from the report's, with my own pure-Python GF(2) script (`verify/adjudication/recheck_alt_witnesses.py`, log next to it). These are the TN_252 X weight-21 witness, B's BB_360 X/Z (default order), BB_360 Z (`--order 0`), and LP_1054 X/Z. Each has H e = 0 and raises the rank by one (for example TN_252: rank 125 to 126). All are VALID.
- **A's split runs are complete.** I read every `LEVELRESULT` line in `reimpl-A/logs/split_logs` and checked that the owned counts sum to each group's total: TN_252 plain Z21 (16 parts, 14894), orbit Z21 (6 parts, 2130), orbit X20 (3134), plain X20 (21892), plain Z20 (14894), BB_360 plain X23 (2377) and Z23 (2406), LP_1428 orbit Z23 (3302) and plain X23 (20705), and LP_1768 plain Z21 (31782). All are EMPTY with complete coverage. The aborted parts (LP_1428 plain Z23, the K=8 TN_252 Z21 attempt and the TN_252 X21 siblings) are correctly not counted.
- **The prototype logs say what the report says.** I read the TN_252 4-thread log and re-derived the bounds from all 27 `proto_t5` logs. Levels are consecutive, the bounds match report §4, and the witness lines match.
- **Finding F2 is real.** I confirmed in `cc_proto.cpp` lines 82-91 that hits are reported only when w == target, and that a syndrome-free cluster below the target returns false.

## 5. Soundness findings and their status

| # | Raised by | Severity | Finding | Status |
|---|---|---|---|---|
| F1 | search, orbit, impl audits | minor | `int stamp` (lines 60/122/133) overflows after 2^31 packing nodes in the BB_360, LP_1428 and TN_252 runs. Signed overflow is undefined behaviour in C++. | **Closed, not a soundness threat.** A stale mark can only remove a check from the packing, which weakens pruning. The "no candidate" test sets `any` before it reads the mark. This was checked several ways: forced-wrap builds give identical node counts (40/40 levels on LP_1054, plus BB_144, LP_442 and TN_108); a stamp-mod-3 stress build finds identical sets of minimum-weight logicals; and the TN_252 1-thread and 4-thread runs have identical counts. A (64-bit stamp) and B (no stamp) reproduce every claim. Any in-repo engine must use `uint64_t`. |
| F2 | search audit | info | A level's answer is exact only if all lower levels were refuted: the prototype drops nontrivial syndrome-free clusters below the target. Single-half runs with `W_FROM > 1` would be unsound. | **Closed for the claims.** All are css runs with unbroken levels 1..d. **Still a design point:** CC_INTEGRATION_PLAN §5.2 rules 1-2 have the same dependency (precondition lb_h >= w). See §7, step 3b. |
| F3 | search, impl audits | info | The unverified `orbbb` variant hard-codes the two n/2 blocks as orbits. | **Closed.** No claimed run used it. Drop it from any port. |
| F4 | search, impl audits | info | Orbit-file handling is fragile: any tag other than "Z" is taken as X, ids must be contiguous, the cache is keyed by stem only, and a missing file silently falls back to plain seeds. | **Closed for the claims.** Three independent recomputations and DistQLDPC `-symbreak-report` match the cached files exactly. An in-repo engine should use `find_half_symmetry` in-process. |
| F5 | impl audit | info | `read_mat` validates nothing: a missing file leads to undefined behaviour, and ragged rows are read out of bounds. | **Closed for the claims.** The inputs were scanned clean, and the server and Mac files are identical (§4). |
| F6 | impl audit | info | The program never checks that the detectors are complete, i.e. rank[H;G] = n - rank(S). | **Closed.** Two audits verified this on all 26 tier5 codes, and A and B do not depend on the G files. An in-repo engine should check it at start-up. |
| F7 | orbit audit | minor | The soundness sketch in report §5 leaves out three steps: the invariance condition, that a moved logical stays in O_{>=i}, and the minimality argument behind the closed-cluster dead end. | **Closed (documentation).** The full argument is in the orbit audit, `reimpl-A/DESIGN_NOTES.md` and `reimpl-B/DESIGN.txt`. Fix the report text. |
| F8 | orbit audit | minor | The "second search order" cross-checks reuse the same orbit file, and only LP_1054 had been reproduced without orbits. | **Closed by the reimplementations.** BB_360, TN_252, LP_1054 and LP_1768 are now reproduced without orbits, and LP_1428 up to dX >= 24, dZ >= 23. Remaining: LP_1428 Z at w = 23, which rests on orbits verified by DistQLDPC plus three independent recomputations. |
| F9 | orbit audit | info | `orbits.py` lacks DistQLDPC's halfswap-inverse maps, so its partitions can only be finer, which is the safe direction. | **Closed.** The partitions are identical. |
| F10 | impl audit, witness check | info | TN_252's X level 20 and Z level 21 came from a single 4-thread run. | **Closed.** A (split runs, with and without orbits) and B (full-run and single-level) reproduced both levels. |
| F11 | witness check | info | TN_252 has no Z witness, so d = 21 also needs dZ >= 21. | **Closed.** dZ >= 22 was reproduced by A and B. The exact dZ is open and is not needed. |
| F12 | this adjudication | info | Report §0 says "13 other open tier5 codes" while §4 lists 17. | Documentation fix. |

**Residual risk (no finding, stated for completeness).**

- **Common-mode risk.** All three searches implement the same algorithm (DKP connected clusters + sibling exclusion + disjoint odd-check packing + orbit seeds) from the same description. A shared risk would be a flaw in the algorithm's argument, not in the code. Against that:
  - five separate write-ups of the argument found no gap;
  - the code agrees with brute force (enumerating the kernel, with no use of CC) on more than 100k small-code runs;
  - LP_1054 and LP_1768 are exact in two implementations without orbits.
- **No formal certificate.** The lower bounds are reproduced exhaustive searches, not proof logs. A checker that replays a trace (plan §8.5) would close this gap.

## 6. What a stem rename still needs

There are two PI rules. Stems carry only bounds that "our tool" has confirmed. Reproduction inside DistQLDPC is preferred, and §8.5 of CC_INTEGRATION_PLAN asks for a certification bundle.

| Bundle item (§8.5) | 5 claimed codes | 17 lower-bound codes |
|---|---|---|
| Verified witness, both checks | done | not applicable (no new upper bound) |
| Agreement from at least one clean-room implementation | done (A and B) | **missing** |
| Rule-diverse re-run (without orbits, MRV, other order) | done; one level orbit-only (LP_1428 Z w=23) | missing |
| In-repo DistQLDPC CC result with trace | **missing** | **missing** |
| `cc_check` replay | **missing** | **missing** |

Proposed new names, to be done only after PI acceptance, in both repos, with `scratchpad/coord/rename_stems.py`:

- BB_360_12_17to24 to BB_360_12_24
- TN_252_2_17to28 to TN_252_2_21
- LP_1054_140_17to32 to LP_1054_140_20
- LP_1428_184_ge17 to LP_1428_184_24
- LP_1768_224_ge17 to LP_1768_224_22
- After the lower-bound reproduction:
  - TN_288_2_ge18, TN_324_4_ge18, TN_432_8_ge19, TN_540_4_ge19, TN_576_2_ge20, TN_648_14_ge19, TN_684_2_ge20, TN_648_10_19to52;
  - TN_360_4_ge20, TN_396_4_ge20, TN_468_4_ge20, TN_496_2_ge20, TN_504_2_ge21, TN_612_2_ge22;
  - BB_756_16_ge25, BB_864_4_ge25, BB_1080_4_ge25.

Renaming does not change tiers. Tiers are defined by main's server time, so these codes stay in tier5 until main itself solves them.

## 7. Next steps (in order)

1. **Reproduce the 17 lower bounds now.** This is cheap and needs no new code. Run reimpl-B's `ccb`, which runs each half as its own process, or reimpl-A's `cc_exact` on yfclab2:
   - one pinned core per half, `taskset` + `prlimit --as=4 GiB`, capped at 1 h (TN) or 2 h (BB);
   - 34 processes in all;
   - the coordinator must assign a core range.

   A matching lb for each code moves these from PLAUSIBLE to CONFIRMED.
2. **Optional: remove the last level that depends on orbits.** Run LP_1428 Z at w = 23 without orbits using A's `-level 23 -split K k 3`. A estimated about 16 CPU-hours, which is 1-2 h wall on 8-16 server cores. Low priority, because the orbits are verified.
3. **Build the in-repo engine** (CC_INTEGRATION_PLAN S0/S1) with these changes taken from this review:
   - a. Use a `uint64_t` packing stamp, or reset the epoch when it wraps (F1).
   - b. **Make each level self-contained**, as A and B do: report any nontrivial syndrome-free cluster with |S| <= w as FOUND (a verified witness), not only at |S| = w (F2). This removes the lb_h >= w precondition in §5.2. It lets one level be run, split or re-run as a standalone certificate, which is exactly what made TN_252 and the runs without orbits feasible. The cost is one nontriviality test per closed cluster.
   - c. Check at start-up that the detectors are complete (rank[H;G]), and validate matrix shape (F5, F6).
   - d. Take orbits only from in-process `find_half_symmetry`, and drop `orbbb` (F3, F4).
   - e. Write per-level node counts and an event-hash trace for `cc_check`. Add A-style prefix partitioning (`-split K k D`) and B-style per-half processes, so that server runs parallelize without threads.
4. **Reproduce the 5 distances inside DistQLDPC** on yfclab2, one process per half (or one half, where the XZ-dual map applies). Expected wall time per half, from B's server timings:

   | Code | Expected wall time per half |
   |---|---|
   | LP_1054 | about 1 min |
   | LP_1768 | about 4 min |
   | LP_1428 | about 30 min |
   | BB_360 | about 30 min |
   | TN_252 | about 2.6 h (X to the witness at 21; Z through level 20 suffices for d = 21) |

   TN_252 Z at level 21, which gives dZ >= 22, takes about 4 h more, or under 1 h split across 6 cores. Then assemble the §8.5 bundle: witness, in-repo trace, A/B agreement, `cc_check` replay, and a run without orbits or with MRV.
5. **PI decision.**
   - (a) Accept the current evidence (witnesses plus three in-house exhaustive searches that agree) and rename now.
   - (b) Wait for step 4, which is the "prefer DistQLDPC" route and my recommendation. The science is settled and step 4 is short once the engine exists.
   - (c) An interim option is to update only the witness-backed upper bounds now, for example LP_1428_184_17to24, LP_1768_224_17to22, LP_1054_140_17to20 and TN_252_2_17to21. These are certificates whichever tool found them, but they add one extra round of renames.
6. **Fix the report text** (F7, F12) before it is shared further.

## 8. Assessment: the CC + packing-bound engine inside DistQLDPC

**Where it wins (measured).** Times below are single-threaded. Main's times are the recorded Mac numbers for tier0-4 and the server numbers for tier5. CC times are the prototype's (Mac) or B's (server).

| Code | Main (best mode) | CC with orbits | CC without orbits |
|---|---|---|---|
| BB_288_12_18 | 304 s | 3.6-6.5 s | 55-125 s |
| LP_544_80_12 | 51 s | 0.1 s | 0.3-0.8 s |
| GB_144_12_12 | 60 s | 0.4-0.5 s | 1.4-2.9 s |
| TN_144_2_13 | 71 s | 4-6 s | 10-20 s |
| TN_250_10_15 (no symmetry) | 985 s | 67-107 s (no orbits to use) | 67-107 s |
| LP_714_100_16 | 1409 s (Mac), timeout at 5000 s (server) | 3.6 s | 21-33 s |
| LP_1020_136_16 | about 7-8 ks (server) | 1.5-2.5 s | 26-42 s |
| TN_180_2_17 | about 10 ks (server) | 341-384 s | 853-1365 s |
| TN_216_4_18 | 17-18 ks (server) | 595-924 s | 3183-5363 s |

- **Tier5 results:** 5 new exact distances, up to d = 24 at n = 1768, each in at most 1 h per half (TN_252 at most about 2.6 h), plus higher lower bounds on the 17 other open codes.
- **Scaling:** the packing bound cuts growth per level from about 6x (plain CC, and in effect MaxCDCL's lower-bound side) to about 2.6-3.8x. It gives 50-500x fewer nodes at a fixed level.
- **Symmetry:** orbit seeds add 6-18x on LP, 10-16x on BB and 2.3-2.7x on TN codes with 36 orbits. This reuses DistQLDPC's own verified GH-85 symmetry machinery.
- **Operations:** memory is a few MB, far below the 2/4 GB caps. Runs are deterministic, with node counts reproducible across implementations and thread counts, which is good for certificates. Seed and prefix partitioning parallelizes cleanly on the server.

**Where it loses or does not help.**

- **Codes where each qubit touches only 2 checks** (toric and surface codes): the packing bound is useless there, and the prototype is about 1.5x slower than Qubitserf on toric_20. These must stay on MaxCDCL, as the plan's selector already does.
- **No upper bound until the exact level.** A run that stops early gives only a lower bound. Each extra unit of d costs about 3x (B's TN_252 Z level 20 to level 21: 4053 s to 14295 s), so codes with d around 30 or more are out of reach on one core. This covers BB_756/864/1080 (lb >= 25 after 1 h, true d unknown and likely larger) and TN_648_10 (upper bound 52). For those, MaxCDCL, or the plan's U0 basis-row bound, is still needed for upper bounds. The S2a co-scheduling idea follows from this.
- **No symmetry, no orbit gain.** The seven TN tier5 codes with a trivial group stall at lb 18-20 after 30 min. Further progress there needs new automorphism discovery or stronger bounds.
- **The algorithm is easy to copy.** It is published (DKP 2017), and the packing bound is about 20 lines, so Qubitserf or anyone else could add it. Against MaxCDCL it is a real engine-level differentiator, a QLDPC-specific bounding rule that MaxCDCL cannot express, which matches the PI's preferred direction. The lasting value comes from three things together: the verified integration with symmetry and duality, the certified traces and checker, and the new results. GH-121 (PIB) showed that putting the same parity bound inside MaxCDCL's lookahead hurt solution-finding on TN, so keeping CC as a separate engine with MaxCDCL as the fallback and upper-bound engine is the right structure.

**Recommendation.** Proceed with CC_INTEGRATION_PLAN S0 to S1, with the changes in §7 step 3. Adoption still goes through Tier 0-5 under the PI's rule. On the evidence so far, a CC-enabled candidate would solve 9 of the 26 tier5 codes within the 6 h limit (the 4 already solved plus the 5 new), against the 3-4 that main solves. Tiers 1-4 would mostly empty out, and re-tiering is a PI decision (plan §11.4).

## 9. Files

- This document: `ext/verify/ADJUDICATION.md`.
- My witness re-check: `ext/verify/adjudication/recheck_alt_witnesses.py` and `ext/verify/adjudication/recheck_alt_witnesses.log`.
- Evidence I relied on:
  - Witness check: `ext/verify/witness-gf2/check_witnesses.log`.
  - Reimplementation A: `ext/verify/reimpl-A/logs/{claim_logs,split_logs}/` and `ext/verify/reimpl-A/DESIGN_NOTES.md`.
  - Reimplementation B: `ext/verify/reimpl-B/server-logs/{claims_summary.txt,witness_recheck.txt,validation_v2_summary.txt}` and `ext/verify/reimpl-B/DESIGN.txt`.
  - Prototype logs: `ext/logs/proto_t5/`, `ext/logs/proto_t5_mt/` and `ext/logs/proto_xcheck/`.
  - Audits: `ext/verify/{search-audit,orbit-audit,impl-audit}/`.
  - Integration plan: `ext/verify/CC_INTEGRATION_PLAN.md`.
