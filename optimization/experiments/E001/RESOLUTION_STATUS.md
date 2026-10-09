# E001 current resolution status — 2026-10-07

Superseded for immediate scheduling by the user's later
[provisional shelving / LEARN decision](DISPOSITION-2026-10-07.md).
Controlled INCONCLUSIVE remains unchanged; this retained audit is historical,
not a requirement to continue E001 before the now-authorized Brain Round 2.

**Active experiment: H-001. Decision: INCONCLUSIVE pending controlled Tier 1.**
The user's lifecycle correction restores E001 as the immediate priority. No
fresh Brain round or next hypothesis selected. E002/E003 history is preserved;
old Brain alternatives are not a queue. This audit changes no experiment rule.

## What is available and what is missing

Existing Tier 0 passes on macOS, hosted Linux and Windows. Hosted report has
identical certified pilot distances/objective/bounds and remains valid evidence
for the unchanged E001 source; CI timings are diagnostic only. Two Windows
rounds: 96 complete correct solves, GB regression reproduced in OFF/MTO; local
numeric REJECT twice. These are not exclusive Linux controlled measurements.
No controlled results directory or supplied dedicated-server endpoint/access
and reservation was found in the inspected project/workspace/session. No new
solver/timing run was performed in this audit.

Fresh audit PASS: archive hash, all 914 payloads, 28 baseline/candidate input
identities, exact source/patch against Git, unchanged embedded MaxCDCL/notices,
retained hosted correctness ZIP, six fresh runner gate/parser tests. Audit
record: raw/resolution-audit-20261007.json. Package runner and preregistered
judging rules remain unchanged; no concrete packaging defect found.

Baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a;
candidate code 50623f9710969288d3a9d1c6325f3a72c35ff6d5;
candidate package snapshot 9d68f459019e9c5a20c5c513cf89aaf4a2cd2854;
QDistSAT harness 7c4774fffc49856f48a22ae5f9063d00b2661aaa.
Current audit branch restores that exact E001 application source; E001 changes
only application logical-basis copies, not the downstream MaxCDCL engine.

## Exact external action

Transfer the existing parent-workspace **E001-linux-package.tar.gz** to an
exclusively reserved Linux server. Requires g++, make, zlib development headers,
Python >=3.10; no network fetch or Windows binary required. Reserve selected
physical core and sibling, stop other workloads, keep power/governor stable.
CPU 2 and reservation note below are examples; replace with actual allocation.
Use a new extraction/output directory; do not overwrite prior runs.

```sh
printf '%s  %s\n' 3df26a2e60dd23216c37c3cd2f3dfe07b5173059a383c9ba565e28078973b84e E001-linux-package.tar.gz | sha256sum --check
tar -xzf E001-linux-package.tar.gz
cd E001-linux-package
python3 candidate/optimization/server/run.py --package . --output ../E001-controlled-results --cpu 2 --exclusive-host --reservation-note 'actual exclusive reservation ID'
```

The runner verifies hashes, builds both with identical flags, reruns Tier 0,
then four cases x OFF/MTO x three/version = 48 Tier 1 runs, serial AB/BA/AB.
180s internal limit, 195s watchdog. Original medians/range envelope/per-case
regression gates from PROPOSAL.md apply. Only controlled Tier 1 PASS permits
LP_340_56_8 Tier 2 (12 runs; 600s/615s). No Tier 3 code; no costly later tier
after earlier rejection/inconclusive result. Worst internal budgets 144/120 min
plus build/Tier 0 overhead; earlier estimates ~4.2/~29 min are not guarantees.

Return the **entire E001-controlled-results directory**, including reservation/
environment, compiler/build logs, Tier 0 outputs, binary identities, every raw
stdout/stderr, samples.json and decision.json. Preserve nonzero-exit logs too;
never rerun/discard a sample silently. A reported numeric pass requires reviewing
host stability/exclusivity before it can be adopted. Import as a uniquely named
run under E001/controlled/, then reconcile result.json/STATE/HYPOTHESES.

Alternatively provide a usable server execution path and exclusive reservation.
No password is needed in the experiment record. No PI scientific judgment is
currently required; server execution/access is the concrete missing dependency.

## Provisional knowledge, not a completed LEARN/Brain

The transformation reduces raw logical XOR gates in all six inspected cases,
preserves validated row spaces/syndrome/Pauli objective, but local whole-solve
runtime improves on BB/LP and regresses on GB. Fewer gates alone are insufficient
to predict runtime. Preprocessing stage cost and causal search explanation remain
unisolated; confidence in a specific explanation is low. Controlled performance
and hardware portability remain unknown. After E001 resolves, complete explicit
LEARN before ranking fresh hypotheses; select none now.

Scientific semantics changed: no. No accepted optimization, merge, or controlled
performance claim follows from this audit.

## Publication-time remote reconciliation

Remote 7f22d18 supplies yfclab2 access/continuation records and 96 correct server
diagnostic solves, with repeated GB regression but unresolved contention.
Those records and all raw evidence/tools are now preserved here. Earlier audit
statements about unavailable access describe the then-inspected Windows state;
they do not negate the newly imported remote access record. Controlled isolation
remains the missing scientific measurement condition. See SERVER-2026-10-07.md.
