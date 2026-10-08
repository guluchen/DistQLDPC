# GH40 Tier1: local NOT ADOPTED; controlled INCONCLUSIVE

One production concept remains direct ternary tail evaluation in
propagateForLK. No scientific semantics, encoding, solver flags or other
optimizations changed. DistQLDPC/QDistSAT remains the downstream MaxCDCL-derived
application, not upstream MaxCDCL.

Baseline24572d6 / production2a7332f; original successful02 production binaries
a8846446 / c6005150 reused unchanged after complete Tier0 and required hosted
source reconciliation. Prelaunch repaired exactly two stale GH27 provenance paths;
no solver, timing or guard behavior changed. Actual support
09c32ed8151233ba3eac9a0477277a00a2e110a0, executed driver SHA256
bbefb3cffa423d4508007e2e82cb7b5bbb6b26a9adc89e3194f2ddf2c030f9dd,
assignment6067775885, session33687, fresh GH40-windows-tier1-01.

All48 serial AB/BA/AB production solves completed rc0 with identical expected
distance/objective/final LB/UB and sound every interim field; independently
reparsed against original ground truth. All raw argv/stdout/stderr/timings,
resources, identities and manifest retained in raw/windows-tier1-01. AUDIT.json
recomputes medians from raw commands and validates all154 original manifest files.

| Case | Mode | Baseline median s | Candidate median s | Change |
|---|---|---:|---:|---:|
| BB_90_8_10 | OFF | 2.469573 | 2.504317 | +1.4069% |
| BB_90_8_10 | MTO | 2.970292 | 3.080232 | +3.7013% |
| GB_144_12_8 | OFF | 1.036067 | 1.084255 | +4.6510% |
| GB_144_12_8 | MTO | 1.292008 | 1.346803 | +4.2411% |
| BB_108_8_10 | OFF | 3.016676 | 3.084582 | +2.2510% |
| BB_108_8_10 | MTO | 3.824053 | 3.946665 | +3.2063% |
| LP_238_44_6 | OFF | 2.067516 | 2.147186 | +3.8534% |
| LP_238_44_6 | MTO | 2.440714 | 2.564284 | +5.0629% |

All eight groups have min(candidate)>max(baseline), not merely slower medians.
Median ratio geometric means OFF1.030326346 / MTO1.040506285 (about +3.03%/+4.05%).
Original numeric filter rejects at its first confirmed per-case regression;
independent audit retains and evaluates all eight groups rather than truncating
that first-hit judge output. No Tier1 PASS or improvement claimed.

Actual helper CPU4/sibling5, mask16, AboveNormal32768;85 resource samples all
capacity-eligible, minimum global spare85.25046%, minimum sibling idle88.88889%,
four contention flags preserved. These flags occur in baseline preflight samples;
this observation does not prove a causal effect or absence of other noise. Host
was observed quiet, without OS reservation; formal controlled performance decision
therefore remains INCONCLUSIVE. Practical local decision is SHELVED / NOT ADOPTED:
consistent negative direction does not justify further local Tier2 expense or the
standing user one-tier exception. No Tier2/Tier3 run, no merge/adoption.

All preparation/runtime/input/source/binary/support postpins passed. Final owned
actions=[]/remaining=[]/confirmed=true; only runner14708 before Job release,
verified absent after sessionexit0. All four actual restores passed, final mask
65535/Normal32. Released hub6067854318 before retention/publication. Full failed
Tier0 attempt01 remains unchanged with its explicit engineering correction.

Learning: nonzero ternary counts did not predict benefit. Added size branch/code
layout could outweigh scan savings, but counters and timings do not establish
which mechanism caused the slowdown. A future exact controlled revalidation may
resolve that limitation; no universal ternary-optimization rejection asserted.
Next independent Brain should propose exactly three single-concept options from
shared evidence, with attention to measured repeated work or stronger impact
evidence instead of assuming a shorter source path is faster. No paper origin;
BibTeX not applicable.
