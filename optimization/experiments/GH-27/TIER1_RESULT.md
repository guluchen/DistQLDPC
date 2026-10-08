# GH27 standard Tier1 result

Formal decision INCONCLUSIVE; local fixed numeric filter REJECT / NOT PROMOTED.
No adoption, production merge or automatic Tier2/3. All48 scientific solves PASS.
The small mixed performance direction does not establish an improvement or a
universal failure of prefix inlining. Controlled confirmation remains pending.

One conceptual enqueue-prefix change, production58fbae546e74c158c21070cd10106e94d6bd2b98
against baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a. No rebuild, profile,
diagnostic or tuning in this run; exact successful Tier0 binaries reused.
RUN_ASSIGNMENT6066022135; actual supportdc2ef350833ff22f67a9fd21e111971b42bfb6bc;
driverSHA256fd0716aed58d5217dd327ed14aae36c026d1f5ac371fa6a6c42526779ea16fc3.
Registration6066047992 had a wrong short commit transcription, corrected before
execution at6066053132; actual required --support-sha/preexecution use dc2ef35.
Only assignment URL plus requested lawful rc1 UNKNOWN disposition changed after
reviewed4d4d777. All intermediate bounds/d/objectives stayed strict; lawful UNKNOWN
would block timing as INCONCLUSIVE rather than falsely trigger scientific rejection.

Fresh GH27-windows-tier1-01, session10198 exit0/FILTER_COMPLETE/valid_runtrue.
Fixed48 serial AB/BA/AB OFF/MTO solves,3 baseline and3 candidate per group,
180s internal/195s external/10800s aggregate limits. All exact distances,
objectives, final bounds and every interim bound agree with the original truth;
no timeout, crash, malformed result or semantic mismatch. Independent retained
audit rechecked actual order, every scientific stdout, empty stderr, actual argv,
duration equality, all3 raw samples, and recalculated every median/ratio.

Times below are seconds; positive delta means slower candidate.

| Case | Mode | Baseline median | Candidate median | Delta |
|---|---|---:|---:|---:|
| BB_90_8_10 | OFF | 2.451310 | 2.455159 | +0.157% |
| BB_90_8_10 | MTO | 2.987561 | 2.999849 | +0.411% |
| GB_144_12_8 | OFF | 1.083298 | 1.073391 | -0.915% |
| GB_144_12_8 | MTO | 1.342059 | 1.341711 | -0.026% |
| BB_108_8_10 | OFF | 3.023608 | 3.034837 | +0.371% |
| BB_108_8_10 | MTO | 3.864476 | 3.870028 | +0.144% |
| LP_238_44_6 | OFF | 2.119108 | 2.094107 | -1.180% |
| LP_238_44_6 | MTO | 2.455928 | 2.503127 | +1.922% |

OFF median geometric ratio0.9960628314891926 (-0.394%); MTO1.0060979484530435
(+0.610%). Six of eight sample ranges overlap. BB108 OFF and BB90 MTO show small
nonoverlapping slowdowns in these three-sample ranges. The unchanged E004 judge
returns reject at its first per-case regression, BB108 OFF; its early-return
details do not contain all eight groups. This document/AUDIT retains all groups
without redefining that preregistered filter or strengthening its wording into
a controlled scientific conclusion.

Actual helper selectionCPU14/sibling15, mask16384/AboveNormal32768.84 telemetry
samples, all capacity eligible; minimum global idle73.740%, minimum sibling
idle88.889%, two contention flags (BB108 MTO repeat3 candidate preflight;
LP238 MTO repeat2 candidate in-run). These measurements do not establish which
timing differences were caused by interference. Host was not exclusively reserved;
differences are small, modes mixed and several ranges overlap.

Only runner19932 remained before close and was absent afterward. Job/affinity/
priority/sleep restoration alltrue; finalmask65535/Normal32. All original successful
preparation/source/support/runtime/input/parser/actual binary identities passed
postchecks. Resource RELEASE6066130488 was published before evidence retention.

Full original raw stdout/stderr/commands/samples/result/identities/resources/
cleanup/executed driver are retained unchanged in raw/windows-tier1-01.
The original154 manifest-covered files were all SHA256 verified; raw-sha256.json
and raw/** -text protect the exact retained Git bytes. The raw driver result is
unchanged: its numeric reject and formal INCONCLUSIVE are distinct fields.

Learning: the call boundary really changed and baseline entry counts are large,
but that did not produce a consistent benefit in this first fixed filter. Counts
alone are inadequate evidence for prioritizing a small call-overhead optimization.
Next action is controlled revalidation if this idea remains interesting, or a
separately selected concept targeting substantial repeated solver work. A user
one-tier exploratory exception, if requested by the coordinator, must be explicitly
preregistered and assigned; this completed Tier1 assignment does not authorize it.
