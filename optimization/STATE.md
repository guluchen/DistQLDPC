# Optimization state

Objective: improve DistQLDPC exact CSS distance runtime without changing semantics.
Policy: ../docs/OPTIMIZATION_LOOP_POLICY.md.

Current experiment: [E001](experiments/E001/README.md), approved Brain Round 1 H-001.
Decision: **INCONCLUSIVE — pending controlled run**.
Tier 0 correctness: PASS (macOS, supplemental MSYS, and yfclab2 server runs).
Hosted QDistSAT PR check: PASS on 9d68f45 (same implementation; retained evidence).
Tier 1 controlled gate: not passed. 48 server diagnostic samples are complete;
all scientific results match. Diagnostic numerical gate rejects on GB; controlled
confirmation is pending. Tier 2 blocked. Tier 3 not run.

Latest continuation: [2026-10-07](experiments/E001/CONTINUATION-2026-10-07.md).
The exact H-001 implementation was recovered and reused, not replaced. The
offline archive, checksums and exporter are available; all 56 input identities
were verified. SSH key access to yfclab2 is configured. User authorizes at most
half idle capacity when more than 50% is free. One pinned CPU was used; occupied
host/core conditions prevent controlled promotion. Local standalone maxcdcl has a pre-existing
MSYS link limitation; both distqldpc builds and correctness checks pass.

Latest supported model: sequential row XOR reduces logical chain construction on
all six inspected pilot/Tier 1/Tier 2 cases. LP_238 logical weights/gates decrease
1160 -> 936; LP_340 2220 -> 1688 before simplification. This does not establish
runtime gain. Search behavior can worsen despite fewer clauses.

Latest evidence: [yfclab2 run](experiments/E001/SERVER-2026-10-07.md). Diagnostic
medians improve on BB_90, BB_108 and LP_238 in both modes, but GB_144_12_8 is
50.3% slower OFF and 42.5% slower MTO. Repeated GB phase counters show more
conflicts/starts/UP, consistent with increased search work. This is a warning to
confirm under controlled conditions, not an accepted performance conclusion.
The interrupted first attempt and all later raw outputs are retained.

Next action: run the E001 offline package on an exclusively reserved dedicated
Linux server, resolving the GB warning and preserving compiler, inputs and limits. Follow
its Tier 0 -> Tier 1 -> conditional Tier 2 gates. Import full controlled result
directory into experiment history and update this state plus HYPOTHESES.
Do not brainstorm a replacement or promote while this result is inconclusive.
No scientific semantics changed. No performance claim or merge authorization.

Reservation follow-up: no scheduler or delegated CPU isolation was found for
the yfclab2 account; the read-only audit is retained in the server experiment
record. No additional benchmarks were run. Operator-provided exclusivity or a
different dedicated host is the remaining requirement for controlled timing.
