# E006 / H-009: BDD local filter REJECT; server corroboration pending

Latest execution: [diagnostic round02](DIAGNOSTIC-02-RESULT.md),48 correct solves,
independent audit PASS. BB90/GB144 affected-mode gains4.59%/39.45%; BB108/LP238
regress5.61%/23.32% with disjoint three-run ranges. Local general-purpose screen
**REJECT / NOT ADOPTED**, no Tier2/3. Dedicated-server performance remains
INCONCLUSIVE/unmeasured; repeat on server when eligible to corroborate. Candidate
unchanged/isolated/unmerged. The earlier strict partial INCONCLUSIVE record below
is historical and preserved, not the latest local-screen disposition.

Latest user decision: [record diagnostic screening and later controlled server
repetition](FOLLOWUP-2026-10-08.md). This does not alter the existing result,
candidate or strict runner defaults; no new benchmark started in that update.

2026-10-08. User asks for the next method after E005. Fresh
[Brain Round4](../../brain/2026-10-08-round4.md) selects existing H-009;
[proposal recorded before implementation](PROPOSAL.md). Test exactly one change:
replace the downstream MTO bound constructor with a singleton unweighted BDD
at its existing guarded call site. No LTO, SLS, row-XOR, reordering or tree reuse.

**Decision: INCONCLUSIVE; candidate isolated, not adopted.** Tier0 PASS.
Strict Windows Tier1 attempted32 of48 serial solves:31 complete/correct and
one deliberately resource-aborted. Two complete MTO/BDD comparisons favor BDD,
but BB108 MTO is incomplete and LP238 unstarted. No four-case aggregate or
promotion; no Tier2/3. A missing result after intentional termination is not
a solver crash, timeout distance or evidence against BDD. No timing-selected
retry or weakened threshold. Next action: complete a separately recorded full
Tier1 run under the same criteria, preferably a validated yfclab2 lease.

## Exact implementation and boundaries

