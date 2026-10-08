# E006 exploratory Tier2: LP340 local REJECT, candidate not adopted

2026-10-08. Explicit user request "跑tier2看看" after the Tier1 local REJECT;
[preregistered exception](TIER2-PROPOSAL.md), not a Tier1 PASS or ordinary
promotion. Same independent baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a
and BDD candidatec91b19bbf29a28a6e808c8ef2c328cb9cef784e8. No solver, scientific,
input, build or optimization change. Source/runtime/binary identities and
existing local/required hosted Tier0 PASS rechecked before the run.

**Decision: local Tier2 numeric REJECT; keep the current general-purpose BDD
replacement REJECT / NOT ADOPTED.** LP340 affected-mode three-repeat median
regresses6.75%, with fully disjoint ranges. This medium case does not reverse
Tier1's BB108/LP238 failures or justify a specialization. No Tier3, merge or
new optimization. Dedicated-server performance remains INCONCLUSIVE/unmeasured;
future server corroboration is distinct from these local diagnostic results.

## Execution and exact results

One local Windows worker, fixed CPU14/sibling15, mask16384, AboveNormal32768
owned-job priority for both versions and every observed fork child. Balanced
power scheme retained. LP_340_56_8 only, OFF and original MTO selector (candidate
MTO=BDD), serial AB/BA/AB, three repeats/version/mode,12 solves.600s original
parent wall limit/615s watchdog, no retry. Explicit --allow-core-contention
records interference instead of aborting; global spare>50% and one worker
<=half spare remain mandatory. All12 complete with d/objective/LB/UB8,
no crash, UNKNOWN or timeout. No partially completed timings or dropped samples.

| Mode | Baseline raw seconds | Candidate raw seconds | Baseline median | Candidate median | Ratio |
|---|---|---|---:|---:|---:|
| OFF | 68.464964,69.116279,67.623322 | 67.211219,67.433143,67.383368 | 68.464964 | 67.383368 | 0.984202 |
| MTO / BDD | 75.093664,75.425213,75.259370 | 79.811001,80.338636,80.925249 | 75.259370 | 80.338636 | 1.067490 |

OFF median improves1.58%, but OFF does not invoke the BDD constructor; do not
attribute that difference to BDD encoding. The affected-mode baseline range
75.093664--75.425213s and candidate79.811001--80.925249s do not overlap.
Every candidate solve is slower than every baseline solve. Retained existing
numeric gate rejects this per-case regression; no universal threshold or
post-hoc case/parameter selection. Both modes remain visible and unpooled.

## Resource observations and independent audit

405 observations:393 active and12 preflight. Five active sibling interference
alerts, one preflight alert; minimum active sibling idle77.702703% and minimum
global idle56.247335%. No capacity loss/abort. These alerts were preserved
without ending the run, implementing the user-directed diagnostic policy.
Do not claim zero interference or continuous exclusive access. Resource
telemetry sampled every2s cannot independently prove timing effects absent.
MTO baseline/candidate repetitions1 and3 each have no active interference
alerts and still show the slower candidate direction. Repeat2 has one alert
on each version, with unequal severity; keep it in the complete triplets and
do not derive a selected-subset median. These observations characterize the
negative direction without proving the exact interference contribution.

[Independent Tier2 audit](raw/tier2-windows-exploratory-01/independent-tier2-audit.json)
PASS verifies156 original payloads, candidate source/binary identities, hosted
receipts, exact LP340 commands/limits/input/cwd, full raw results/bounds,
AB/BA/AB triplets, medians/ranges, all observed parent/fork-child masks/priorities,
global/half-spare capacity and six cleanup fields. The per-run resource rows
retain interference counts and minimum sibling idle alongside elapsed time.
Job limit released, affinity65535, Normal priority32 and sleep requirement
restored. Original baseline22e398cc.../candidate990f7c97... SHA256 retained.
No other applications or privileged isolation settings changed.

Original runner and audit retain INCONCLUSIVE as the dedicated/diagnostic
performance status alongside numeric_filter=reject. [Reconciled decision](TIER2-DECISION.json)
states the scope: reject current general-purpose replacement on the local
filters; controlled dedicated corroboration is pending. Historical receipts
remain unchanged. Minor interference is not an automatic veto; here the
affected-mode repeated slowdown, rather than the presence of alerts, drives
non-adoption. Do not claim a controlled-server6.75% slowdown from this screen.

## Learning, provenance and next action

The first complete Tier1 already showed BDD helping BB90/GB144 and hurting
BB108/LP238. This separately requested medium case also hurts the affected
mode; increasing problem size did not produce evidence supporting acceptance.
Original downstream search/BDD node/auxiliary/clause and phase counters are
retained, with [phase-counter extraction](raw/tier2-windows-exploratory-01/search-observations.json).
They help locate work differences but do not establish causation or total
work from a single phase. New bound-representation ideas should first inspect
propagation/search costs; do not infer that smaller graphs or literature
results guarantee faster downstream distance solving.

Method source and BibTeX now preserved per the user's new instruction:
vandesande2025certifiedextended (exact arXivv1 section0.4/appendix.9 read) and
vandesande2026certified (published AAAI paper), [source/adaptation mapping](../../REFERENCES.md)
and [references.bib](../../references.bib). The paper studies certification of
known encodings; this trial's singleton-unit adaptation is ours, not a claim
to reproduce its full upstream MaxCDCL method. H008's earlier CP2025 SLS source
and BibTeX are also recorded, without changing its experiment.

Next: keep candidatec91b19b isolated/unmerged, preserve both failed local
filters, and use a fresh Brain before another optimization. The user-requested
future complete server Tier1 corroboration remains pending a validated window;
use existing prepared commands/lease prerequisites, never overwrite/pool these
rounds. This Tier2 request does not authorize an expensive Tier3 run. No
background monitoring or recurring schedule was created.
