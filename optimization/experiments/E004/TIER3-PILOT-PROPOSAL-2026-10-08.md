# H-007: explicitly authorized exploratory Tier 3 pilot

2026-10-08, before execution. User clarified: when the evidence cannot directly
reject an idea, advance one tier to collect information rather than leaving CPU
unused. This supersedes the prior no-higher-tier execution condition for H-007;
it does not declare Tier 1/2 PASS or permit unsupported acceptance claims.
Exploratory execution and scientific promotion are separate. Preserve safety,
scientific correctness, raw evidence and resource limits.

H-007 already has Tier 0 PASS, Linux/Windows diagnostic Tier 1, and complete
Windows LP340 Tier 2 diagnostics. Next is one bounded Tier 3 case, BB_144_12_12,
on the dedicated yfclab2 server. Same single LTO concept and original Linux
baseline/candidate binaries; verify original 156-file manifest, both binary
hashes and prior Tier 0 PASS. No rebuild, source/heuristic changes or stacking.
Four additional matrix files exported from baseline24572d6/candidate5b13a2c
are byte-identical; separate input manifest preserves the old package manifest.
Distance 12 is checker-only, never fed to the solver.

Pilot cost/scope: one baseline/candidate pair per mode (OFF then MTO), four serial
runs, 600s internal wall limit / 615s external watchdog. Maximum solver budget
40 minutes. This intentionally bounded pilot is not the full seven-case decisive
suite or a three-repeat performance estimate. No medians from singleton samples,
no claim that timeout durations measure completed-solving speed.

If a run reaches its ordinary internal timeout with sound partial bounds, retain
it and still run the paired binary/other mode within this fixed budget: incomplete
results are information, not automatic performance rejection. A scientific
mismatch, invalid bound/output or unexpected crash rejects and stops immediately.
External-watchdog/runtime failure or global capacity loss stops this attempt;
no silent retry, workload killing or change to the resource permission.

One eligible logical CPU selected from observed kernel topology/allowed affinity,
pin the supervisor and all children to it, observe its sibling. Global idle must
remain >50%, one CPU <=half measured spare capacity, checks every two seconds.
Core contention is telemetry only, because installed fixed-core102/230 isolation
is unavailable while230 is busy. No privileged scope expansion, reservation
attestation or controlled-timing claim. Partial/time-to-bound and search traces
may inform subsequent decisions but do not certify optimal distance or speedup.

Retain every output, command, elapsed time, return code, resource sample and input/
binary identity. Report exact/pending bounds and paired descriptive ratios only
when both solves complete correctly. Final pilot status may remain INCONCLUSIVE;
that will no longer itself prohibit the next authorized tier-sized experiment.
Further expensive coverage/repetition is separately scoped from this pilot,
rather than automatically executing the remaining six cases or an unbounded job.
