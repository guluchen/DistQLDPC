# Independent optimization agents through GitHub

User clarification2026-10-08: each agent independently proposes three methods,
selects one, and shares experiments/learning through GitHub. Agents cooperate
through accumulated evidence, not by splitting H010 implementation into roles.
Subsequent user instruction: repeat BRAIN(three) -> SELECT(one) -> ANALYZE/EXECUTE
-> EVALUATE/LEARN -> BRAIN until a feasible optimization has reproducible,
scientifically correct supporting evidence. A rejected round does not end the
overall task; each new attempt needs fresh rationale, not outcome-seeking retries.

Coordination hub: [GitHub issue15](https://github.com/guluchen/DistQLDPC/issues/15).
Reusable instruction: [AGENT_PROMPT.md](AGENT_PROMPT.md).
Initial setup created records/protocol only. Execution now proceeds in each
independent issue/PR: primary PGO [PR19](https://github.com/guluchen/DistQLDPC/pull/19)
and scratch reuse [PR18](https://github.com/guluchen/DistQLDPC/pull/18).
Use hub comments for latest ownership, reached gates and results.

Initial selection: [primary agent issue16](https://github.com/guluchen/DistQLDPC/issues/16),
three proposals H010/H011/H012, H010 selected/UNTESTED. Other agents independently
choose their own three and one selection; H011/H012 are unselected opportunities,
not compulsory assignments. GitHub's new-issue template
[agent-experiment.md](../../../.github/ISSUE_TEMPLATE/agent-experiment.md)
supplies consistent fields for copying into issues. It is stored on the history
branch; automatic display in GitHub's issue chooser requires a separately
reviewed publication to the default branch. This setup does not merge it.

## Sources of truth

- Experiment source baseline: `24572d6d09cce9a4a5faa58300a89e0feba9da6a`.
- Current policy/history: branch `experiment/h001-logical-row-xor`, including
  AGENTS, README, MODIFICATIONS, NOTICE, cross-repo CI/policy docs, optimization
  STATE/HYPOTHESES, Round5 and E001–E006 records. Read current docs through GitHub
  even when the baseline checkout predates them. Never include that branch's
  H001 code in a fresh baseline just to obtain updated documentation.
- GitHub issue per experiment: owner, three proposals, selection, exact scope,
  state, dependencies, result and links. Hub comments discover independent work.
- Durable repository/storage records: raw data, commands, hashes and learning.
  GitHub comments summarize evidence; they do not replace it.

## Register independent work

Each agent chooses a unique descriptive session ID and creates an issue titled
`[Agent experiment] <agent-id>: <selected mechanism>`. Before selection, read
open/closed experiment issues and historical records. Show three candidates,
their sources, mechanism, expected cases, scope, risks, costs and relation to
previous trials; rank and select exactly one. Unselected proposals remain visible.

Use `GH-<issue>-A/B/C` for that issue's hypothesis IDs and `GH-<issue>` for its
experiment record. Existing H010/H011/H012 belong to the primary Round5; other
agents must not independently allocate H013/E007 and collide. Integrator may
later assign global IDs while preserving aliases and evidence.

Post a registration comment in issue15:

```text
REGISTER agent=<session-id> issue=<URL> selected=<hypothesis-id>
baseline=24572d6d09cce9a4a5faa58300a89e0feba9da6a
mechanism=<precise operation and scope> branch=<unique branch>
status=PROPOSED host-slot=NONE
```

Then reread hub comments and current issues before coding: searches may lag.
Compare actual mechanism/configuration, not titles. Same active original
hypothesis: lower issue number retains it; the other agent records a different
selection, or explicitly proposes a replication with new information sought.
Preserve the original proposals/selection history. Different parameter values
do not automatically establish a new concept. Past rejected work can be revisited
only with a new rationale. Ambiguous equivalence goes to the integrator; it need
not stop unrelated investigation.

Issue comments are a coordination protocol, not an atomic distributed lock.
They do not trigger agents automatically. The integrator resolves ownership
conflicts; exact duplicates must not quietly consume two experiment budgets.

## Isolated implementation and review

Use a separate checkout/worktree and branch per experiment, for example
`experiment/gh-17-my-agent`. Start from the exact baseline, not another agent's
candidate. Check repository instructions and existing worktree ownership before
creating/reusing a checkout. One performance concept per diff; supporting tests,
build infrastructure and attribution changes must directly serve that concept.

Write `optimization/experiments/GH-<issue>/PROPOSAL.md` before implementation.
Store local bibliography additions beside that record; the integrator reconciles
the shared bibliography and STATE/HYPOTHESES after review, preventing concurrent
index edits. Cite exact paper/version/section and preserve BibTeX; identify
ordinary engineering ideas honestly. Inspect actual downstream solver behavior
before attributing an absent mechanism or transplanting upstream code.

Create an independent draft PR referencing the issue, immutable baseline and
conceptual diff. Attach it to the agent's task when tools support attachment.
Request independent review of a pinned SHA. Evidence must identify candidate,
baseline, profiles, compiler/options, inputs, binaries and harness. Candidate
changes invalidate dependent checks. Do not self-merge, force-push others' work,
or combine successful ideas without a separate interaction experiment.

## Resource and gate coordination

Code reading/proposal research can run in parallel. Timed work uses one named
benchmark runner per host and an explicit queue in issue15. The primary execution
task is initially the scheduler/integrator; no host runner is assigned by setup.
Agents prepare packages and request `RUN_REQUEST`, rather than each starting
benchmarks after noticing idle CPU. A scheduler issues one `RUN_ASSIGNMENT`
containing runner, issue, candidate SHA, host, case/mode budget and time window.
No assignment means no timed work. Handoff/release is recorded in the hub.

This is a procedural queue, not automatic CPU isolation or a tested distributed
lease. Only the assigned runner launches jobs; existing hardware/helper controls
still require validation. If simultaneous assignments appear, stop launching
and resolve the conflict. Do not modify other users' processes or privileges.

Team aggregate use must satisfy user's global spare>50% and at most half spare
capacity. Baseline/candidate run serially on the same CPU, with sibling telemetry;
never place competing versions/experiments on sibling cores. Builds, training
and other significant work also need resource accounting. Independent hosts can
have separate runners after their eligibility/protocol is verified.

Tier0 scientific/smoke/build and required cross-repo correctness checks precede
performance. Semantic mismatch, incorrect distance/bound, crash or output/
timeout regression immediately rejects and stops; report to PI. Tier1 has
BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, baseline/candidate three times
each, OFF/MTO separately, raw timings/medians/science retained. Standard Tier2
LP_340_56_8 follows reproducible positive direction and no serious regression.
Any user-authorized exploratory exception must be separately preregistered and
does not make a failed/inconclusive gate PASS. No Tier3 launch from setup.

Follow existing diagnostic/controlled policy. Minor contention can be retained
with telemetry; a robust acceptance decision still requires evidence that it
does not change the conclusion. Shared CI timing is informational. No controlled
window means prepare a reproducible package and record INCONCLUSIVE; do not
fake a conclusion or repeatedly retry until favorable.

## Publish learning, including failures

States are distinct: PROPOSED, REGISTERED, IMPLEMENTING, TIER0_READY,
TIER0_PASS, WAITING_FOR_HOST, RUNNING, REVIEW_READY, COMPLETE. Gate status is
PASS/REJECT/INCONCLUSIVE; disposition is ACCEPT/REJECT/INCONCLUSIVE and separate
from merge state. Preparation/review completion does not mean performance PASS.

Update each issue with this result record:

```text
agent / issue / selected hypothesis / exact mechanism
baseline SHA / candidate SHA / PR
Tier0 science result / reached tier / gate decisions
raw artifact location / SHA256 manifest / commands / compiler / inputs
per-case medians and variability / contention and capacity / cleanup
disposition and reason / limitations / mechanism observations
what the next agent should learn / follow-up prerequisites
```

Commit raw data or link durable storage before CI artifacts expire. Keep failed,
aborted and inconclusive records; do not close them as successful adoption.
Integrator updates shared registry/state/source map without replacing earlier
evidence, then posts a hub summary. Each next agent reads that accumulated
experience before its fresh three-proposal Brain round. The pinned baseline
changes only through an explicit reviewed decision.
