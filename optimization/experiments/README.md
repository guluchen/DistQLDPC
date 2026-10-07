# Experiment history

E001 is active. Hypotheses are not a queue; fresh Brain follows resolution and LEARN.

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

[Brain lifecycle decision](../brain/2026-10-07-e001-resume-decision.md): deferred,
no new candidate selected. Keep Windows and server evidence separate; preserve
failed/inconclusive experiments, raw outputs, identities, medians and hypotheses.
A missing median is not zero. No merge or research-grade performance claim.
