# H-007 LP340 strict retry03 preregistration

The user authorizes the next experiment after agreeing to serial baseline/LTO
runs on one core rather than simultaneous SMT competition. Continue the existing
LTO-only H-007 experiment, not a new solver hypothesis. One fresh LP_340_56_8
round with unchanged validated binaries/package/compiler/runtime and prior
Tier0 identity checks. Both versions use AboveNormal job-wide priority.

Scope: OFF/MTO, three repeats/version/mode, ABBAAB, twelve serial solves.
Initial/preflight physical-core pair >=95% idle; unused sibling >=95% during
runs; global idle >50%, one worker <=half spare capacity. Internal wall limit
600s, external watchdog615s, bounded preflight30s. Affinity/priority/sleep
settings restored. No unrelated process changes, threshold relaxation,
simultaneous sibling run, automatic retry or Tier3. Expected12--15 minutes;
maximum120 solver minutes. Resource-window loss stops this attempt and records
INCONCLUSIVE, not scientific rejection. Wrong scientific result/bound/output
or unexpected crash stops with REJECTED. No ground-truth/timeout/encoding/
distance semantics change; preserve downstream MaxCDCL distinction.

Previous attempt02 interrupted its first baseline at29.097s when sibling idle
fell to90.071%; no completed pair or performance estimate. Retain it separately.
If all twelve solves complete, independently audit raw results, scientific
bounds, hashes, priority/affinity/window/restoration and three-repeat medians.
Do not pool earlier Normal-priority or contended rounds or infer acceptance
from noisy measurements. Record exact executed scripts and all partial samples.

Command (workspace root):

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E004/run_windows_affinity_tier2.py --prior E004-windows-tier2-02 --cygwin-root E004-windows-runtime/cygwin --output E004-windows-strict-tier2-03 --preflight-wait-sec 30 --priority-class above-normal
```

## Result: INCONCLUSIVE

Initial CPU14/sibling15 idle99.688/100% qualified. Prior Tier0 PASS and all156
manifest payloads, binary/compiler/runtime identities rechecked. Exact executed
driver/helper retained; no implementation change from attempt02 (history commit
a9b0ed3). First OFF pair completed correctly, returncode0, d/objective/LB/UB8:

| Version | Repeat | Raw wall seconds |
| --- | --- | --- |
| baseline | 1 | 68.30553279999003 |
| LTO candidate | 1 | 67.62490049999906 |

Second OFF candidate interrupted at22.36261789999844s. Last2s observation:
sibling idle94.405594%, global idle73.078632%, spare-capacity condition still
valid but sibling95% threshold failed. This is a marginal threshold miss; a
single observation does not establish severe interference or its source.
All74 observations retained; one active contention observation, no preflight
refusals. No complete three-repeat sets, MTO run, medians or speedup claim.
No repeated timing selection or automatic retry. No Tier3 or candidate merge.

The guard intentionally terminated only the owned parent/child tree; taskkill
returned0. The interrupted output has no scientific result; absent values are
unknown, not zero. No unexpected solver crash or scientific mismatch found.
Independent partial audit PASS: two exact correct solves, all observed parent/
child affinity16384 and AboveNormal32768, hashes/window/abort checks and
restoration. Job limits released, original mask65535 and priority32 restored,
temporary sleep request cleared. Full12-sample performance audit not applicable.

Learning: an eligible pair can sustain a complete OFF comparison on this host,
but this attempt did not sustain the preregistered window for the entire round.
One pair cannot establish reproducibility or reject/accept LTO. Preserve earlier
attempts separately. Next: obtain a longer quiet window and rerun the unchanged
serial protocol. Any alternative interference tolerance must be specified
prospectively and recorded as separate diagnostic evidence, not applied to this
round after observing timings.

[Raw evidence and partial audit](raw/windows-strict-tier2-03) contain exact
commands, stdout/stderr, three samples including the abort, resources,
priority/affinity traces, environment identities, executed scripts and cleanup.
Files changed: this preregistration/result, raw evidence and history indexes;
no solver/build/benchmark data change, no attribution or semantic modification.
