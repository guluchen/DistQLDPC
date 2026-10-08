# GH22 global symmetric activity: completed filter

Decision **REJECT for general-purpose adoption in this local filter**, isolated
PR25 / NOT ADOPTED; formal controlled performance **INCONCLUSIVE**. Tier0 PASS,
48 Tier1 results correct, no Tier2/3. Scientific semantics unchanged.
Source596510ccda48361b34158927607a58988402ff91 on baseline24572d6; exact one-index
Solver.cc change, notices preserved. Actual execution support851f755e632ac7be72d313a0979ce265d3bf6b07,
driverSHA503607d9909e31035d014aace6401a3bf8fff4a5191e944eade4703614d8f327,
assignment6064232111/session87041 exit0. Frozen actual binaries match Tier0.

| Case | Mode | Baseline median s | Candidate median s | Change |
|---|---|---:|---:|---:|
| BB90 | OFF | 2.705502 | 2.960155 | +9.41% |
| BB90 | MTO | 3.283120 | 2.763399 | -15.83% |
| GB144 | OFF | 1.158857 | 1.615309 | +39.39% |
| GB144 | MTO | 1.466539 | 1.149788 | -21.60% |
| BB108 | OFF | 3.318694 | 3.516915 | +5.97% |
| BB108 | MTO | 4.224261 | 3.783580 | -10.43% |
| LP238 | OFF | 2.222082 | 2.229041 | +0.31% |
| LP238 | MTO | 2.537823 | 2.163986 | -14.73% |

First three OFF cases have every candidate slower than every baseline; all
four MTO cases have every candidate faster than every baseline. OFF median GM
1.128395 (+12.84%), MTO0.842571 (-15.74%); worst-range envelope GM1.149826/0.871326.
The unchanged prerecorded generic numeric filter rejects; do not hide serious
OFF regressions by pooling modes or relabeling the tested global rule as MTO-only.
This is a meaningful encoding/search interaction, not proof original duplicate
bump is a bug, and not a universal activity heuristic result.

All48 scientific results d/objective/LB/UB10/8/10/6 correct; every emitted update
validated and independently reread (96 bound updates). No crash, timeout,
resource abort, identity change or malformed output. Source/input/parser/
four runtime DLL/binary hashes fixed. AB/BA/AB180/195s serial sameCPU14/AboveNormal,
no competing sibling experiment.87 resources eligible,3 contention alerts,
min globalspare72.302%. Full Job/affinity/priority/sleep restoration confirmed,
only runner24128 before release. Windows is monitored diagnostic, not exclusive
research-grade reservation. Strong observed OFF regressions justify declining
this global candidate; controlled corroboration remains pending.

Durable raw594 payloads retain Tier0+hosted and all48 argv/stdout/stderr/timing/
statistics/telemetry/cleanup plus exact executed driver. Public SHA manifest
inventories actual retained payloads; local-only executable/object hashes remain
identified separately. Independent calculations/ordering/science/resource audit
PASS, no repeated-until-favorable measurement. Candidate remains separate draft;
do not merge, combine O2/PGO/LTO/enqueue, or advance this global rule to Tier2/3.

Next hypothesis suggested by these data: separately test the same symmetric
choice only when the existing cardinality mode is explicitly MTO, retaining
the baseline choice in OFF/BOTH/Sinz/forced-both. Fresh three-proposal round,
immutable baseline and prerecord BEFORE source edit; no conclusion about that
unbuilt variant. LP340 remains an untouched performance holdout for a future
candidate that passes gates or a separately authorized exploratory exception.
