# E006 diagnostic Tier1 round02: local REJECT, server corroboration pending

2026-10-08. User says continue after recording the two-stage workflow and
acceptance with characterized minor interference. [Preregistered screen](DIAGNOSTIC-02-PROPOSAL.md)
executes unchanged BDD candidatec91b19bbf29a28a6e808c8ef2c328cb9cef784e8 against
baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a; no solver/build/input changes.
Existing local and required hosted Tier0 PASS, identities rechecked. Exactly
one concept remains the MTO constructor replacement, not upstream MaxCDCL.

**Disposition: REJECT the current general-purpose replacement in the local
Tier1 screen; NOT ADOPTED.** Repeated BB108/LP238 regressions violate the
per-case gate even though the affected-mode aggregate improves. Candidate stays
isolated in draftPR14, unmerged. No Tier2/3 or acceptance. Dedicated-server
performance remains INCONCLUSIVE/unmeasured; the user-requested future complete
server repetition remains pending to corroborate these results. This does not
reject BDD encodings universally or establish a dedicated-server slowdown.

## Completed screen and raw medians

All48 serial AB/BA/AB solves complete with expected d/objective/LB/UB and no
timeout/UNKNOWN/crash: BB90d10, GB144d8, BB108d10, LP238d6 in both modes.
Three repeats/version/case/mode,180s parent/195s watchdog. Same CPU14/sibling15,
mask16384 and AboveNormal32768 for every owned parent/fork child. Explicit
--allow-core-contention records sibling/core interference rather than aborting;
global>50% and one worker<=half spare remain enforced. No omitted samples or
pooling with strict01. Scientific answers and timeout semantics unchanged.

| Case | Mode | Baseline median s | Candidate median s | Candidate/baseline |
|---|---|---:|---:|---:|
| BB_90_8_10 | OFF | 2.732290 | 2.719487 | 0.995314 |
| GB_144_12_8 | OFF | 1.144249 | 1.153298 | 1.007909 |
| BB_108_8_10 | OFF | 3.339863 | 3.366507 | 1.007978 |
| LP_238_44_6 | OFF | 2.294641 | 2.277109 | 0.992360 |
| BB_90_8_10 | MTO / BDD | 3.292002 | 3.140765 | 0.954059 |
| GB_144_12_8 | MTO / BDD | 1.445806 | 0.875506 | 0.605549 |
| BB_108_8_10 | MTO / BDD | 4.256847 | 4.495669 | 1.056103 |
| LP_238_44_6 | MTO / BDD | 2.702983 | 3.333286 | 1.233188 |

Affected-mode medians: BB90 improves4.59%, GB144 improves39.45%, BB108 regresses
5.61%, LP238 regresses23.32%. BB108 baseline range4.252837--4.273466s,
candidate4.492289--4.540051s; LP238 baseline2.696912--2.711881s,
candidate3.328125--3.349767s. Every candidate run is slower than every baseline
run on these two affected-mode cases. OFF triplets overlap on all four cases,
with median changes under0.8%. No universal percentage threshold invented.
Affected-mode median geometric ratio0.931355 and range-envelope ratio0.937174
do not erase the per-case failures. Existing numeric gate reports REJECT.

## Interference, identity and cleanup

89 resource checks,41 active checks; zero active interference alerts at the
2s cadence, minimum active sibling idle96.453901%, minimum global idle74.471993%.
Four preflight interference observations were recorded without stopping.
Short solves may have no active sample; this is not continuous exclusivity
evidence. No exclusive Windows reservation or proof of complete absence of
background effects is claimed. Nevertheless, this screen did not fail because
of a95% cutoff; the repeated two-case negative filter is materially larger
than the overlapping OFF-control variation. Minor interference is not being
used as an automatic veto or a blanket explanation of the regression.

[Independent audit](raw/tier1-windows-diagnostic-02/independent-diagnostic-audit.json)
PASS:156 original payloads, candidate sources/binaries, hosted receipts,
commands/input/cwd, all raw scientific output, AB/BA/AB order, medians,
parent/fork-child affinity/priority, capacity checks and six cleanup fields.
Original compiler/runtime, baseline22e398cc.../candidate990f7c97... hashes retained.
Job limit released, mask65535 and Normal32 restored, sleep requirement restored.

The existing generic runner prints "48 correct strict-window solves" even with
--allow-core-contention and leaves decision INCONCLUSIVE. That label is not a
strict-window claim: environment invocation/allow_contention=true and complete
telemetry define this diagnostic protocol. Raw receipts are preserved unchanged;
[reconciled disposition](DIAGNOSTIC-02-DECISION.json) explicitly records local
REJECT and unresolved dedicated-server corroboration. No silent retrospective
change to protocol, samples or prior strict result.

## Mechanism observations and learning

Identical phase1 counters across all three repeats within each version:
BB108 baseline conflicts38153, starts126, UP1655382; BDD conflicts39119,
starts127, UP7250858. LP238 baseline conflicts9512, starts40, UP776150;
BDD conflicts12111, starts52, UP4061181. [Raw counter observations](raw/tier1-windows-diagnostic-02/search-observations.json)
retain the exact phase values. These are downstream instrumentation's phase
counters, not total-work measurements or a proven explanation. They suggest
more propagation/search work on the cases that regress; reducing construction
size or choosing another representation is not inherently faster.

BB90/GB144 positive direction repeats the earlier strict partial screen.
The new complete screen reveals failures hidden by that round's missing BB108/
LP238 comparisons. A universal constructor replacement is therefore not a good
candidate for promotion on current evidence. A future restricted encoding or
propagation-cost hypothesis would need independent rationale/preregistration;
do not silently specialize by benchmark name or combine methods in this trial.

## Server availability and next action

[Read-only yfclab2 sample](raw/server-availability-02.json): global idle48.724352%,
CPU102 idle0%, sibling230 idle99.198397%,5s window; helper status inactive,
no lease/partition. Global spare fails the user's>50% rule, so no server workload
or privileged helper change was attempted. SSH oom_score_adj warnings are
existing login messages and do not change the recorded successful status query.

When the server has a suitable validated window, repeat complete unchanged
Tier1 separately using the retained command sheet/package and lease validation
prerequisites. Keep all cases, including regressions; do not run just the two
favorable cases or pool desktop/server timings. Until corroborated, no broad
scientific speed claim, acceptance, merge or higher tier. No recurring monitor
or scheduled job created; future server execution remains authorized but pending.
