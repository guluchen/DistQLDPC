# User-requested LP_340_56_8 diagnostic: INCONCLUSIVE

2026-10-07. The user explicitly requested LTO Tier 2 despite the prior
INCONCLUSIVE Tier 1. See [preregistration](TIER2-DIAGNOSTIC-PROPOSAL.md) and
[bounded recovery amendment](TIER2-RESOURCE-AMENDMENT.md). This is additional
diagnostic evidence, not formal promotion through the original gate.

**No comparable performance result.** Both attempts were stopped by the user's
global spare-CPU rule. One OFF baseline completed; no candidate or MTO solve
completed. No medians, speedup ratio, Tier 2 pass, Tier 3, adoption or merge.
The original Tier 1 INCONCLUSIVE conclusion is unchanged.

| Attempt | CPU / sibling | Completed solves | Outcome |
| --- | --- | ---: | --- |
| 1 | 3 / 131 | 0 | First OFF baseline terminated after 6.026s when global idle reached 47.606%. |
| 2 | 69 / 197 | 1 | OFF baseline completed in 97.587s: d/objective/LB/UB all 8. First OFF LTO candidate terminated after 6.014s when global idle reached 40.334%. |

The ~6s values are interrupted-command durations, not completed solver timings;
they cannot be compared with the 97.587s completed baseline. The single baseline
is not a three-run median. Planned AB/BA/AB repetitions and both modes therefore
remain incomplete; partial attempts are not pooled or silently retried.

## Correctness and identities

Source, matrix inputs and compiler options remain the same LTO-only E004 trial.
No new implementation or build. Reverified all 156 manifest payload hashes and
both binary hashes against prior passed Tier 0 before each attempt:

- Baseline commit 24572d6; binary SHA256
  `055e973e88cc0bb47dfeea236799b02c05d8f2d19b7a50a049125f9057223c0f`.
- Tested candidate 5b13a2c; binary SHA256
  `9923009bb57c1f5ce5c5bfdede9af1b490f944e94f0a1731e0a85da5f0af9cca`.
- Final PR 2efbdc1 differs only in CI serialization; src/Makefile/data unchanged.
- Follow-up driver SHA256
  `f677578933a997900c7451605474d5f7a30be1dfe1343eda32eab0ea712a9c5f`.

Ten guard/parser/gate tests PASS using the actual follow-up driver. Original
server and final PR Tier 0 remain PASS. The completed baseline has the expected
distance 8; interrupted outputs contain no observed invalid distance bounds.
Candidate Tier 2 correctness/comparison is incomplete, not newly certified.
Both exit codes -9 are intentional process-group kills with resource_abort set;
external_timeout is false. No solver crash, internal timeout or semantic mismatch
is inferred from these resource interruptions. Scientific semantics unchanged.

## Resource behavior and learning

Attempt 1 preflight idle 73.749%. After its interruption, three 10-second windows
measured 73.689%, 71.535%, 73.396%; all met the preregistered >55% acquisition
margin. Attempt 2 therefore used a new output directory and freshly observed
CPU pair. Active guard remained >50%, one allocated CPU <= half spare capacity,
before commands and every two seconds during execution. The 55% acquisition
margin did not relax user permission or certify an isolated core.

Attempt 1/2 have 4/53 resource observations; minimum half-spare capacity was
60.94/51.63 logical CPUs versus one allocated CPU. Both stopped at the first
observed global idle violation. Sibling activity was retained as telemetry;
CPU isolation remains deferred. No privileged action or changes to other jobs.

Learning: recent average spare capacity and a quiet core cannot ensure that an
approximately 100s solve remains continuously eligible under the global-capacity
rule. This explains the missing comparison, not the performance of LTO. No
algorithmic conclusion or medium-case extrapolation is supported.

Next action: run the same comparison in a stable window that satisfies the
existing resource rule throughout. Keep both interruptions and start a fresh
registered run; do not promote to Tier 3 or claim a gain from the single baseline.
This turn stops after the bounded second attempt, as preregistered.

## Retained evidence and reproducibility

- [Attempt 1 decision](raw/tier2-attempt1/results/decision.json),
  [command / abort](raw/tier2-attempt1/results/tier2-LP_340_56_8-no-card-1-baseline.command.json),
  [resource telemetry](raw/tier2-attempt1/results/capacity.json).
- [Attempt 2 decision](raw/tier2-attempt2/results/decision.json),
  [one completed sample](raw/tier2-attempt2/results/samples.json),
  [candidate abort](raw/tier2-attempt2/results/tier2-LP_340_56_8-no-card-1-candidate.command.json),
  [resource telemetry](raw/tier2-attempt2/results/capacity.json).
- [Recovery preflight](raw/tier2-recovery-preflight.json),
  [independent audit](raw/tier2-independent-audit.json).
- Full commands, stdout/stderr, environment, prior Tier 0 receipts and binary
  identities are retained in each results directory and its original archive.
  Attempt 1 archive SHA256
  `487bfd7ff7049feb4a731ca351ede652866278edcb20736ae7ef421bb0734ffc`;
  attempt 2 `4047422290bac9be4e3823028c12213804954ed68e6eeb21cba1b97cfb03f113`.

Driver: [idle_tier2_lto.py](idle_tier2_lto.py), reproducible generator
[prepare_tier2.py](prepare_tier2.py). Recheck evidence with
`python optimization/experiments/E004/analyze_tier2.py`.

Exact second command (first used CPU 3/sibling 131 and output tier2-results):

```sh
python3 /home/yfc/codex-e004-lto-20261007/idle_tier2_lto.py \
  --package /home/yfc/codex-e004-lto-20261007/E004-server-package \
  --prior-results /home/yfc/codex-e004-lto-20261007/results \
  --output /home/yfc/codex-e004-lto-20261007/tier2-results-attempt2 \
  --cpu 69 --sibling 197 --allow-core-contention --user-requested-tier2
```

Each attempted solve used `-v -cpu-lim=600 -no-card` and the pinned baseline
LP_340_56_8 matrix prefix, with 615s external watchdog. MTO was planned but never
reached. Server directories remain intact; no benchmark is left running by this
turn after the driver exits.
