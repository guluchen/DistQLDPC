# Optimization loop policy

This policy governs optimization experiments on DistQLDPC. QDistSAT supplies the cross-repo benchmark platform; DistQLDPC is the CSS/QLDPC distance application, with an embedded MaxCDCL engine. Preserve MaxCDCL attribution and the application/engine boundary documented in [NOTICE](../NOTICE) and [MODIFICATIONS.md](../MODIFICATIONS.md). The compute and scientific boundaries in [AGENTS.md](../AGENTS.md) continue to apply.

## Scope and semantic invariants

The research lifecycle is **BRAIN -> EXECUTE -> EVALUATE -> LEARN -> BRAIN AGAIN**.
HYPOTHESES.md is a registry, not a FIFO queue. After resolving an experiment,
record its mechanism, prediction, actual outcome, help/hurt cases, likely
explanation and confidence, and implications for the working performance model.
Then perform a fresh Brain round using all retained evidence: rank up to three
serious candidates by expected impact, success probability and information gain
relative to implementation/semantic risk and experiment cost; select one and
record the reasoning before implementation. Old unselected alternatives compete
equally with newly generated candidates. Preserve negative results.

For the current restart, E001 is the active experiment. Do not start another
optimization while E001 lacks the required controlled evidence. If dedicated
execution/access is unavailable, verify the reproducible package and stop at
that external dependency. An INCONCLUSIVE result does not authorize advancing
gates or automatically executing another old Brain candidate.

**Search space unrestricted, but experiment scope restricted.** Heuristics, branching, restarts, clause management, bound strategy, cardinality encoding, preprocessing, matrix representation, constraint generation, incremental solving, data structures, solver internals, and higher-level formulations are all eligible, provided they preserve scientific semantics.

Each round tests one main hypothesis. Before implementation, read prior accepted and failed experiment records, then write a short proposal: hypothesis, intended change, expected effect, and correctness risk. Supporting changes must serve that hypothesis; do not bundle unrelated optimizations. Revisit a failed idea only with new evidence or a documented change in assumptions.

Never obtain a performance improvement by changing benchmark ground truth, timeout semantics, logging/result semantics, or scientific semantics. Distance, Pauli weight, encoding meaning, lower/upper-bound certification and interpretation, and timeout result behavior must remain correct. If a proposal requires a semantic change, stop and escalate before implementation. Any observed semantic mismatch immediately rejects the candidate and must be escalated to the PI with the evidence; do not proceed to a higher tier.

## Progressive filtering

### User-directed diagnostic screening and server verification (2026-10-08)

The user accepts a two-stage approach to avoid repeatedly aborting inexpensive
screens on brief sibling-core activity. In a preregistered diagnostic screen,
interleave serial baseline/candidate runs on the same CPU and retain interference
telemetry; sibling idle below95% is recorded instead of ending the screen.
Global spare>50%, allocation<=half spare, correctness and timeout guards still
apply. Diagnostic timings do not establish controlled PASS, acceptance, merge
or research-grade speedups. Promising candidates receive a separate complete
controlled repetition on the dedicated server when resources and validated
isolation are available. Do not pool different protocols or retrospectively
relabel earlier aborted runs. Strict isolation/helper guards remain unchanged.
Additional user instruction permits acceptance with minor interference if
repeated evidence establishes that it does not change the performance decision.
Zero interference is not an absolute requirement. Preregister the assessment,
retain all samples and telemetry, verify reproducible gains beyond variability
and no material per-case regression. Equal scientific answers alone do not
establish timing robustness. If interference can change the decision, remain
INCONCLUSIVE; capacity, correctness and tier guards remain mandatory.
The [E006 follow-up record](../optimization/experiments/E006/FOLLOWUP-2026-10-08.md)
records the authorized pending BDD verification and acceptance conditions;
no background monitor is implied. Existing strict executables remain unchanged
until a separately preregistered measurement protocol is implemented.

### User-directed exploratory continuation (2026-10-08)

The user's latest instruction is: if the evidence does not clearly justify
rejection, advance one tier rather than leave available CPU unused. This
supersedes the execution stop on an INCONCLUSIVE gate for explicitly bounded
exploratory follow-ups. It does not turn an inconclusive gate into PASS or
authorize acceptance, merge, or a controlled performance claim. Record the
budget, cases, repeat count and provenance before running; keep correctness,
timeout interpretation and the user's spare-capacity restrictions unchanged.
Confirmed regressions and semantic mismatches still stop advancement.

