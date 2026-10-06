# QDistSAT cross-repo benchmark

DistQLDPC pull requests are compared against their base commit using the public
QDistSAT benchmark platform.

Current pilot set:
- `LP_136_32_4`
- `BB_108_8_10`

Both DistQLDPC cardinality modes used by QDistSAT are exercised:
- `-no-card`
- `-card-mto`

Policy:
- scientific result mismatches fail CI;
- timing ratios are reported but do not fail CI because shared GitHub runners are noisy;
- full research benchmark suites remain manual / dedicated runs, not normal PR CI.

The workflow uploads JSON and Markdown reports as an Actions artifact.

## Relationship to optimization experiments

QDistSAT is the benchmark platform; DistQLDPC is the solver application being compared, with an embedded MaxCDCL engine. This pilot check contributes correctness/smoke evidence to Tier 0 of the [optimization loop policy](OPTIMIZATION_LOOP_POLICY.md). Its case selection and both cardinality modes remain unchanged.

The pilot is not the Tier 1 lightweight performance filter, even though `BB_108_8_10` appears in both sets. Passing shared CI, or observing a faster CI timing, does not satisfy performance promotion gates. Follow Tier 0 → Tier 1 → Tier 2 → Tier 3 without skipping gates; Tier 3 and research-grade performance claims require controlled dedicated-server runs. Retain raw CI reports used as experiment evidence in durable storage before Actions artifacts expire.
