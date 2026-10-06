# Optimization state

Objective: improve DistQLDPC exact CSS distance runtime without changing semantics.
Policy: ../docs/OPTIMIZATION_LOOP_POLICY.md.

Current experiment: [E001](experiments/E001/README.md), approved Brain Round 1 H-001.
Decision: **INCONCLUSIVE — pending controlled run**.
Local Tier 0 correctness: PASS. Hosted QDistSAT PR check: pending.
Tier 1: not run; medians unavailable. Tier 2 blocked. Tier 3 not run.

Latest supported model: sequential row XOR reduces logical chain construction on
all six inspected pilot/Tier 1/Tier 2 cases. LP_238 logical weights/gates decrease
1160 -> 936; LP_340 2220 -> 1688 before simplification. This does not establish
runtime gain. Search behavior can worsen despite fewer clauses.

Next action: run the E001 offline package on an exclusively reserved dedicated
Linux server, preserving baseline/candidate compiler, inputs and limits. Follow
its Tier 0 -> Tier 1 -> conditional Tier 2 gates. Import full controlled result
directory into experiment history and update this state plus HYPOTHESES.
Do not brainstorm a replacement or promote while this result is inconclusive.
No scientific semantics changed. No performance claim or merge authorization.