For H-007, completed Tier 1 and Windows Tier 2 diagnostics justify the requested
next exploratory step: the preregistered single-case BB_144_12_12 Tier 3 pilot.
This is not authorization to launch the complete expensive seven-case suite.
The scientific promotion criteria below remain unchanged.

Run **Tier 0 → Tier 1 → Tier 2 → Tier 3** in order for each candidate. Do not skip a gate because an idea is promising or a previous candidate passed. A changed candidate must re-enter the applicable validation sequence from Tier 0.

- **Tier 0 — correctness/smoke:** compile and run fast deterministic correctness and smoke checks appropriate to the change, including distance, bound, timeout, and result behavior where affected. For solver behavior/performance changes, require the existing [QDistSAT cross-repo benchmark](QDISTSAT_CROSS_REPO_CI.md) PR check (`LP_136_32_4`, `BB_108_8_10`; `-no-card` and `-card-mto`). Passing correctness is required before performance filtering; shared CI timing is diagnostic only.
- **Tier 1 — lightweight performance filter:** run `BB_90_8_10`, `GB_144_12_8`, `BB_108_8_10`, and `LP_238_44_6`. Run each case/configuration three times for both baseline and candidate under comparable controlled conditions; compare per-case medians and retain all raw runs. Promote only with reproducible overall improvement beyond baseline variability and no material per-case regression. Record the aggregation and noise-based decision criteria before comparing results; do not impose an unsupported universal percentage threshold. An inconclusive result does not pass.
- **Tier 2 — medium filter:** run only after Tier 1 passes. Include at least `LP_340_56_8`; record any additional medium cases and the repeat/decision plan before running. Require correctness and improvement direction consistent with Tier 1, without material regression. If Tier 1 gains disappear or reverse, reject the candidate or retain it as a documented specialization hypothesis for a future round; do not promote it to Tier 3.
- **Tier 3 — decisive seven-case set:** run only after Tier 2 passes, on the PI's dedicated server: `BB_144_12_12`, `GB_144_12_12`, `BB_144_14_14`, `LP_442_68_10`, `LP_544_80_12`, `TN_144_2_13`, and `TN_250_10_15`. Use controlled baseline/candidate comparisons and repeat runs as needed to resolve variability. Only controlled dedicated-server runs at this stage support research-grade performance claims; report limitations, regressions, and timeouts as well as improvements.

Confirmed performance regressions automatically reject the candidate without routine PI approval. Distinguish reproducible regressions from timing noise; inconclusive candidates stay at their current gate. Escalate correctness disagreements or scientifically meaningful anomalies under AGENTS.md, rather than ordinary performance failures.

Keep baseline and candidate inputs, resource limits, execution environment, and measurement procedure comparable. Record intended configuration differences and compare each relevant mode separately; do not hide regressions by mixing modes or treating timed-out runs as completed solves. Do not alter timeout limits or reporting behavior to manufacture a pass.

These tiers are experiment policy, not new script modes or a replacement for existing CI. The batch script's default 18-case, advanced four-case, and full 22-case groups do not implement these gates. Select tier cases explicitly. Short representative checks may use the environments permitted by AGENTS.md; any medium run that becomes long or compute-heavy belongs on the dedicated server. Tier 3, full suites, and broad sweeps must not run in Codex Cloud or routine GitHub Actions. If server access is unavailable, prepare the reproducible run package and report the access requirement; do not bypass gates or substitute paid cloud compute without PI approval.

## Experiment memory and acceptance

Keep a durable, discoverable experiment record for every round, including abandoned, failed, rejected, and accepted experiments. Store a versioned record in the repo or link it from a versioned experiment index to durable storage. Do not rely solely on expiring CI artifacts. Each record must contain:

- the hypothesis, proposal, and relevant prior experiment references;
- baseline and candidate commit IDs, a diff summary, and any patch needed to reproduce an uncommitted candidate;
- exact commands, input identities, benchmark harness revision (including QDistSAT when used), configurations/modes, timeout/resource limits, and environment details;
- raw benchmark outputs for every run, including failures and timeouts, plus durable artifact locations;
- per-case medians where repeated (three runs in Tier 1), semantic results/bounds, variability, and the reached tier;
- accept/reject/inconclusive status, the evidence and reasoning for each gate decision, and what the next round should learn from it.

Retain rejected experiments even when reverting their code. The next round must read this history before selecting a hypothesis.

Successful timing alone is not permission to merge. First verify that gains did not come from benchmark, timeout, logging/result, or scientific-semantic changes, and that the required evidence and validation are complete. Routine merges then follow AGENTS.md. Distinguish early filtering evidence from research-grade claims; a Tier 1 or Tier 2 pass is not a research performance conclusion.
