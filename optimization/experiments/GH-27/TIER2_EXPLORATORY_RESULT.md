# GH27 exploratory LP340 result

Decision INCONCLUSIVE / NOT ADOPTED. Exactly one user-directed exploratory tier
completed; this was not normal Tier1 promotion. Prior Tier1 fixed-filter reject,
not-promoted and formal INCONCLUSIVE remain unchanged. No Tier3 or production merge.
Tier0 PASS remains; all12 larger-case scientific comparisons PASS.

Same single enqueue-prefix conceptual change, production58fbae546e74c158c21070cd10106e94d6bd2b98
against baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a. No rebuild, tuning,
profile, diagnostic or extra benchmark case. Exact successful02 production
binaries reused, original/prior-evidence/source/input/runtime/support/parser/
binary pins passed before and after. Actual support530a1a2a2082f24c4bc4336a0b1a21f1d9ff22db;
driverSHA2568d9bd8afa2aa828e5e702e6495f818f80de0ca262077221c44038a783acdc28b.
Preregistered exceptionbe58053 before assignment6066419326; actual registration
6066430257. Session27360 exit0/FILTER_COMPLETE/valid_runtrue.

Exactly LP_340_56_8, OFF/MTO,3baseline/3candidate each, serialAB/BA/AB12 solves,
600s internal/615s external/10800s aggregate. All completed results report
distance/objective/final LB/final UB8; every interim bound/objective/distance
valid, no crash, timeout, UNKNOWN, malformed field or changed output semantics.
Independent audit verifies actual order, all raw scientific outputs/empty stderr,
argv/return/duration equality and recalculates all medians/ratios.

Raw seconds, in repeat order1/2/3:

| Mode | Baseline raw | Candidate raw | Baseline median | Candidate median | Delta |
|---|---|---|---:|---:|---:|
| OFF | 59.745571,60.639113,60.085560 | 59.950724,60.120306,59.843563 | 60.085560 | 59.950724 | -0.224407% |
| MTO | 66.669779,66.788975,67.138067 | 66.691287,66.606491,66.817352 | 66.788975 | 66.691287 | -0.146264% |

Both complete sample ranges overlap. Unchanged numeric filter INCONCLUSIVE:
median ratios0.9977559250627868 OFF /0.9985373648938277 MTO, but range-envelope
ratios1.006272187146763 /1.0022134961628872. No material reproducible benefit is
established by these tiny positive medians. This does not prove the method has
no effect, nor resolve its mixed near-zero Tier1 behavior.

Actual helper selectionCPU14/sibling15, oneCPU Job mask16384/AboveNormal32768.
379 resource samples, every capacity check eligible; minimum global idle72.697%,
minimum sibling idle87.692%, two contention flags: OFF repeat2 baseline and MTO
repeat3 baseline. Both flagged runs are the slowest respective baseline samples;
this temporal association does not prove interference caused their times or
the candidate median advantage. No samples discarded/corrected/repeated.
Host was not exclusively reserved; controlled confirmation is still required.

Only runner23188 remained before close and was absent afterward. Job/affinity/
priority/sleep restoration alltrue, finalmask65535/Normal32. Resource released
6066680027 before any evidence retention or another workload. Other actors were
restricted to source/CPU0 metadata during this assigned run.

Original raw46-file SHA256 manifest verified in full; all raw commands/stdout/
stderr/timings/result/exception review/prior-evidence pins/resources/cleanup and
exact executed driver retained unchanged in raw/windows-tier2-01. Independent
AUDIT.json carries every exact timing and recalculated value. raw-sha256.json
and raw/** -text protect exact public Git bytes; prior records stay unchanged.

Learning: a larger solve produced only about0.13s OFF and0.10s MTO median saving
in a roughly60–67s solve, within overlapping run variation. High enqueue entry
counts and a verified inline boundary are not sufficient evidence of meaningful
performance benefit. Do not adopt or run Tier3. Leave controlled revalidation
queued if desired, and move to a separately preregistered hypothesis targeting
more substantial repeated solver work; do not tune this candidate after the fact.
