# GH-34 Tier1 result — gate INCONCLUSIVE (not PASS), no regression, ~1% faster direction

Host Apple M6 Mac mini (macOS 27, Apple clang 21), one solve at a time, interactive
desktop, no CPU pinning: **diagnostic local evidence, not controlled**.
Frozen binaries baseline ac43af52…6eb26 / candidate 0549c4ec…61b8b (hashes
re-verified after the run); all 16 input matrix hashes re-verified after the run.
Command and rules: TIER1_RUN.md (committed before launch). Raw: `raw/tier1-01/`
(`samples.json` with every wall time, stdout, telemetry; `result.json`; per-run
stdout/stderr; console log). Single attempt, no reruns.

Science: 208/208 solves exit 0 with the named distance; every emitted
progress/bound line identical between versions for each case/mode. No stop.
Resources: 1-min load before each solve 1.3–4.35 (guard < 6.0 never waited);
summed `ps` %CPU before each solve 7–160% of 1200%.

## Gate phase (preregistered 3+3 AB/BA/AB, unchanged GH16 judge)

| Case | Mode | Baseline median s [range] | Candidate median s [range] | Ratio |
|---|---|---|---|---:|
| BB_90_8_10 | no-card | 1.8799 [1.8521, 1.9187] | 1.8530 [1.8518, 1.8555] | 0.9857 |
| GB_144_12_8 | no-card | 0.6700 [0.6624, 0.6737] | 0.6703 [0.6627, 0.6801] | 1.0005 |
| BB_108_8_10 | no-card | 2.3095 [2.3033, 2.3156] | 2.2790 [2.2621, 2.2838] | 0.9868 |
| LP_238_44_6 | no-card | 1.2036 [1.2011, 1.2146] | 1.2008 [1.2008, 1.2053] | 0.9977 |
| BB_90_8_10 | card-mto | 1.6731 [1.6728, 1.6759] | 1.6481 [1.6462, 1.6499] | 0.9851 |
| GB_144_12_8 | card-mto | 1.1244 [1.1208, 1.1257] | 1.1111 [1.1081, 1.1149] | 0.9882 |
| BB_108_8_10 | card-mto | 2.3428 [2.3425, 2.3431] | 2.3167 [2.3165, 2.3207] | 0.9889 |
| LP_238_44_6 | card-mto | 1.1473 [1.1432, 1.1522] | 1.1480 [1.1414, 1.1502] | 1.0006 |

| Mode | Median-ratio geomean | Envelope geomean | All medians non-worse | Numeric filter |
|---|---:|---:|---|---|
| no-card | 0.99264 | 1.00580 | no (GB144 +0.05%) | not positive |
| card-mto | 0.99068 | 0.99443 | no (LP238 +0.06%) | not positive |

No case has every candidate sample slower than every baseline sample. BB108 OFF and
BB90/GB144/BB108 MTO have every candidate sample faster than every baseline sample.

## Supplementary replication (preregistered 10 alternating pairs; not used by the gate)

| Mode | Per-case ratios BB90 / GB144 / BB108 / LP238 | Geomean | Envelope | Judge would say |
|---|---|---:|---:|---|
| no-card | 0.9854 / 0.9911 / 0.9896 / 0.9927 | 0.98970 | 1.00329 | not positive (envelope) |
| card-mto | 0.9881 / 0.9907 / 0.9887 / 0.9923 | 0.98994 | 0.99861 | positive |

All 8 replication medians favour the candidate; 5 of 8 cells are non-overlapping
improvements; none overlaps in the regressive direction.

## Decision
Formal Tier1 gate: **INCONCLUSIVE**. In no-card both conditions fail: GB144's median
is +0.05% and the envelope geomean is 1.0058 (>= 1). In card-mto the envelope passes
(0.9944) but LP238's median is +0.06%. Both worse medians lie within overlapping
ranges. Not REJECT: no regression flag, scientific results identical, and 14 of the
16 case/mode medians (8 gate + 8 replication) favour the candidate, by about 1%. Not PASS. Under the recorded standing user
instruction (docs/OPTIMIZATION_LOOP_POLICY.md on branch experiment/h001-logical-row-xor,
"User-directed exploratory continuation": if evidence does not clearly justify rejection, advance one tier),
one bounded exploratory LP_340 Tier2 is preregistered in TIER2_EXPLORATORY.md.
It cannot turn this gate into PASS and authorises no Tier3/merge.

Mechanism note (hypothesis, not established): the ~1% could come from removing two
dependent ALU operations from each `value(Lit)` check on a path where ~70% of time is
lookahead propagation. It is not isolated from code-layout/alignment effects (binary
sizes differ, 327656 vs 327304 bytes) and no performance-counter evidence exists; on
an unpinned desktop with 0.67-2.3 s solves that include fork and parsing, ~1% is
within what layout alone can produce.
