# Optimization state

Latest user decision: [provisionally shelve E001 / LEARN](experiments/E001/DISPOSITION-2026-10-07.md).
Latest [literature/program-optimization revision](brain/2026-10-07-round2-research-revision.md) supersedes the initial Round 2 recommendation and the earlier
resume-only scheduling instruction. Evidence requirements are unchanged.

## Immediate state

E001 / H-001: **SHELVED / NOT ADOPTED for the current track**, at the user's
explicit direction after repeated diagnostic GB regressions. Its controlled
performance decision remains INCONCLUSIVE; no controlled rejection is invented.
Correctness PASS, no Tier 2/3 or merge; all five complete diagnostic rounds
(144 Windows + 96 yfclab2 solves) and interrupted attempts remain preserved.
CPU-isolation installation was deferred and is not installed; ordinary spare
capacity use remains authorized within the user's limits.

Current experiment: [E004 / H-007 LTO](experiments/E004/README.md), authorized
by acceptance of the revised recommendation. Independent baseline 24572d6;
tested candidate 5b13a2c, final PR 2efbdc1 (only CI serialization differs).
Server and final required hosted PR Tier 0 PASS. All 48 Tier 1 diagnostic solves
are correct; OFF/MTO median geomeans 0.979514/0.981341, but MTO range envelope
1.006753 fails the beyond-noise gate. Occupied host with 29 contention checks.
Decision INCONCLUSIVE. The user subsequently requested diagnostic Tier 2
LP_340_56_8 despite this gate. Two attempts stopped at global idle 47.61%/40.33%;
only one OFF baseline completed (97.587s, d=8), no candidate/MTO completion.
[Tier 2 follow-up](experiments/E004/TIER2-DIAGNOSTIC-RESULT.md): no comparison,
medians or speedup; Tier 1 remains unchanged. No Tier 3, adoption or merge.
Candidate isolated in
experiment/h007-lto, draft PR 12; current history branch still preserves E001.

H-008 SLS/H-009 BDD remain unimplemented alternatives, not an execution queue.
Next: controlled E004 Tier 1 if worth resolving; otherwise explicit shelving
and a fresh Brain before choosing another idea. Do not promote small noisy gains.
H-003/H-005/H-006 and original witness screen remain historical candidates.

## Historical state before the latest shelving instruction

The remaining resume-only descriptions below preserve the earlier chronology;
they are superseded for current scheduling by the explicit user decision above.

The user corrected the lifecycle on 2026-10-07: BRAIN -> EXECUTE -> EVALUATE ->
LEARN -> BRAIN AGAIN. Hypotheses are not a queue. Do not start another optimization
while E001 is unresolved. H-002/H-003 were alternatives from the old Brain,
not successors. Earlier wording prioritizing E003/profiling or treating a new
round request as permission to bypass E001 resolution is superseded by this
explicit instruction. E002/E003 remain preserved historical experiments.

Worktree branch research/e001-resolution-audit restores the exact E001 application
source from 50623f9; no new optimization or change to E001's preregistered gates.
Original baseline 24572d6, candidate code 50623f9, package snapshot 9d68f45,
QDistSAT harness 7c4774f. Embedded MaxCDCL unchanged; DistQLDPC is downstream,
not identical to upstream MaxCDCL. No scientific semantics changed.

## Evidence and working performance model

These are provisional observations, not the post-resolution LEARN step.

- E001 mechanism/prediction: invertible sequential row-XOR shortens separate
  Gx/Gz copies, reducing logical chains; expected encoding savings, especially LP.
- Observed logical weights/raw logical XOR gates: LP_136 560->428, BB_90 204->190,
  GB_144_12_8 491->434, BB_108 250->222, LP_238 1160->936, LP_340 2220->1688.
  These are before simplification; do not equate them with final clause counts.
- E001 correctness: retained macOS and hosted Linux Tier 0 PASS; three Windows
  rounds pass Tier 0 and 144 complete timing solves have certified correct results.
  Hosted report independently reverified; shared CI timing excluded.
- Windows direction: BB_90, BB_108 and LP_238 faster in both modes in both rounds;
  GB slower: OFF ratios 1.4929 / 1.4756 / 1.4700, MTO 1.4138 / 1.4128 / 1.4528. GB sample ranges
  disjoint in each round/mode. Local numeric filter REJECT three times; controlled
  decision remains INCONCLUSIVE. Raw data and medians retained under E001.
- Supported inference: fewer generated gates alone cannot predict whole-solve
  runtime on these local measurements. Family-dependent behavior is observed;
  a structural correlation or portable causal explanation has not been established.
- Likely explanation to investigate: changed CNF structure can change propagation
  and search. Confidence low: stage timing/search-counter causal analysis has not
  isolated it. End-to-end measurements cannot separate encoding/preprocessing
  savings from search effects; absent counters are unknown, not zero.
