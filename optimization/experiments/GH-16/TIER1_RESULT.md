# H010 Tier1 Windows diagnostic result

Decision **INCONCLUSIVE / NOT ADOPTED**. Tier0 PASS;48 correct solves.

Both mode median geometric means about0.98, but OFF envelope1.0208 and BB108+0.05% do not pass the fixed filter.
MTO envelope0.9987 with allnonworse medians is positive, not controlled evidence. No serious repeated regression.

| Case | Mode | Baseline median s | PGO median s | Change |
|---|---|---:|---:|---:|
| BB_90_8_10 | no-card | 2.891962 | 2.863335 | -0.99% |
| BB_90_8_10 | card-mto | 3.444926 | 3.385826 | -1.72% |
| GB_144_12_8 | no-card | 1.242904 | 1.178589 | -5.17% |
| GB_144_12_8 | card-mto | 1.482880 | 1.447151 | -2.41% |
| BB_108_8_10 | no-card | 3.322285 | 3.323956 | +0.05% |
| BB_108_8_10 | card-mto | 4.245704 | 4.158562 | -2.05% |
| LP_238_44_6 | no-card | 2.259822 | 2.218436 | -1.83% |
| LP_238_44_6 | card-mto | 2.688520 | 2.634486 | -2.01% |

Resource checks85, alerts24 including3 active; minimum globalspare65.883%, minimum siblingidle85.938%.
SingleCPU serial runs preserve all raw timings and telemetry; no exclusive reservation. Allcleanup booleans true, no owned processes remain.
Frozen profile and binary hashes verified before/after. No science/timeout/groundtruth changes. Shared CI times unused.

Root advances one separately preregistered exploratory LP340 under standing user instruction; no formal Tier1 PASS and no Tier3 authorization.
See TIER2_PROPOSAL.md. Further evidence determines next hypothesis, not favorable retries.

Full raw: raw/windows-tier1-01/result.json, samples.json, resources.json, commands/stdout/stderr/affinity and executed-driver.py; manifest raw-sha256.json.
