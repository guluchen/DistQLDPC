# H-007 strict Windows Tier 2: initial window unavailable

2026-10-08. User authorized LP340 after the completed strict Tier1 round.
[Preregistered proposal](WINDOWS-STRICT-TIER2-PROPOSAL-2026-10-08.md).
Decision **INCONCLUSIVE**, environment refusal, not a candidate rejection.
No solver started, no scientific result, timing samples or medians. No Tier3
launch, source/binary rebuild, optimization change or merge.

Initial five-second selection found no physical-core/SMT pair with both threads
>=95% idle. Driver exited1 before creating output/validating reused identities
or changing affinity/sleep state. Prior unchanged Windows Tier0 PASS remains
available; this attempt does not claim fresh correctness/build validation.
Original selection tick values were not saved by the existing helper, and are
not reconstructed. Raw refusal metadata explicitly notes this limitation.

Subsequent read-only checks found two Ld9BoxHeadless (PIDs11708/21596) and two
dnplayer (18152/22280), different from the previous observed instances. Their
presence does not establish why they started or prove a particular timing effect.
Supplemental five-second measurement recorded per-core idle62.5--88.125%, no
eligible95%-idle pair. It is labeled a later observation, not the missing original
selection data. No other programs terminated/moved; strict threshold not weakened.

User clarification requested: wait for emulator shutdown and retain strict
measurement, or explicitly choose contended diagnostics. No response is inferred
from elapsed time; the existing strict authorization remains the default. Standby
is environment-limited, not lack of a driver. Preserve previous negative and
positive rounds separately, without pooling or inventing speedup/rejection.

Latest steering: user reports halving emulator virtual CPU count and asks how
serious interference is. Two subsequent five-second read-only samples found
global idle89.140625/88.28125%; no SMT pair eligible in either sample. CPU8 was
98.125/99.375% idle but sibling9 only84.6875/80.625%. The best pair in the second
sample was6/7 at91.875/93.125%, still below the unchanged95% criterion. This
indicates abundant global capacity, but not a qualifying low-interference pair;
no claimed proportional solver slowdown or causal attribution to emulator
configuration. Retain after-emulator-core-reduction.json separately from the
initial refusal and earlier supplemental observations. No explicit switch to
diagnostic mode received, so no solver started and strict authorization remains.

User subsequently reports another virtual-core reduction. Two more five-second
samples found global idle86.66797/90.31439%, still no95%-idle pair in either
sample. Best second-sample pair12/13 was95.625/93.125%; CPU10/11 was99.375/47.5%.
Store after-second-emulator-core-reduction.json; no claim about actual emulator
virtual CPU count or causal effect, since only user-reported configuration and
observed host accounting are available. No further solver launch or weakened
threshold. A prospective practical alternative is confining emulator processes
to other physical cores to leave14/15 for the owned benchmark; not performed
in this scope, and would not exclude Windows/cache/power interference.

Prepared `run_windows_affinity_tier2.py` derives from the verified strict Tier1
driver with only case/count/time-budget selection changed: LP340,12 solves,
600s internal/615s external. Same source/package/runtime/binary checks, Job
Object scope, preflight wait, during-run CPU/sibling/affinity checks and cleanup.
`audit_windows_affinity_tier2.py` independently checks exact/intermediate bounds,
sample order, hashes, process affinity, strict resources, medians and restoration
after a complete round. Both syntax checks PASS; audit not run on nonexistent
performance samples. DistQLDPC downstream MaxCDCL distinction and attribution
unchanged; NOTICE/MODIFICATIONS require no changes.

Exact refused command:

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E004/run_windows_affinity_tier2.py --prior E004-windows-tier2-02 --cygwin-root E004-windows-runtime/cygwin --output E004-windows-strict-tier2-01 --preflight-wait-sec 30
```

Next strict retry, after an eligible window returns, must use a fresh output
directory (e.g. E004-windows-strict-tier2-02). Internal same-pair30s wait applies
before solves; the unchanged initial selector currently takes one five-second
sample and refuses immediately if no pair qualifies. Keep refusals rather than
retrying silently. If explicitly choosing diagnostic mode, record scope before
running and add `--allow-core-contention`; global>50%/half-spare rules stay intact.

[Retained evidence](raw/windows-strict-tier2-01): refusal metadata, executed
driver/helper and supplemental CPU/process snapshot. Files changed: proposal/
result, dedicated Tier2 driver/audit, raw evidence, experiment index/STATE/
HYPOTHESES. The candidate performance diff remains LTO only.
