# Hypothesis registry (not an execution queue)

Recorded decision: [fresh Brain deferred; no next selection](brain/2026-10-07-e001-resume-decision.md).

Lifecycle: BRAIN -> EXECUTE -> EVALUATE -> LEARN -> BRAIN AGAIN.
After resolving the active experiment and recording explicit learning, a fresh
Brain round generates/ranks up to three serious candidates and selects one.
Old unselected candidates have no priority; IDs do not specify execution order.
No fresh Brain while E001 awaits required controlled evidence.

## Active hypothesis

**H-001 — shorten logical bases with one sequential row-XOR pass (E001).**
Selected as #1 by original Brain Round 1; source chat
01a111cd-9e52-7112-ad06-4a4b4a078c0c, approval/restart referenced in the
[original proposal](experiments/E001/PROPOSAL.md). Independently shorten Gx/Gz
copies, original row order, greatest strict reduction, smallest-index tie,
immediate updates, one pass. MaxCDCL application entry only; no engine change.
Status **INCONCLUSIVE**, controlled Tier 1 absent; correctness PASS; three Windows
numeric filters REJECT. Preserve exact implementation and evaluation rules.
[Resolution status / external action](experiments/E001/RESOLUTION_STATUS.md).

## Previously tested, unpromoted hypotheses

**H-002 — exact XOR-prefix sharing (E002).** Originally an unselected alternative
from the same old Brain as H-001, not the next queued task. Later executed as an
independent experiment before E001's controlled resolution; this chronology is
preserved, not treated as the required fresh Brain process. Only the candidate
name was recovered; detailed old Brain prose unavailable. Per-build ordered,
signed XOR cache. Correctness PASS; local numeric REJECT, controlled INCONCLUSIVE.
[Evidence](experiments/E002/README.md). Further execution suspended while E001
is active; any future revisit must compete in a fresh Brain with new evidence.

**H-004 — reduce temporary XOR clause allocations (E003).** Newly proposed
general engineering mechanism, not an old Brain candidate. Independent baseline,
one local clause buffer, identical CNF; correctness PASS, local/controlled
INCONCLUSIVE. [Evidence](experiments/E003/README.md). Preserved historical result,
not active and not an automatically selected follow-up.

## Untested candidate hypotheses

**H-003 — verified witness through existing initUB.** Unselected alternative
from the original Brain Round 1. Unimplemented/untested. Needs witness validation
and bound/timeout semantics review. No priority over newly generated ideas.

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

Latest user-requested Windows E001 repeat 03: 48 new correct solves, 144 total;
local numeric REJECT again, GB regression OFF/MTO. Windows provenance explicitly
recorded; controlled status not relabeled. No fresh Brain/next selection.

Remote yfclab2 evidence reconciled from 7f22d18: 96 additional correct diagnostic
solves across two server CPU pairs; GB regression repeats in both modes with
increased phase-specific search counters. Occupied/core-contention timings do not
resolve the controlled gate. Server/Windows rounds retained separately; H-001
active, no new selection. See E001/SERVER-2026-10-07.md.
