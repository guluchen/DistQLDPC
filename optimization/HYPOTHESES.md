# Hypotheses

## H-001: shorten logical bases using one sequential row-XOR pass

Status: selected and explicitly approved in Brain Round 1; implemented as E001;
**INCONCLUSIVE pending controlled run**, not accepted as a performance optimization.

Source: Brain chat 01a111cd-9e52-7112-ad06-4a4b4a078c0c, final answer.
Approval/restart: ChatGPT 6ac503bf-5384-83ee-8551-c06d26ceb216 and current task.
Full hypothesis, mechanism, scope, risks, costs and prior-attempt relation:
[preregistered proposal](experiments/E001/PROPOSAL.md).

Only MaxCDCL's application entry point receives shortened memory copies of Gx/Gz.
Each row in original order chooses its current best strictly reducing partner,
ties by smallest index; apply immediately, one pass only. Rows are not reordered.
Local correctness passed; controlled performance remains unknown.

2026-10-07: same implementation revalidated on MSYS; the original proposal and
selection are unchanged. [Continuation evidence and server package](experiments/E001/CONTINUATION-2026-10-07.md)
are retained. Zero controlled Tier 1 samples; no new hypothesis is selected.

Later [yfclab2 diagnostics](experiments/E001/SERVER-2026-10-07.md) completed
server Tier 0 and 48 Tier 1 samples on one CPU within the user's idle capacity
limit. Results match; GB regresses in both modes while the other three cases
improve. The diagnostic numerical gate rejects, but occupied-host timings do
not resolve the controlled decision. H-001 remains INCONCLUSIVE; no promotion
or replacement hypothesis is selected.

Attempt 5 independently repeats Tier 0 PASS and 48 matching diagnostic solves
on a different CPU pair. GB is again slower (+45.5% OFF, +45.3% MTO), with
identical increased phase-specific search counters. All 96 completed diagnostic
samples are retained as separate rounds. Seven contention checks in attempt 5
leave controlled performance unresolved; no specialization or replacement is
selected from these data.

## Other original Brain candidates — unselected

H-002: exact XOR-prefix sharing. H-003: verified witness through existing initUB.
Neither implemented or newly brainstormed here. Do not combine with E001.

No earlier versioned experiment history existed; private prior attempts unknown.
