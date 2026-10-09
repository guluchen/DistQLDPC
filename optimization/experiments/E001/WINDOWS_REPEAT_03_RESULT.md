# E001 Windows repeat 03 result

**Results obtained on Windows/Cygwin. Windows Tier 1 numerical decision: REJECT.**

User explicitly requested this Windows execution. Same baseline/candidate/probe
hashes and all 914 package source payloads verified; no rebuild or implementation
change. Baseline 24572d6, E001 candidate code 50623f9, snapshot 9d68f45,
QDistSAT 7c4774f. DistQLDPC includes its downstream MaxCDCL engine; it is not
standalone upstream MaxCDCL. No E002/E003 changes combined.

Windows 11 / Cygwin 3.6.11, GCC 14.4 original application Makefile flags. Native
Python with UTF-8 drives the existing Tier 0 harness and adapts Unix CLI paths.
Cygwin provides POSIX fork/pipe/signals for unchanged application code. Host CPU,
OS, power plan and process inventory in raw/windows-repeat-03/windows-host.json;
compiler/binary hashes and input manifest in environment.json/identity-check.json.

Fresh Tier 0 PASS: 676 algebra cases, exhaustive CSS d=2/d=1, default/OFF/MTO,
smoke, pinned QDistSAT OFF/MTO pilot, six forced timeouts. All 48 new Tier 1
solves have certified correct distance/objective/lower/upper bounds (144 across
three rounds). No crash/timeout or discarded sample. Serial AB/BA/AB, three per
version/case/mode, 180s internal limit/195s watchdog, verbose output redirected;
same full wall-time metric and unchanged preregistered numerical judge.

| Case | Mode | Baseline median (s) | Candidate median (s) | Round 1 ratio | Round 2 ratio | Round 3 ratio |
|---|---|---:|---:|---:|---:|---:|
| BB_90_8_10 | no-card | 2.3933 | 2.2162 | 0.9372 | 0.9434 | 0.9260 |
| BB_90_8_10 | card-mto | 2.8501 | 2.4144 | 0.8403 | 0.8346 | 0.8471 |
| GB_144_12_8 | no-card | 0.9972 | 1.4659 | 1.4929 | 1.4756 | 1.4700 |
| GB_144_12_8 | card-mto | 1.2496 | 1.8154 | 1.4138 | 1.4128 | 1.4528 |
| BB_108_8_10 | no-card | 2.8654 | 2.5157 | 0.8681 | 0.8782 | 0.8780 |
| BB_108_8_10 | card-mto | 3.6979 | 2.9966 | 0.8057 | 0.8080 | 0.8103 |
| LP_238_44_6 | no-card | 1.8823 | 1.7814 | 0.9472 | 0.9566 | 0.9464 |
| LP_238_44_6 | card-mto | 2.2158 | 1.7313 | 0.7815 | 0.7726 | 0.7813 |

Round 3 median-ratio geomeans: OFF 1.03125; MTO 0.93952.
Disjoint Windows regression: GB_144_12_8 no-card, baseline 0.9821–1.0150 s, candidate 1.4657–1.4664 s.
Disjoint Windows regression: GB_144_12_8 card-mto, baseline 1.2494–1.2654 s, candidate 1.7646–1.8485 s.

## Interpretation

This is Windows-derived local evidence. Interactive host, no exclusive reservation,
fixed power policy or pinned CPU. Record the local numerical outcome as such;
do not turn it into Linux/dedicated or hardware-independent evidence. Preserve
all earlier samples and mode-specific regressions, not just aggregate speed.
Original controlled performance status remains INCONCLUSIVE. No Tier 2/3,
acceptance, merge or fresh Brain round. Scientific semantics unchanged.

Row shortening demonstrably reduces raw logical XOR gates; whole-solve runtime
is family-dependent locally. The causal effect on search versus construction
is not isolated. If GB regresses again, this strengthens local reproducibility
but does not identify the cause. Review existing search diagnostics or the
verified dedicated package before selecting any future hypothesis.

Raw new data: raw/windows-repeat-03/, all outputs, timings, commands, environment,
Tier 0 and hash manifest. Repeat plan: WINDOWS_REPEAT_03_PLAN.md.

## Existing solver-log observations (no new instrumentation)

GB OFF repeat 1 baseline: last failed-UB [UB, cnfls, hcnfls] = [8, 11976, 594]; final hardConflicts = 594; [nbLK, nbLKup] = [14347, 11604748].
GB OFF repeat 1 candidate: last failed-UB [UB, cnfls, hcnfls] = [8, 18882, 615]; final hardConflicts = 615; [nbLK, nbLKup] = [23628, 18263005].
These printed counters show different search work for the smaller encoding; they do not isolate a causal explanation or stage runtime. Full extracted observations for all 48 solves: solver-counters.json; source logs retained, absent counters null.
