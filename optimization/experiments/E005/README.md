# E005 / H-008: REJECTED configuration; performance INCONCLUSIVE

2026-10-08. User requests next proposal after shelving LTO. Fresh
[Brain selection](../../brain/2026-10-08-round3.md) recovers existing H-008;
[preregistered proposal](PROPOSAL.md) fixes one original-CNF local-search call,
seed1,10000 flips,25% noise. No LTO/row initialization/BDD/phase transfer.

**Decision: REJECT this fixed backend/seed/budget configuration for the current
track.** It provided zero verified caps in eight completed warm-start calls on
all four Tier1 cases/both modes, so the proposed feasible-cap mechanism was not
realized. This applies to the tested configuration, not SLS generally. The
controlled performance outcome remains **INCONCLUSIVE**: strict Tier1 refused
initial resources, zero baseline/candidate timing samples or repeated medians.
Do not describe this as a measured slowdown or controlled performance rejection.

## Implementation and scientific boundaries

Baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a;
candidate749391c9aab5389965822cac94d90aa360446f9a,
[isolated draft PR13](https://github.com/guluchen/DistQLDPC/pull/13), unmerged.
[Exact candidate diff](candidate.patch). Newly authored WalkSAT-style backend
captures the original CNF before simplification, retains best hard-feasible
assignment, independently verifies original hard clauses/soft cost and matrix
commutation/logical/union-weight predicates. Only verified original cost reaches
existing initUB, whose residual-offset/inclusive+1 behavior is retained and tested.
No feasible verified cap follows exact original search. Never emit optimal
RESULT from SLS; warm-start work stays inside unchanged parent wall timeout.

Files: application distqldpc.cc, new SlsWarmStart.h, Makefile header dependency,
focused C++ correctness probe/CI step, experimental README. No src/solver bytes
changed (canonical line endings independently checked); MaxCDCL downstream
instrumentation/attribution unchanged, no NOTICE/MODIFICATIONS patch update.
QDistSAT remains the benchmark platform, DistQLDPC the downstream application.
GCC14.4/Cygwin runtime and original-O3 flags retained, one build worker.

Windows binary SHA256:

- Baseline:22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815
- Candidate:21db0a5753f9f91509e88a22628d0b14c4374d111f574d8f83a962a08fc3d92a

## Tier0: PASS

[Validation03/raw independent audit](raw/validation-03): build;250 small CNFs
checked exhaustively for reported witness/cost and deterministic budget;
exhaustive original CSS witnesses; inclusive caps at/above optimum including
fixed-cost endpoint; tiny CSS1/CSS4/CSS5 distances1/2/1, both modes; six identical
CNF dumps; smoke; unchanged QDistSAT LP136 distance4/BB108 distance10 both modes;
one-second UNKNOWN/TIMEOUT/sound-bound checks. Cleanup/priority/affinity PASS.
Candidate/manifest/runtime identities retained. Tiny valid warm witnesses are
observed, so the capture/search/verified-cap path actually executes.

Required candidate PR checks PASS:
[cross-repo37766753566](https://github.com/guluchen/DistQLDPC/actions/runs/37766753566)
and [CI37766753505](https://github.com/guluchen/DistQLDPC/actions/runs/37766753505),
including focused C++ probe. QDistSAT SHA7c4774fffc49856f48a22ae5f9063d00b2661aaa;
PR test merge5530e66 contains candidate749391c/base24572d6. Full job logs and
job/step/status receipts preserved in validation03; shared timings informational.

Earlier setup failures retained: validation01 test-only strict `-std=c++11`
hid POSIX declarations; switched test compiler to `-std=gnu++11`, leaving
production flags unchanged. validation02 Windows CRLF prevented bash smoke
startup; normalized unchanged script locally. No scientific mismatch occurred.
Their generic harness emitted status REJECTED via assertions; this is a setup
classification error, not candidate semantic rejection. Do not delete/relabel
raw receipts. Original validation01 executed driver was not retained; exact
compile commands/errors are, and repaired driver is explicitly labelled.

## Tier1: resource refusal, zero performance samples

[Attempt01/raw](raw/windows-tier1-01): initial5s selector found no physical-core/
SMT pair both>=95% idle, before workload or temporary-setting changes. Initial
per-core ticks were not retained by helper; do not invent idle percentages.
No retries/relaxed thresholds. No speed ratio, median, serious-regression claim,
Tier2/Tier3 or acceptance. Prepared strict driver preserves original180s/195s,
48 serial ABBAAB solves, same AboveNormal job priority and single-core affinity,
global>50%/half spare/sibling95% guards and30s preflight wait.

## Separate mechanism diagnostic

[Preregistered short screen](MECHANISM-SCREEN.md),
[eight raw one-second runs](raw/mechanism-screen-01). Warm-start code/budget/seed
unchanged. Contention allowed for functionality only, one pinned worker, global
spare guard retained. All calls completed10000 flips before exact solver entered
ordinary no-UB search; all eight returned normal UNKNOWN/TIMEOUT with sound bounds.
No model/cap was accepted; independent audit checks fallback and restoration.

| Case | OFF verified cap | MTO verified cap | Final hard-unsatisfied clauses, OFF/MTO |
| --- | --- | --- | --- |
| BB_90_8_10 | none | none | 13/13 |
| GB_144_12_8 | none | none | 25/25 |
| BB_108_8_10 | none | none | 6/6 |
| LP_238_44_6 | none | none | 90/90 |

Final hard-unsatisfied count describes the last search assignment, not whether
an earlier assignment was feasible. Decisive observation is zero **verified**
caps and original exact fallback. Reported acquisition/verification seconds
are~0.0055--0.0140 under contended diagnostics, exclude capture overhead and
are not repeated performance measurements. No overall-overhead/speedup claim.

Learning: generic small-budget CNF flips did not provide the proposed cap for
these parity-heavy cases. Dense XOR feasibility is a plausible explanation,
not an established bottleneck/profile finding. Larger budget, different SLS
backend or parity-aware moves would be separately preregistered hypotheses;
do not tune this candidate after observing results. Next Brain should consider
the existing singleton BDD proposal or gather profiling evidence for ordinary
program optimization. No automatic next proposal or expensive tier launch.

Candidate remains isolated/unadopted; all failed receipts retained. Reproduce
using the exact commands in COMMANDS.md and script/raw command records. No
scientific semantics, input ground truth, bounds or timeout interpretation changed.