Independent baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a;
candidatec91b19bbf29a28a6e808c8ef2c328cb9cef784e8,
[draft PR14](https://github.com/guluchen/DistQLDPC/pull/14), unmerged.
[Exact diff](candidate.patch):10 files,259 insertions/12 deletions.
The history checkout's older H001 solver is neither executable in this trial.

Source: Solver.cc/.h and new UnitBoundBDD.h; application diagnostic labels only
in distqldpc.cc. Support: Makefile dependency, BDD production probe and CI step,
experimental README, MODIFICATIONS and NOTICE. Existing MaxCDCL notices remain;
new generic BDD helper uses the embedded engine's MIT terms. DistQLDPC/QDistSAT
remain downstream/application/benchmark code with their own instrumentation and
optimizations; this is not an upstream MaxCDCL experiment.

Fixed active-literal order and original k=UB-1-nbFalse, n*k<=10000 guard,
cardinality mode/invocation checks, Sinz component and removal/reset/recycle
machinery retained. Root unit asserts the same sum<=k. Forward BDD clauses
project to that bound; no weighted/AMO extension. OFF and Sinz-only unchanged.
Distance, Pauli weight, logical predicates, certified bounds and timeout/result
semantics unchanged. Experimental diagnostic labels disclose the replacement.

Windows candidate binary SHA256
990f7c97358e13f904f661eb2cf7010f3e84d650eff0a48145943d5554bd7315;
baseline22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815.
GCC14.4.0/Cygwin3.6.11, original-O3 flags, one build worker. Existing E004
immutable156-payload package supplies baseline/matrices/QDistSAT helpers.
Its manifest's LTO candidate is unused; E006 source/binary/hosted identities are
recorded separately. Exact executed source bytes are retained, including Windows
line endings; [SHA256 inventory](raw-sha256.json) covers every raw artifact.

## Tier0

[Local raw evidence](raw/tier0-windows/summary.json), independent audit PASS:
fresh build; exhaustive BDD graph n<=8, production CNF projection/all bounds,
positive/mixed/negative literals; partial-assignment extensions; real root
reset, tighten/relax, dynamic auxiliary reuse and garbage collection.
Probe reports10042 graph/partial checks plus full signed CNF projections.
Independent tiny CSS oracle gives1/2/1; six dump comparisons byte-identical.
Smoke both versions; pinned QDistSAT7c4774fffc49856f48a22ae5f9063d00b2661aaa
LP136(distance4)/BB108(distance10), both modes, science identical.
Four one-second BB108 runs return1/UNKNOWN with sound bounds; no exact distance.
Correctness-only window allowed contention, never used for performance.

Hosted checks on candidatec91b19b:
[CI37770650581](https://github.com/guluchen/DistQLDPC/actions/runs/37770650581)
and required
[cross-repo37770650545](https://github.com/guluchen/DistQLDPC/actions/runs/37770650545)
PASS. Full job logs retained under raw/hosted; candidate/base merge and actual
QDistSAT SHA present. Original local summary's pending-hosted label is historical;
hosted-ci.json and the combined Tier1 receipt establish completed PASS.
Shared hosted timings support no scientific performance conclusion.

## Tier1 partial results

Same CPU14, SMT sibling15; owned Job Object fixes every parent/fork child to
mask16384 and AboveNormal32768, serial AB/BA/AB. Initial/preflight each CPU>=95%
idle; active sibling>=95%; global spare>50%, one worker<=half spare.180s parent
wall limit/195s watchdog, original inputs,30s bounded preflight wait. Balanced
power policy unchanged; no exclusive Windows resource reservation asserted.

Three-repeat medians, seconds; candidate's card-mto selector is BDD:

| Case | Mode | Baseline | Candidate | Candidate/baseline |
|---|---|---:|---:|---:|
| BB_90_8_10 | OFF control | 2.725710 | 2.712654 | 0.995210 |
| BB_90_8_10 | MTO / BDD | 3.278678 | 3.118633 | 0.951186 |
| GB_144_12_8 | OFF control | 1.142316 | 1.143125 | 1.000709 |
| GB_144_12_8 | MTO / BDD | 1.444298 | 0.875615 | 0.606256 |
| BB_108_8_10 | OFF control | 3.345040 | 3.338680 | 0.998099 |

All31 completed solves match expected d/objective/LB/UB, with no UNKNOWN.
BB108 MTO first baseline4.267592s completes; candidate deliberately stopped
at2.565757s when sibling idle88.405797%<95%. **Do not compare that partial
elapsed time as a solve or include it in medians.** Global idle69.452055%,
half spare5.556164 logical CPUs, so the capacity guard was satisfied. One of21
active resource checks lost the sibling window; two earlier preflight waits
are retained. No serious-interference claim from one observation.
Owned-tree taskkill succeeded. All six cleanup fields PASS: Job limit released,
mask65535,Normal priority32 and sleep requirement restored.

[Independent partial audit](raw/tier1-windows-01/independent-partial-audit.json)
recomputes raw results/medians, verifies156 package payloads, E006 sources/binaries,
commands/inputs/working directories, parent/fork-child masks/priorities, preflight,
active resource loss and cleanup. Original runner receipt says tier1 pending;
this reconciled record closes the attempt as incomplete INCONCLUSIVE. No
aggregate ratio, complete numeric gate, Tier2/3 result or acceptance invented.

## Learning and next action

Unlike E005's absent feasible-cap mechanism, BDD actually constructs constraints
on affected cases. BB90/GB144 local MTO/BDD differences repeat with disjoint
three-run ranges, about4.88%/39.37% lower medians. OFF controls remain within
overlapping timing ranges. This supports further measurement, not a universal
gain or adoption. BB108/LP238 affected-mode performance remains unknown.

GB144 first candidate log records n144/k1,3,7,15,14,8 BDD construction and
changed search history; final LRB phase conflicts84 vs baseline5101, UP29411 vs
274447. These phase-specific counters are observations, not total-work counts
or proof of causation. Constructor CPU time prints0.000000 at platform clock
resolution, not evidence of zero cost. Node/clause/aux statistics retained;
smaller representations alone never establish speed.

Next prioritize completing all Tier1 cases for unchanged H009; do not tune the
ordering/budget or propose a combined optimization based on partial timings.
Then use existing tier gates for LP340 and eventual dedicated decisive set.
[Exact commands](COMMANDS.md), Windows drivers and prepared Linux Tier0/Tier1
runner retained. Linux runner syntax checked only; its controlled integration
and helper acquisition/recovery validation remain prerequisites, not completed
evidence. No PI action required for implementation; a suitable resource window
is needed for the next controlled measurement.
