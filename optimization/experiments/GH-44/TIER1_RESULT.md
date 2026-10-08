# GH44 Tier1: local REJECT / NOT ADOPTED

All48 scientific solves PASS. The preregistered generic fixed-v3 candidate fails
the lightweight filter because three groups have large, disjoint regressions.
No Tier2 or Tier3. Production remains isolated in this unmerged experiment.
Controlled universal performance remains INCONCLUSIVE because this Windows Job
does not exclusively reserve CPU resources; that limitation is not a reason to
promote a practically negative global candidate or silently select faster groups.

Assignment https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6068824846
Frozen support `fcc6bba217ef312f5b2c507e11b34f3266410dcf`, driver SHA256
`a68ebbd4e1f47b9de0d9bbcb58130162cb117972493fdc0eab397e37ceb51154`.
Fresh GH44-windows-tier1-01/session3919 exit0, FILTER_COMPLETE valid_run=true.
Original successful Tier0 binaries unchanged; no rebuild/tuning/profile/diagnostic.
The fresh helper-selected CPU14/sibling15 passed portable ISA/OS gate before any
v3 solve; one CPU mask16384/AboveNormal32768, fixed AB/BA/AB180/195/10800 policy.
The two corrected inherited prerecord paths were caught and repaired before
execution (7876d47), with no failed performance attempt or discarded timing.

Each median uses baseline3 and candidate3; all raw values are in
`raw/windows-tier1-01/samples.json` and `AUDIT.json`, with original stdout/stderr,
exact argv and command elapsed. Seconds:

| Case | Mode | Baseline median | Candidate median | Change | Sample ranges |
|---|---|---:|---:|---:|---|
| BB_90_8_10 | OFF | 2.478827100 | 2.826532300 | +14.027% | disjoint slower |
| BB_90_8_10 | MTO | 2.978203500 | 2.518250900 | −15.444% | disjoint faster |
| GB_144_12_8 | OFF | 1.039070600 | 1.085263000 | +4.446% | overlap |
| GB_144_12_8 | MTO | 1.342413200 | 1.746294400 | +30.086% | disjoint slower |
| BB_108_8_10 | OFF | 3.026390600 | 3.485769500 | +15.179% | disjoint slower |
| BB_108_8_10 | MTO | 3.859629400 | 3.549503900 | −8.035% | disjoint faster |
| LP_238_44_6 | OFF | 2.101004200 | 1.939222600 | −7.700% | disjoint faster |
| LP_238_44_6 | MTO | 2.506270000 | 1.871227600 | −25.338% | disjoint faster |

Median ratio geometric means: OFF1.0607621665 (+6.076%), MTO0.9322323542 (−6.777%).
Original numeric filter: reject / confirmed per-case regression. Its early-return
details contain the first regression; all eight groups and ranges independently
recomputed and retained, including the favorable groups. No posthoc subset policy.

Every interim/final LB/UB/d/objective and return/status,48 exact known results,
sample order/argv/elapsed, empty scientific stderr and original159 manifest
payloads independently reparsed/verified. Full10216 runtime hashes/exactfileset,
all successful Tier0 raw identities, inputs/source/support/binary pins unchanged.
No scientific anomaly, wrong result or timeout occurred.

All80 resource samples eligible;1 preflight contention flag (LP238OFF candidate
repeat3). Minimum global idle88.263%, sibling95.522%. This single flag is recorded
without claiming it caused any timing difference; absence of observed interference
is not exclusive reservation. No shared CI elapsed used. Only runner18132 before
Job release; actual runner absent after exit; every cleanup remaining[]/confirmed,
all4 restorations PASS, final mask65535/Normal32. Immediate release:
https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6068916180

Learning: ISA-level code generation can produce large, case/mode-dependent timing
differences, yet a global v3 switch is not safe to adopt for this workload. Original
FP contraction `fast` plus new FMA availability can affect search rounding; layout
and instruction selection are alternative explanations. This run does not isolate
any cause, measure vectorization, prove a FMA mechanism, or reject every ISA family.
A faster-mode-only or FMA-disabled target would be a separately preregistered
hypothesis from the immutable baseline, not a repair or accepted subset of GH44.
Next: retain this failed proposal, search shared history, independently propose
exactly three new concepts and select one with explicit impact/risk evidence.
