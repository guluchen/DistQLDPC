# E006 exploratory Tier2 preregistration: explicit user override

2026-10-08 before execution. After reviewing Tier1's local REJECT on BB108/
LP238, user explicitly says "跑tier2看看". This authorizes this bounded
exploratory follow-up despite the failed Tier1 filter; it does not relabel
Tier1 PASS, accept the method, or authorize Tier3. Supersedes the earlier
no-Tier2 scheduling stop for this single attempt only. Scientific gates and
spare-capacity rules remain unchanged.

Same baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a and BDD
candidatec91b19bbf29a28a6e808c8ef2c328cb9cef784e8; no optimization changes.
Tier0 local/required hosted PASS, source/runtime/binary/input identity rechecked
by driver. Local Windows, same existing Cygwin runtime and one worker.

LP_340_56_8 only, expected distance8. Both OFF control and MTO/BDD selector;
three baseline/candidate repeats per mode, serial AB/BA/AB,12 total solves.
600s original parent wall limit/615s external watchdog as in prior Tier2
experiments. Same fixed CPU and AboveNormal owned-job priority for both
versions and fork children. --allow-core-contention records transient
interference rather than stopping; global idle>50% and one worker<=half spare
remain mandatory. No other workloads, root changes or scientific assumptions.

Typical expected10--20min based on prior LP340 baseline runs; worst120 solver-min.
Retain every raw sample, telemetry, scientific output, search/BDD counters and
cleanup. Semantic mismatch/wrong bound/result/crash immediately rejects and
stops; capacity loss/watchdog or incomplete timeout makes the round INCONCLUSIVE
and stops. No automatic retry or timing-selected omission. Partial timings never
become completed medians. Median and full range comparisons per mode separately;
report any affected-mode disjoint regression and OFF noise. Do not pool prior
LTO/strict/diagnostic round timings.

Purpose: measure whether this unchanged representation behaves differently on
the medium case; not an acceptance test that overrides Tier1 regressions. Any
improvement supports at most a future specialization hypothesis requiring a
new Brain/protocol; a regression strengthens current non-adoption. Dedicated
server corroboration remains pending resources, no automatic Tier3 or merge.

New output E006-windows-tier2-exploratory-01; driver adapted only in case set,
600/615s limits and truthful tier labels from the already used E006 Tier1 driver.
Original Tier1 raw evidence/driver remain unchanged. Independently audit new
commands/results/medians/identities/affinity/priority/capacity/cleanup after run.
