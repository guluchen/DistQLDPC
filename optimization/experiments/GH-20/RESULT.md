# GH20 final filter record

Decision **INCONCLUSIVE** for research-grade performance; **SHELVE for progression**.
Tier0 PASS. Standard Tier1 completed48 scientifically correct solves, valid_run=true,
numeric filter REJECT. Tier2/3 NOT RUN. No merge, no acceptance, no further local
timing repeats. Candidate remains isolated PR23; all failed attempts and learning retained.

Hypothesis: skip only two identity suffix-copy loops in downstream propagateForLK.
Production candidate3fe5afead91cf0527cd39529a6d48b4e19e12041 / baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a.
Assigned record b7817eac23f3c80ddf1b180c73a0f2ed6c3a0daf;
executed driver dc9029e4f1492f72a3bbd181fffc3979b1a28317743238e08c3c16e2d12c2dde.
Hub15 RUN_ASSIGNMENT6063966390. Support was frozen from reviewed6c33c02 with
only actual assignment URL update. Additional unexecuted runtime-pin commitc670804
remains in history; it was not part of the actual measured driver. No post-start edit.

Same immutable default-O3 Cygwin production binaries/inputs across all48 serial
AB/BA/AB180/195s runs, OFF/MTO3/version/case. Every interim/final bound and output
was validated; no malformed result, wrong distance, crash, timeout or capacity
abort. Owned Job had only runner10392 before release. All job/affinity/sleep/priority
restoration booleans true; final identity checks PASS. This establishes a completed
diagnostic run, not an exclusive research-grade timing environment.

|Case|Mode|Baseline median seconds|Candidate median seconds|Change|Nonoverlap slower range|
|---|---|---:|---:|---:|---|
|BB_90_8_10|no-card|2.728991|2.762621|+1.232%|yes|
|BB_90_8_10|card-mto|3.273038|3.335617|+1.912%|yes|
|GB_144_12_8|no-card|1.159603|1.163851|+0.366%|no|
|GB_144_12_8|card-mto|1.469948|1.478130|+0.557%|yes|
|BB_108_8_10|no-card|3.321593|3.383337|+1.859%|no|
|BB_108_8_10|card-mto|4.245804|4.298548|+1.242%|yes|
|LP_238_44_6|no-card|2.288470|2.317460|+1.267%|yes|
|LP_238_44_6|card-mto|2.701585|2.733446|+1.179%|no|

All8 medians are slower. Median-ratio geometric mean: OFF+1.180%, MTO+1.221%.
Five case/mode ranges have candidate minimum above baseline maximum. Legacy
filter's string "confirmed per-case regression" is its mechanical numeric label;
we do not assert controlled confirmation. Resource telemetry90 rows, global idle
minimum61.40%,9 core-contention flags, no exclusive reservation. Thus the formal
performance state remains INCONCLUSIVE, with negative local evidence and no
positive Tier1 direction. No Tier2 gate passes. Do not infer universal family
regression or general failure of redundant-store elimination.

Learning: actual compiler retained both original loops, and LP136 diagnostics
found2007/4158 theoretical identity stores. Removing them did not produce a
positive lightweight filter. Extra branch cost/code layout is a possible explanation,
not measured causality. Prefer methods with a stronger measured operation
opportunity; keep shared history and independent baseline branches. No paper
origin/BibTeX applies: this method came from direct downstream code inspection.

Next: queue other independent hypotheses; repeat this exact Tier1 on a genuinely
reserved dedicated server only if corroboration is useful, without chasing favorable
Windows repeats. Exact controlled-server commands are in SERVER_TIER1.md.
Raw48 timings, medians, semantic/output/commands, complete telemetry, hashes and
cleanup evidence live in raw/windows-tier1-01. raw-sha256.json covers all retained
evidence as paths relative to raw/; Git blobs are verified under raw/** -text.
