# Hypothesis registry (not an execution queue)

Latest experiment: [E004 / H-007 INCONCLUSIVE](experiments/E004/README.md).
Earlier decision: [E001 provisionally shelved / LEARN](experiments/E001/DISPOSITION-2026-10-07.md),
then [literature/program-optimization revision](brain/2026-10-07-round2-research-revision.md). Initial Round 2 priority is superseded.

Lifecycle: BRAIN -> EXECUTE -> EVALUATE -> LEARN -> BRAIN AGAIN.
After resolving the active experiment and recording explicit learning, a fresh
Brain round generates/ranks up to three serious candidates and selects one.
Old unselected candidates have no priority; IDs do not specify execution order.
The latest user instruction permits a fresh Brain after provisional shelving;
it supersedes the earlier resume-only scheduling restriction, not timing gates.

## Provisionally shelved hypothesis

**H-001 — shorten logical bases with one sequential row-XOR pass (E001).**
Selected as #1 by original Brain Round 1; source chat
01a111cd-9e52-7112-ad06-4a4b4a078c0c, approval/restart referenced in the
[original proposal](experiments/E001/PROPOSAL.md). Independently shorten Gx/Gz
copies, original row order, greatest strict reduction, smallest-index tie,
immediate updates, one pass. MaxCDCL application entry only; no engine change.
Practical disposition **SHELVED / NOT ADOPTED**. Controlled status **INCONCLUSIVE**,
Tier 1 controlled evidence absent; correctness PASS; three Windows
numeric filters REJECT. Preserve exact implementation and evaluation rules.
[Disposition / LEARN](experiments/E001/DISPOSITION-2026-10-07.md).

## Previously tested, unpromoted hypotheses

**H-007 — LTO only (E004).** Revised Brain recommendation accepted by user;
independent baseline, one build concept. Tier 0 PASS, 48 diagnostic solves correct.
Small favorable medians but MTO noise envelope fails; occupied host also prevents
promotion. INCONCLUSIVE, no merge. A later user-requested diagnostic Tier 2
stopped twice on CPU capacity; one OFF baseline d=8, no candidate/MTO completion.
No performance comparison or Tier 3. [Learning/evidence](experiments/E004/README.md).
The subsequent Windows attempt also remains INCONCLUSIVE: compiler unavailable
and automatic review rejected installer launch; no new solver samples.
[Windows preparation/result](experiments/E004/TIER2-WINDOWS-RESULT.md).

**H-002 — exact XOR-prefix sharing (E002).** Originally an unselected alternative
from the same old Brain as H-001, not the next queued task. Later executed as an
independent experiment before E001's controlled resolution; this chronology is
preserved, not treated as the required fresh Brain process. Only the candidate
name was recovered; detailed old Brain prose unavailable. Per-build ordered,
signed XOR cache. Correctness PASS; local numeric REJECT, controlled INCONCLUSIVE.
[Evidence](experiments/E002/README.md). Any future revisit must compete in a
fresh Brain with new evidence; Round 2 does not recommend this failed filter.

**H-004 — reduce temporary XOR clause allocations (E003).** Newly proposed
general engineering mechanism, not an old Brain candidate. Independent baseline,
one local clause buffer, identical CNF; correctness PASS, local/controlled
INCONCLUSIVE. [Evidence](experiments/E003/README.md). Preserved historical result,
not active and not an automatically selected follow-up.

## Revised research proposals (current status; not a queue)

The latest user request emphasizes recent MaxSAT papers and ordinary program
optimization. [Research revision](brain/2026-10-07-round2-research-revision.md)
supersedes H-003/H-005/H-006 ranking, without declaring them ineffective.

- **H-007: LTO only.** Selected and tested as E004; INCONCLUSIVE, unpromoted.
  One build setting, no PGO/refactoring; no established controlled speedup.
- **H-008: one bounded SLS warm start.** #2; CP 2025-inspired feasible cap only,
  original-instance verification and exact BnB retained. Not bundled with H-003.
- **H-009: singleton BDD objective-bound encoding.** #3; paper-informed alternative
  to MTO, same cardinality meaning/lifecycle, no AMO assumption or tree reuse.

H-007 has E004 evidence; H-008/H-009 remain proposals, not an execution queue;
Tier 0/1/2 gates unchanged and no Tier 3 authorized by this revision.

## Historical untested candidate hypotheses

**H-003 — verified witness through existing initUB.** Originally unselected,
historically ranked #1 in the initial Round 2 using an independent read-only
committed-input feasibility screen. Not implemented or performance-tested.
Still requires residual-cost/strict-bound/timeout review before implementation.
This is a re-ranking using evidence, not promotion from a FIFO queue.

**H-005 — lookahead long-clause prefetch.** Round 2 #2, unimplemented/untested.
Preserve propagation/search order; memory bottleneck unverified. Not a binary
watch or circular-scan proposal, which the existing engine already implements.

**H-006 — compatible MTO tree reuse when tightening k.** Round 2 #3,
unimplemented/untested; high lifecycle/correctness risk. No bound relaxation or
literal-set change may retain stale constraints. Detailed scope, cost,
risks and falsification for all three: [Round 2](brain/2026-10-07-round2.md).

## Rejected hypotheses

No controlled scientific rejection established. H-001 and H-002 have rejected
local numerical filters, as recorded above; do not relabel those measurements
as dedicated-server evidence. All negative data remain preserved.

## Accepted hypotheses

None. No candidate promoted or merged on these measurements.

## Superseded assumptions

The interpretation of H-001/H-002/H-003 as a FIFO queue is explicitly superseded
by the user's 2026-10-07 correction. Earlier immediate-state text prioritizing
E003 or another optimization before E001 resolution is superseded. This changes
research scheduling/memory, not experimental methodology or scientific semantics.
No hypothesis is declared scientifically obsolete without evidence.

Latest scheduling override: the user provisionally shelves H-001 and requests
three fresh proposals. Historical resume-only statements below describe the
previous state and no longer prohibit this Brain round. No candidate accepted,
merged or combined; controlled performance uncertainty remains preserved.

Latest user-requested Windows E001 repeat 03: 48 new correct solves, 144 total;
local numeric REJECT again, GB regression OFF/MTO. Windows provenance explicitly
recorded; controlled status not relabeled. No fresh Brain/next selection.

Remote yfclab2 evidence reconciled from 7f22d18: 96 additional correct diagnostic
solves across two server CPU pairs; GB regression repeats in both modes with
increased phase-specific search counters. Occupied/core-contention timings do not
resolve the controlled gate. Server/Windows rounds retained separately; H-001
active, no new selection. See E001/SERVER-2026-10-07.md.
