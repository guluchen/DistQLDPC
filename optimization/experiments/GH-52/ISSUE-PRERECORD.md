# GH52 full issue prerecord snapshot before implementation

Issue https://github.com/guluchen/DistQLDPC/issues/52; IDs GH-52-A/B/C. Fresh worktree GH52-DEFERRED-SOFT, branch experiment/gh52-deferred-soft.

Hub #15. Owner academic_brain_loop, fresh independent round after GH26 production adapter feasibility closure. Immutable baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a; source-only, no compute/implementation yet. DistQLDPC's downstream MaxCDCL-derived engine and QDistSAT benchmark platform remain distinct from upstream. No scientific/CSS/QECC/Pauli/logical/objective/groundtruth/bound/timeout/output/correctness assumption changes.

Exactly THREE proposals, one selected:

A rank1 SELECTED: defer unlocked-soft-conflict stopping ONLY in propagateForLK. Research origin: Zhang/Li/Cherif/Li, Weight-Aware Branch-and-Bound for Weighted Maximum Satisfiability, IJCAI2026 §3.3 Algorithm3. Paper continues propagation beyond a soft falsity until hard conflict or queue exhaustion, then chooses a falsified soft literal. This experiment isolates continued propagation for the existing unit-cost engine, preserves the first eligible original soft falsity as fallback, and prioritizes actual hard conflicts. Excludes weighted WA-Select, weight-priority heap, stratified hardening, new bound/core formula, FLA and new caller. This is a restricted adaptation, not full-paper replication; weighted-paper benchmark improvements are not predicted here.

Concrete mechanism: baseline uncheckedEnqueueForLK returns false immediately on an unlocked soft falsity; propagateForLK then exits. That can prevent later existing hard clauses from reaching an actual hard conflict. Continue the exact existing UP queue under the same positive assumptions, preserve existing reason clauses and locked-core unlocking. At exhaustion, report the first stored soft falsity through the original analyzer. Only if genuine actual-source safety established. Potential cost: extra UP/watch traffic and different cores/search can outweigh stronger conflicts. No hotspot, frequency, benefit or percentage established. Unit weights make the paper's weight-priority component inapplicable; no fabricated weights.

Mandatory proof-first gate: analyze every actual caller and helper, multiple unlocked falsities, falseVar preservation, hard-vs-soft return flags, causal implication graph/reasons, isetLock/finalIset/unlockReason and heap updates, qhead/trail cleanup on both returns, flags/counters, root offset/current UB and hardening lifecycle. A hard conflict found after a soft falsity is not automatically a valid new cost certificate; prove original setConflict/lookbackResetTrail applies. If broader learner/rollback/core changes are necessary, withdraw selected narrow scope before coding rather than silently bundle them. No synthetic conditional fixture is substituted for genuine production safety. Estimate1–3days source/fixture engineering, then one bounded assigned Tier0; scientific anomaly/crash/wrong bound stops immediately.

B rank2 UNSELECTED: remaining-weight-first active soft-literal selection with activity tie-break only, from the same paper §3.3 PickSoftLiteral. DistQLDPC objective unit weights and remaining lock eligibility may leave all selectable weights identical; inspect exact eligibility and reject as inert if so. Never invent component count as remaining literal weight or generalize WPMS gains to CSS. Any real variation needs original objective bookkeeping proof. No selection/implementation of this method.

C rank3 UNSELECTED: demand dirty-watch cleanup only in propagateForLK through existing lookup(p), replacing its two entry cleanAll calls. Ordinary engineering, not paper-derived; openly reranks prior unselected GH17-B/GH20-C/GH27-B/GH44-B/GH46-B/GH50-B, no novelty claim. Requires actual dirty/reached/avoided counts and raw consumer/append/delete/GC/reset audit; binResMinimize direct access forbids assuming postponed cleanup safe. Withdraw if broad container redesign needed. No cache-stall/allocator claim or compiler bundle.

Primary source: https://www.ijcai.org/proceedings/2026/270 and https://www.ijcai.org/proceedings/2026/0270.pdf; pages2427–2436, DOI10.24963/ijcai.2026/270, published August2026 within the requested October2024–October2026 interval. Exact paper section/Algorithm3 inspected, along with Algorithm4 exclusion. Bibliography:
```bibtex
@inproceedings{zhang2026weightaware,
  author={Jialu Zhang and Chu-Min Li and Sami Cherif and Shuolin Li},
  title={Weight-Aware Branch-and-Bound for Weighted Maximum Satisfiability},
  booktitle={Proceedings of the Thirty-Fifth International Joint Conference on Artificial Intelligence},
  year={2026}, pages={2427--2436},
  doi={10.24963/ijcai.2026/270},
  url={https://www.ijcai.org/proceedings/2026/270}
}
```
No paper code import; license unverified, original implementation only if feasible.

Learning: GH26 kernel534/reader64+5 certificates did not certify merged-K/current-bound provenance or actual speculative rollback; production adapter now SHELVED/UNPROVEN, no performance rejection of all FLA. GH50 actual originalGCC already commoned both source value checks: identical1168-byte function/3relocations, so no source-operation-count speed inference. GH46 valid baseline opposite-unit anomaly persists; no omission/waiver/semantic fix to claim full certification. GH30/GH36 family/mode regressions and GH41 Tier1 INCON+MTO observations require all fixed cases/modes. No previous optimization stacked.

Open AND closed issue and all-state PR keyword searches checked soft conflict/weight-aware/delayed/demand/propagation; selected existing loop/scratch/codegen/ISA work differs, no matching selected deferred-soft-stop found. Reread hub after registering; lower issue owns simultaneous duplicate. No global STATE/HYPOTHESES writes.

Next: fresh isolated baseline worktree, exact issue-local A/B/C prerecord and source feasibility proof BEFORE candidate. No builds/tests/diagnostics/solver/timing/server upload until root named assignment. Team spare>50%, <=half spare, one serial worker/host, owned process/PID-birth cleanup and actual restoration, byte-preserved raw/source/runtime/input/bin evidence. Prototype instrumentation separate from production, no cost parameter sweep.

Tier0 genuine production fixtures compare independent tinyPMS/CSS/all5CLI/scientific interims/finals/model/bounds/timeout, meaningful multiple-soft/hard-conflict/unlocking/lifetime cases, required hosted actual-source correctness. Baseline anomaly is an explicit blocking evidence, not silently passed. Scientific mismatch stops/rejects. Engineering coverage/resource/identity failures remain INCON with retained raw.

Only after certified correctness/opportunity and separate assignment: fixed Tier1 BB90/GB144/BB108/LP238 OFF/MTO,3baseline+3candidate serialAB/BA/AB=48,180/195 limits, original numeric filter/full raw medians/ranges. Tier2 LP34012 at600/615 only actual gate or separately preregistered user's one-tier exception; no implied Tier1PASS. No Tier3/adoption/merge authorized. Cost/frequency/controlled claims require actual evidence, not papers/source counters. Current source/PR/Tier0/performance NONE.