- Implication after resolution: examine construction, simplification and search
  evidence separately; protect certified bound progress on difficult cases.
  This is guidance for a future Brain, not selection of another hypothesis.

Fresh package audit PASS: all 914 payload hashes, 28 input identities, exact
E001 patch/source and unchanged engine/notices; six gate/parser tests PASS.
No fresh solver run or controlled timing in this audit. See
experiments/E001/raw/resolution-audit-20261007.json.

## Preserved history

- E001: active, correctness PASS, Windows numeric REJECT three times, controlled
  INCONCLUSIVE. See EXECUTION_REVIEW.md and WINDOWS_RESULT/REPEAT_02_RESULT.md.
- E002 / H-002 exact XOR-prefix sharing: independent baseline, correctness PASS,
  48 local solves correct; numeric REJECT with GB both modes and BB_108 OFF
  regressions. Controlled INCONCLUSIVE; unpromoted. No formal fresh Brain round
  after resolving E001 occurred. Full record/branch preserved.
- E003 / H-004 local clause-buffer reuse: independent baseline, correctness PASS,
  six byte-identical WCNFs; 48 local solves correct, numeric INCONCLUSIVE
  (OFF median-ratio geomean 1.00346, MTO 0.99283). Controlled INCONCLUSIVE,
  unpromoted; no evidence allocation dominates. Full record/branch preserved.
- H-003 verified witness/initUB: untested old alternative, no priority.

## Resume protocol

Run the unchanged E001 package on the exclusive server; return the entire output
including reservation/environment, compiler/build logs, Tier 0, raw samples,
medians and decision. Check environment validity before adopting numeric results.
Tier 1 failure/inconclusive stops; Tier 1 PASS alone permits LP_340 Tier 2.
No Tier 3 in this runner; do not spend expensive compute on an earlier failure.
A correctness anomaly stops and requires PI judgment.

After sufficient evidence resolves E001, explicitly record LEARN: mechanism,
prediction, actual outcome, help/hurt cases, likely explanation and confidence,
future implications. Then a fresh Brain may rank up to three candidates using
all evidence and select exactly one before implementation. Old candidates
compete equally with new ones. Preserve incremental certification and all failed
records. No accepted optimization or research-grade performance claim exists.

## Latest explicitly requested Windows execution

User requested measurement on this Windows machine with provenance labeled.
E001 Windows repeat 03 complete: fresh Tier 0 PASS; 48 scientifically correct
solves, same verified source/binaries, all 914 package payloads matched.
Windows numerical decision REJECT; GB OFF ratio 1.46995, MTO 1.45277, disjoint
ranges. Three rounds / 144 correct local solves total. No Tier 2/3 or new Brain.
Original controlled Linux status stays separate and INCONCLUSIVE; Windows results
are genuine local evidence, not mislabeled Linux measurements.

New existing-log observation: GB OFF repeat 1 last failed-UB cnfls 11976->18882,
final hardConflicts 594->615, nbLK 14347->23628, nbLKup 11604748->18263005.
Search work differs despite fewer raw gates; this supports investigating search
behavior but does not identify causal mechanism or construction-stage timing.
All 48 extracted counters and original logs preserved. See
experiments/E001/WINDOWS_REPEAT_03_RESULT.md; recorded OS/CPU/power/process
inventory in raw/windows-repeat-03/windows-host.json. Host interactive/unpinned.

## Reconciled remote yfclab2 evidence (origin 7f22d18)

Preserved remote continuation/server records and all raw files without overwriting
Windows records. E001 server Tier 0 PASS; attempts 2 and 5 each completed 48
correct diagnostic Tier 1 solves (96 total), using different CPU pairs. GB is
slower in both modes: attempt 2 +50.3% OFF/+42.5% MTO, attempt 5 +45.5% OFF/
+45.3% MTO; BB/LP improve. Samples remain separate by host and round, not pooled.
Capacity-guarded execution respected the remote user's idle allowance, but core/
sibling contention prevents controlled promotion. Strict attempts interrupted
before scientific/timing samples are retained, not counted as completed runs.

Remote GB OFF final LRB phase-1 counters 3055->5813 conflicts, 15->31 starts,
127023->234913 UP reproduce across two server rounds. These are phase-specific,
not total-search counts, and strengthen the search-work observation without
identifying a causal explanation. SERVER-2026-10-07.md documents uncertainty.
Remote fixed-core lease/isolation helpers and server package exporter are retained;
none installed/executed by this Windows publication task. SSH access is reported
configured remotely; exclusive reservation/isolation remains unresolved.
Original controlled E001 decision stays INCONCLUSIVE. No new Brain/selection.
