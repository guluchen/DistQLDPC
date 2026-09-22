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
