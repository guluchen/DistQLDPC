# H-007: completed exploratory BB144 Tier 3 pilot

Decision **INCONCLUSIVE**, not rejected or accepted. The user's clarification
explicitly permits one exploratory tier forward when evidence cannot clearly
reject a method. This execution supersedes the previous stop on uncertainty;
it does not relabel Tier 1/2 as controlled PASS. See the
[preregistered proposal](TIER3-PILOT-PROPOSAL-2026-10-08.md) and
[execution policy](../../../docs/OPTIMIZATION_LOOP_POLICY.md#user-directed-exploratory-continuation-2026-10-08).

## Scope and identity

Same hypothesis: GCC link-time optimization reduces execution overhead without
changing encoding, scientific results or intended search behavior. The only
candidate performance change remains `LTO=1`, adding `-flto=1` at compile/link.
No new solver change, second optimization, source refactoring or rebuild.
DistQLDPC includes its own downstream MaxCDCL instrumentation and patches;
QDistSAT is the pinned benchmark platform, not an identical upstream solver.
NOTICE/MODIFICATIONS unchanged because the engine patch set is unchanged.

Baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a; tested candidate
5b13a2c01b6e0a4dec6a88ad5bbccdbf15df2030. Final draft PR candidate 2efbdc1
differs only by CI serialization. Original GCC 13.3 Ubuntu 24.04 Linux binaries
and 156-file package matched prior verified identities. Tier 0 PASS reused only
after matching both source/package and binary hashes. Previous Linux/Windows
Tier 1 and completed Windows LP340 Tier 2 remain separate diagnostic rounds.

Four BB_144_12_12 inputs exported from both commits match byte-for-byte;
[input manifest](tier3-input-manifest.json) records their hashes. Expected 12
is checker-only and was not supplied to the solver. One baseline/candidate pair
per OFF/MTO mode, baseline first. Internal wall timeout 600s; external watchdog
615s. All four serial solves finished within budget, with no timeout or abort.
This is one Tier 3 case, not the complete decisive seven-case suite.

## Raw results and validation

| Mode | Baseline seconds | LTO seconds | Candidate/baseline |
| --- | ---: | ---: | ---: |
| OFF | 50.39377679792233 | 49.3852917838376 | 0.9799879056866739 |
| MTO | 54.13965743780136 | 43.57445110799745 | 0.8048527303309628 |

All four return codes 0; distance/objective/LB/UB 12; no UNKNOWN, timeout,
unexpected crash or contradictory intermediate bound. Independent audit PASS.
Baseline/candidate stdout is byte-identical within each mode, including available
search counters. OFF final hardConflicts 4960, nbLK 310793, nbLKup 265994849;
MTO 5840, 355837, 290645914. These observations are compatible with unchanged
logged search work, not proof of identical execution or a performance mechanism.
No medians or reproducibility inference from singleton timings.

Host yfclab2: CPU66 pinned, sibling194 observed; one worker and children inherit
affinity. Five-second preflight idle 75.3103%, both threads initially 100% idle.
No exclusive lease or root helper changes. 101 resource checks, minimum global
idle 63.14499%; one CPU stayed within half spare capacity. Core contention was
observed 76 times. Per-run contention checks: OFF baseline26/26, candidate25/25;
MTO baseline20/28, candidate5/22. Sibling minimum idle was 0% in both OFF runs
and MTO baseline, 85.2792% in MTO candidate. The lower MTO contention is a material
confounder; the apparent 19.5% reduction cannot be attributed to LTO. Monitoring
every two seconds does not rule out shorter scheduling/interference changes.

## Learning and next action

BB144 has exact completion and favorable singleton direction in both modes;
there is no observed correctness failure or evidence sufficient to reject LTO.
The large MTO timing difference is not established as a compiler benefit.
Confidence high in retained result checks, low in speedup size and reproducibility.
This advances execution while keeping scientific adoption pending; no merge.

Next recommended bounded experiment: complete three baseline/candidate repeats
for this Tier 3 case in each mode with alternating order and per-run contention
evidence before expanding expensive case coverage. This would test whether the
MTO signal persists when contention is comparable. A genuinely controlled window
is still required before accepting a research performance claim; uncertainty
alone no longer forces CPU use to stop or restarts Brain prematurely.

## Reproduction and evidence

Exact executed command (use a fresh output directory and freshly eligible CPU
pair on replay; do not reuse the historical idle snapshot):

```sh
/usr/bin/python3 /home/yfc/codex-e004-lto-20261007/idle_tier3_pilot_lto.py \
  --package /home/yfc/codex-e004-lto-20261007/E004-server-package \
  --output /home/yfc/codex-e004-lto-20261007/tier3-bb144-pilot-01 \
  --prior-results /home/yfc/codex-e004-lto-20261007/results \
  --user-requested-tier3 \
  --input-root /home/yfc/codex-e004-lto-20261007/E004-tier3-bb144-inputs \
  --cpu 66 --sibling 194 --allow-core-contention
```

Each command record contains exact binary/input paths, `-v -cpu-lim=600`
and `-no-card`/`-card-mto`. [All raw evidence](raw/server-tier3-bb144-pilot-01)
includes commands, stdout/stderr, timings, environment, CPU selection, capacity,
original executed driver, prior validation, decision and independent audit.
The completed remote archive `tier3-bb144-pilot-01.tar.gz` SHA256 matches the
download: `323029496ad2bdb31423aecd9d3f9007042e373ae964c86751b13a77f6dbdf56`.
The independent audit was added locally after extraction and is not in that
original archive. Recompute from retained evidence:

```sh
python optimization/experiments/E004/audit_tier3_pilot.py \
  optimization/experiments/E004/raw/server-tier3-bb144-pilot-01
```

Files changed this follow-up: experiment proposal/result, input manifest,
pilot driver/audit, raw evidence, STATE/HYPOTHESES, E004 index and policy
clarification. Candidate optimization diff remains unchanged.
