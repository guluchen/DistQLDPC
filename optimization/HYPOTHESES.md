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

## Other original Brain candidates — unselected

H-002: exact XOR-prefix sharing. H-003: verified witness through existing initUB.
Neither implemented or newly brainstormed here. Do not combine with E001.

No earlier versioned experiment history existed; private prior attempts unknown.
