# Experiment history

Latest completed experiment: [E004 / H-007 LTO](E004/README.md), INCONCLUSIVE.
Tier 0 PASS, 48 correct diagnostic Tier 1 solves; small favorable medians but
MTO does not pass the noise-envelope gate, and the server is occupied. No
formal promotion or adoption/merge. The user-requested
[Tier 2 follow-up](E004/TIER2-DIAGNOSTIC-RESULT.md) was stopped twice on CPU capacity;
one baseline d=8, no complete candidate/MTO comparison or Tier 3.
Candidate source isolated in draft PR 12.
Subsequent [Windows attempt](E004/TIER2-WINDOWS-RESULT.md): toolchain unavailable,
installer launch rejected by automatic review; no builds or solver samples.
Same H-007, INCONCLUSIVE; Windows driver prepared but integration unexecuted.
2026-10-08 [follow-up](E004/TIER2-WINDOWS-COMPLETE-2026-10-08.md) completed setup,
Tier 0 and 12 correct LP340 diagnostics; Windows fallback now usable. Small
OFF/MTO median gains do not establish controlled promotion. E004 INCONCLUSIVE.

Earlier: E001 is provisionally shelved / not adopted by explicit user decision;
controlled performance remains INCONCLUSIVE. Its [LEARN record](E001/DISPOSITION-2026-10-07.md)
feeds the [revised research Brain](../brain/2026-10-07-round2-research-revision.md).
H-007 was subsequently tested as E004; H-008 SLS and H-009 BDD remain alternatives.
The original Round 2 H-003 priority is superseded. No automatic next trial.
Hypotheses are not a queue; only one may be tested per experiment.

- [E001 / H-001](E001/README.md): approved logical row XOR; correctness PASS,
  controlled INCONCLUSIVE. [Windows repeat 03](E001/WINDOWS_REPEAT_03_RESULT.md)
  completes three Windows rounds (144 correct solves), local numeric REJECT.
  [yfclab2 record](E001/SERVER-2026-10-07.md) preserves two separate server
  diagnostic rounds (96 correct solves), GB regression and contention telemetry.
  Both independent package/audit continuations and interrupted attempts retained.
- [E002 / H-002](E002/README.md): independent historical XOR-prefix sharing,
  correctness PASS, 48 correct Windows solves, local numeric REJECT; controlled
  INCONCLUSIVE. Not active or automatically selected from old Brain alternatives.
- [E003 / H-004](E003/README.md): independent historical XOR clause-buffer reuse,
  correctness PASS, 48 correct Windows solves; local/controlled INCONCLUSIVE.

[Previous Brain lifecycle decision](../brain/2026-10-07-e001-resume-decision.md)
is superseded for scheduling by the latest user instruction. Keep Windows and server evidence separate; preserve
failed/inconclusive experiments, raw outputs, identities, medians and hypotheses.
A missing median is not zero. No merge or research-grade performance claim.
