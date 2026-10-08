# H-007 strict Windows retry after emulator shutdown

2026-10-08. User closed emulators and requested retry. [Preregistered scope](WINDOWS-STRICT-PROPOSAL-2026-10-08.md).
Practical low-interference window checks **PASS**; scientific and affinity
checks **PASS**; numerical optimization decision **INCONCLUSIVE**. These are
separate conclusions: a suitable monitored window was achieved, while the
LTO gain remains smaller than observed timing variability. No claim of Windows
exclusive reservation or controlled dedicated-server research acceptance.

Same LTO-only hypothesis/baseline24572d6/candidate5b13a2c and GCC14.4/Cygwin
Windows binaries as prior verified runs. Original156 payload hashes, runtime
installed.db, compiler version and binary hashes rechecked; prior Tier0 PASS
reused only with identical identities. No rebuild/solver/input/timeout change,
new optimization or attribution/NOTICE/MODIFICATIONS change. DistQLDPC remains
its own downstream MaxCDCL application; QDistSAT benchmark provenance unchanged.

## Resource-window execution

No Ld9BoxHeadless/dnplayer instance found before the retry. Initial per-core idle
roughly97-100% after shutdown, versus preceding contended session. First strict
attempt used CPU6/sibling7;17 exact solves completed, then next preflight refused
because selected/sibling idle93.75/87.5%, global93.2129%. No solver was active at
that refusal; preserved separately, not pooled or promoted. Independent partial
correctness/cleanup audit PASS.

Second strict attempt is a fresh48-run round on CPU14/sibling15, one owned
controller/solver process tree confined by Windows Job Object. Same95% pair
preflight/sibling active threshold and global idle>50%/one CPU<=half spare.
A documented monitor enhancement allows up to30s waiting before a command
starts on the same pair; every failed/successful preflight is retained and
no solver timing influences eligibility. No active-run relaxation or automatic
rerun. Two failed preflights waited for window recovery before BB90 MTO repeat2
candidate. All subsequent commands started eligible. 80
resource observations; minimum global idle87.336979%.
Active contention observations0; failed preflight observations2. All observed
eligible preflights had both selected/sibling>=95%, all observed active sibling
samples>=95%. Polling every2s does not rule out subinterval scheduling interference.

48 exact solves (four cases, both modes, three baseline/candidate repeats in
ABBAAB order), independent scientific/affinity/strict-resource/restoration audit
PASS. No UNKNOWN, timeout, invalid bound, crash, active resource abort or
semantic mismatch. Temporary sleep request/job affinity cleared and original
mask65535 restored. Balanced scheme retained; no other process moved/terminated.

## Timing and decision

| Case | Mode | Baseline median s | LTO median s | Candidate/baseline |
| --- | --- | ---: | ---: | ---: |
| BB_90_8_10 | no-card | 2.483685600 | 2.457119600 | 0.989303799 |
| GB_144_12_8 | no-card | 1.050705900 | 1.056990600 | 1.005981407 |
| BB_108_8_10 | no-card | 3.054842300 | 3.032020200 | 0.992529205 |
| LP_238_44_6 | no-card | 2.108699200 | 2.086703000 | 0.989568830 |
| BB_90_8_10 | card-mto | 3.005033600 | 2.987707600 | 0.994234341 |
| GB_144_12_8 | card-mto | 1.324286500 | 1.315836700 | 0.993619357 |
| BB_108_8_10 | card-mto | 3.872860900 | 3.821143200 | 0.986646125 |
| LP_238_44_6 | card-mto | 2.458059200 | 2.462439700 | 1.001782097 |

OFF median-ratio geometric mean0.994322423,
MTO0.994056046 (~0.568%/~0.594% faster).
Range-envelope geometric means1.009757522/1.023076985 exceed1, and GB OFF/LP238
MTO have mildly slower medians. No disjoint regression in this complete round.
Existing noise gate INCONCLUSIVE, not PASS. The preceding contended BB108 MTO
negative result remains preserved; this round has favorable BB108 MTO direction
but does not establish the source of the reversal or a portable compiler effect.
Do not pool hosts, CPU pairs, attempts or pre/post-shutdown runs.

Practical learning: this machine can sustain the monitored low-interference
conditions for a full short round after user workload shutdown; a strict
preflight wait handles brief background work without weakening eligibility.
Optimization learning: this cleaner round still supports only a small/noisy LTO
signal, not the earlier Linux MTO singleton19.5% attribution. Correctness
confidence high; speedup-size/reproducibility confidence limited. Candidate
remains isolated/unmerged. No fresh Tier2/3 this follow-up. Next recommended
bounded step under the user's exploratory advancement instruction is LP340
Tier2 with the same Windows window and paired repeats, retaining prior lower
tiers' uncertainty rather than declaring them controlled PASS.

## Reproduce and retain

Executed command:

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E004/run_windows_affinity_tier1.py --prior E004-windows-tier2-02 --cygwin-root E004-windows-runtime/cygwin --output E004-windows-strict-tier1-02 --preflight-wait-sec 30
```

[Complete raw evidence](raw/windows-strict-tier1-02): stdout/stderr, exact
commands, all48 raw timings/medians, CPU and process-affinity telemetry,
environment identities, original executed driver/helper, decision and audit.
[First partial attempt](raw/windows-strict-tier1-01) retained unchanged with
independent partial audit. Practical [user guide/strict launcher](WINDOWS-WINDOW-GUIDE.md)
now waits up to30s at preflight by default. All historical failures/negative
samples remain; the optional contended mode still cannot pass strict checks.

Audit:

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E004/audit_windows_affinity.py E004-windows-strict-tier1-02 --prior E004-windows-tier2-02 --probe E004-windows-affinity-probe-02
```

Files changed: preregistration/result, driver bounded preflight wait, audit strict
window assertions, launcher/guide, raw evidence, STATE/HYPOTHESES/E004 index.
Candidate performance diff remains LTO only.
