# Optimization loop policy

This policy governs optimization experiments on DistQLDPC. QDistSAT supplies the cross-repo benchmark platform; DistQLDPC is the CSS/QLDPC distance application, with an embedded MaxCDCL engine. Preserve MaxCDCL attribution and the application/engine boundary documented in [NOTICE](../NOTICE) and [MODIFICATIONS.md](../MODIFICATIONS.md). The compute and scientific boundaries in [AGENTS.md](../AGENTS.md) continue to apply.

## Scope and semantic invariants

**Search space unrestricted, but experiment scope restricted.** Heuristics, branching, restarts, clause management, bound strategy, cardinality encoding, preprocessing, matrix representation, constraint generation, incremental solving, data structures, solver internals, and higher-level formulations are all eligible, provided they preserve scientific semantics.

Each round tests one main hypothesis. Before implementation, read prior accepted and failed experiment records, then write a short proposal: hypothesis, intended change, expected effect, and correctness risk. Supporting changes must serve that hypothesis; do not bundle unrelated optimizations. Revisit a failed idea only with new evidence or a documented change in assumptions.

Never obtain a performance improvement by changing benchmark ground truth, timeout semantics, logging/result semantics, or scientific semantics. Distance, Pauli weight, encoding meaning, lower/upper-bound certification and interpretation, and timeout result behavior must remain correct. If a proposal requires a semantic change, stop and escalate before implementation. Any observed semantic mismatch immediately rejects the candidate and must be escalated to the PI with the evidence; do not proceed to a higher tier.

## Progressive filtering

Run **Tier 0 → Tier 1 → Tier 2 → Tier 3 → Tier 4** in order for each candidate. Do not skip a gate because an idea is promising or a previous candidate passed. A changed candidate must re-enter the applicable validation sequence from Tier 0.

- **Tier 0 — correctness/smoke:** compile and run fast deterministic correctness and smoke checks appropriate to the change, including distance, bound, timeout, and result behavior where affected. For solver behavior/performance changes, require the existing [QDistSAT cross-repo benchmark](QDISTSAT_CROSS_REPO_CI.md) PR check (`LP_136_32_4`, `BB_108_8_10`; `-no-card` and `-card-mto`). Passing correctness is required before performance filtering; shared CI timing is diagnostic only.
- **Tier 1 — lightweight performance filter:** run `BB_90_8_10`, `GB_144_12_8`, `BB_108_8_10`, and `LP_238_44_6`. Run each case/configuration three times for both baseline and candidate under comparable controlled conditions; compare per-case medians and retain all raw runs. Promote only with reproducible overall improvement beyond baseline variability and no material per-case regression. Record the aggregation and noise-based decision criteria before comparing results; do not impose an unsupported universal percentage threshold. An inconclusive result does not pass.
- **Tier 2 — medium filter:** run only after Tier 1 passes. Include at least `LP_340_56_8`; record any additional medium cases and the repeat/decision plan before running. Require correctness and improvement direction consistent with Tier 1, without material regression. If Tier 1 gains disappear or reverse, reject the candidate or retain it as a documented specialization hypothesis for a future round; do not promote it to Tier 3.
- **Tier 3 — decisive six-case set:** run only after Tier 2 passes, on the PI's dedicated server: `BB_144_12_12`, `GB_144_12_12`, `BB_144_14_14`, `LP_442_68_10`, `LP_544_80_12`, and `TN_144_2_13`. Use controlled baseline/candidate comparisons and repeat runs as needed to resolve variability. Only controlled dedicated-server runs at this stage support research-grade performance claims; report limitations, regressions, and timeouts as well as improvements.
- **Tier 4 — hard set (PI decision 2026-10-11):** run only after Tier 3 passes, on the PI's dedicated server: `TN_250_10_15` (moved from Tier 3), `BB_288_12_unknown`, and `LP_714_100_unknown`, in the same cardinality modes as Tier 3. The per-case time limit is set from measured runs of the current main baseline (reference: a 6-hour feasibility probe of main; record the limit and its source before any candidate comparison). For cases whose distance is not certified (`unknown`), compare proven lower bounds, upper bounds and time to the final result, and treat a newly certified distance as a scientific result that must be independently verified before it is reported or used to rename a benchmark. Report timeouts and bound progress, not only solve times.

Confirmed performance regressions automatically reject the candidate without routine PI approval. Distinguish reproducible regressions from timing noise; inconclusive candidates stay at their current gate. Escalate correctness disagreements or scientifically meaningful anomalies under AGENTS.md, rather than ordinary performance failures.

Keep baseline and candidate inputs, resource limits, execution environment, and measurement procedure comparable. Record intended configuration differences and compare each relevant mode separately; do not hide regressions by mixing modes or treating timed-out runs as completed solves. Do not alter timeout limits or reporting behavior to manufacture a pass.

These tiers are experiment policy, not new script modes or a replacement for existing CI. The batch script's default 18-case, advanced four-case, and full 22-case groups do not implement these gates. Select tier cases explicitly. Short representative checks may use the environments permitted by AGENTS.md; any medium run that becomes long or compute-heavy belongs on the dedicated server. Tier 3, Tier 4, full suites, and broad sweeps must not run in Codex Cloud or routine GitHub Actions. If server access is unavailable, prepare the reproducible run package and report the access requirement; do not bypass gates or substitute paid cloud compute without PI approval.

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
