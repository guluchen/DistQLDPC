# H-007 advancement: Windows Tier 1 complete, INCONCLUSIVE

2026-10-08, user requested advancing H-007. [Preregistration](WINDOWS-TIER1-PROPOSAL-2026-10-08.md)
preceded executions. Same single LTO concept, no implementation/build changes;
verified 156 immutable payloads, both original Windows binary hashes, prior
Tier 0 PASS, unchanged installed package DB and compiler version before running.
Reused E004-windows-tier2-02, baseline 24572d6/candidate 5b13a2c, GCC 14.4.0.
No E001 optimization stacked; downstream MaxCDCL code/notices unchanged.

One new coverage round, not repeated timing selection: four prescribed cases,
OFF/MTO separately, three baseline/candidate repetitions, AB/BA/AB, 180s internal
and 195s external limits, one solver worker. All 48 return 0 with expected
scientific distance/objective/LB/UB, no timeout, UNKNOWN, crash or resource abort.
Independent raw-output/identity/order/median/resource audit PASS. Prior Tier 0
was not rerun because binary/source/runtime identities were unchanged and checked.

| Case | Mode | Baseline median s | LTO median s | LTO / baseline | max LTO / min baseline |
| --- | --- | ---: | ---: | ---: | ---: |
| BB_90_8_10 | OFF | 2.693217 | 2.682326 | 0.995956 | 1.006510 |
| GB_144_12_8 | OFF | 1.142291 | 1.125606 | 0.985393 | 1.001351 |
| BB_108_8_10 | OFF | 3.316028 | 3.294568 | 0.993528 | 0.997078 |
| LP_238_44_6 | OFF | 2.242296 | 2.231852 | 0.995342 | 1.010612 |
| BB_90_8_10 | MTO | 3.266822 | 3.251051 | 0.995172 | 1.003878 |
| GB_144_12_8 | MTO | 1.433172 | 1.426814 | 0.995564 | 1.009481 |
| BB_108_8_10 | MTO | 4.200627 | 4.172645 | 0.993339 | 1.002257 |
| LP_238_44_6 | MTO | 2.649694 | 2.629473 | 0.992369 | 0.996769 |

All eight medians are slightly favorable; no nonoverlapping per-case regression.

- OFF: median geometric ratio 0.992546, descriptive reduction 0.745%; range-envelope geometric ratio 1.003875.
- MTO: median geometric ratio 0.994110, descriptive reduction 0.589%; range-envelope geometric ratio 1.003086.

Both range envelopes exceed 1, so the original preregistered numerical filter
is **INCONCLUSIVE**, independently of desktop-control limitations. No threshold
relaxation, mode pooling or favorable subset selection. 90
resource observations, minimum global idle 74.220273%; one
worker never exceeded half measured spare allowance. Observations are periodic,
not an exclusive-host claim. No new Tier 2/3, adoption or merge.

[Raw stdout/stderr, exact commands, every timing and medians](raw/windows-tier1-01/)
including [independent audit](raw/windows-tier1-01/independent-audit.json).
Local evidence archive SHA256 `0fb4de2badc5f4fb4f4ac1d6d04fcfade8e85a411c7d15e065c8d9139fc02895`; raw evidence also versioned here.
[Driver](run_windows_tier1.py) and [auditor](audit_windows_tier1.py) retained.

```powershell
python -X utf8 .\DistQLDPC\optimization\experiments\E004\run_windows_tier1.py `
  --prior .\E004-windows-tier2-02 --cygwin-root .\E004-windows-runtime\cygwin `
  --output .\E004-windows-tier1-01
python -X utf8 .\DistQLDPC\optimization\experiments\E004\audit_windows_tier1.py `
  .\E004-windows-tier1-01 --prior .\E004-windows-tier2-02
```

These are the recorded commands, not permission to overwrite or repeat completed
output. Codex execution used reviewed escalation to preserve Cygwin child PATH.
The earlier Windows LP340 twelve-run diagnostic remains separate: OFF/MTO ratios
0.987788/0.993750. Earlier Linux Tier 1 ratios 0.979514/0.981341 also remain separate;
different compilers/hosts, no pooled median or cross-platform effect estimate.

## Formal advancement condition

Current yfclab2 observations: three 5s windows global idle
75.897/75.991/75.505%, CPU102 100%, CPU230 0%; 24 users/load average
61.85/62.54/63.30. Helper status inactive, no isolated CPUs. No lease acquired.
A spare global average and an installed helper do not attest a controlled host.
Root-helper scope was not broadened and another workload was not terminated.
Successful acquired-lease/command-failure/forced-recovery validation is pending.

The prepared [controlled follow-up driver](controlled_followup.py) is staged at
`/home/yfc/codex-e004-lto-20261007/controlled_followup.py`. It derives from the
immutable package runner, adding checker-only expected-ground-truth/partial-bound/
contradictory-output checks and rejecting Tier 0 failures/crashes before promotion.
No solver or data change. [Six checker checks](controlled-checker-tests.json) PASS;
Linux CLI checked, but no controlled benchmark was executed. Original package
manifest remains unchanged. [Controlled execution instructions](CONTROLLED-FOLLOWUP.md)
require a real exclusive/stable reservation and completed helper validation;
never falsely set the attestation flag merely because >50% CPU is idle.

Learning: complete case coverage now supports a small diagnostic favorable
median direction with no evident serious regression, but no beyond-noise gain.
Another unrestricted desktop repeat is not the missing evidence. E004 remains
INCONCLUSIVE. Next: at most one properly controlled Tier 1 comparison, proceeding
to Tier 2 only if its unchanged gate passes; otherwise retain an inconclusive or
negative result. If obtaining control costs more than resolving these small
signals is worth, explicitly shelve H-007 rather than falsely accepting it or
automatically starting H-008/H-009. Scientific semantics changed: no.
