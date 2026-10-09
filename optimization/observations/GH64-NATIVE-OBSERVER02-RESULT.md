# GH64 observer validation: acquired attempt 02

2026-10-09. **INCONCLUSIVE: measurement-tool validation incomplete.**
Resource-acquisition attempt 01 never launched a process. This separately
recorded attempt acquired resources and executed the originally unused observer
output namespace; no solver or scientific performance sample ran.

Independent assignment-only source review
`ad24461f41c4aafb03b545e08133e95e71fa6c9759fdf3fefb92c666afe05176`
verified support `a20af720b7359f07e586e3243dadef0f6233c969af20888f2fb9d043586ac5e4`:
only two assignment URL literals differ from the prior reviewed support,
with exact inverse and six unchanged payloads. Fresh remote output absence and
all uploaded support/prior-runtime hashes were checked before launch.

[Assignment](https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6077311720)
and [release](https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6077401546)
cover this bounded validation. Actual helper acquired/capacity/released events,
terminal exit 1, raw child records and output bytes are retained unchanged.

Four scenarios completed: natural zero exit, natural nonzero exit, the expected
synthetic callback rejection, and supervisor timeout. The fifth remaining-cap
scenario failed *before child launch*: its three-second local window included
preflight and metadata work. This is not evidence of a solver semantic mismatch
or of a failed scientific benchmark. The remaining two scenarios did not run;
no seven-scenario PASS certificate exists.

The driver reports `Aggregate exhausted before launch`; its final total elapsed
time is 56.7215 seconds, within the separate 60-second aggregate. Thus the failed
cap was the local scenario window, not the whole-driver deadline. Actual first
natural-zero exit bracket is about 0.698 seconds. The 0.15-second nominal timeout
scenario records terminal observation at about 3.922 seconds, including bounded
supervisor cleanup. These observations require measurement-tool investigation;
they provide no candidate speed or CPU-interference conclusion.

Separate actual post-check confirms helper inactivity, absent experiment group,
recorded process identities absent, and all five original resource-configuration
entries unchanged. Independent terminal-data audit
`384b6ee260f7f4f59025c199ec3c03a41e4b1c91798ceea153d6680b294c3086`
authenticates all18 raw payloads, four actual wait4 outcomes, the fifth prelaunch
failure, terminal/release evidence and seven recorded process identities absent.
The audit initially used a Windows-specific status decoder on Linux raw status;
that verifier failure was archived, then corrected with explicit POSIX decoding.
No runner remains.

Next: preserve this failed validation, diagnose measurement overhead and repair
the engineering harness before another explicitly recorded validation. Preserve
all seven test concepts, ownership and cleanup checks, scientific-result
priority, original numeric judge and timing metrics. Any engineering budget
amendment must be recorded before execution. The source repair scope and budget
were subsequently [preregistered](GH64-NATIVE-OBSERVER-REPAIR01-PRERECORD.md).
Native scientific Tier 1 remains
NOT RUN; native Tier 0 PASS and Windows negative data are unchanged.

Scientific semantics changed: no. Literature source: not applicable.
