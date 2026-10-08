# H010 exploratory LP340 Tier2 result

Decision **INCONCLUSIVE / SHELVED / NOT ADOPTED**. No Tier3.

Standing user exception authorized exactly one exploratory advance; Tier1 remains INCONCLUSIVE. Twelve scientifically correct solves, distance/objective/LB/UB8 throughout.
Production source4674331 unchanged; executed support driver hash and frozen binary/profile checks retained.

| Mode | Baseline raw s | PGO raw s | Baseline median | PGO median | Change |
|---|---|---|---:|---:|---:|
| no-card | 66.630217, 68.153623, 66.940680 | 66.582461, 68.100660, 65.474913 | 66.940680 | 66.582461 | -0.535% |
| card-mto | 80.425682, 75.692830, 76.325509 | 76.579457, 84.388814, 72.906122 | 76.325509 | 76.579457 | +0.333% |

Both mode ranges overlap. Original numerical filter INCONCLUSIVE: OFF envelope1.0221, MTO envelope1.1149 and positive median regression0.333%. No serious nonoverlapping regression is established.
Tier1 about2% positive median direction is not reproducibly corroborated here. Large MTO sample spread/interference prevents declaring PGO universally ineffective or useful. No favorable retraining/retry, no merge.

400 resource checks,68 active plus3 preflight contention alerts; minimum globalspare52.632%, minimum siblingidle67.763%.
Capacity always passed; allocation one logical CPU. These are coarse2s samples, not proof of exclusive control or absence of short interference.
All owned processes gone; Job/affinity/priority/sleep restoration true. Frozen binary/profile hashes unchanged before/after.

Learning: this fixed small-training PGO configuration has no robust general improvement evidence. Do not combine it into the next candidate; direct search/per-operation hypotheses remain independently testable.
If controlled server resources become eligible, a future separately planned corroboration can revisit the same frozen configuration. No research conclusion from shared CI or noisy Windows. Exact server commands in SERVER_COMMANDS.md.
Next primary round already registers exactlythree methods in GH22 and selects one symmetric binary-conflict VSIDS activity change; GH20/GH21 independently select watch-tail/O2. Independent branches and gates remain.

Raw: raw/windows-tier2-exploratory-01 retains all stdout/stderr/argv/affinity/timing/science/resource/environment/cleanup/executed-driver; raw-sha256.json covers both rounds and failures.

Independent second-agent audit PASS: all60results/all120emittedbounds, runorder,
limits/medians/envelopes/geomeans/resourcecounts, exactbinary/profile/parser/helper
hashes, originalpackage and594rawGitblobs at152109a verified. Exact report and
executed reviewer script retained in raw/independent-audit-152109a; its workspace
path assumptions describe the historical execution, not a portable standalone
runner. Manifest now includes those two additional witness payloads596total.
