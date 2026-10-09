# One original-baseline cross-host correctness check

This is a bounded investigation of the already retained GH46 correctness anomaly,
not an optimization, performance run, repair or change of common baseline.
The user's choice about a separate repair remains pending. Reading source and
checking an existing, unmodified binary cannot substitute for that choice.

Run exactly once on yfclab2 the original baseline24572d6 standalone Main binary
already built and authenticated in native GH41 Tier0-04, without rebuilding or
changing source. Binary SHA256:
86db7efcf42388e76a8fe9e2afc2bfff417ad55d296ce5dc59c2ff84bde32d09.
Use the exact retained GH46 family1-variant1 WCNF (300 bytes), SHA256:
ae851ec8bb80b3a638c40184d5203259ecade373e5598df2c79dbd7d12eb52d4.
Original command flags are only -verb=1, identical to the Windows reproduction.
The independently enumerated optimum is5, witness472. Re-enumerate all1024
assignments and verify input validity before the solve. No candidate executes.

Purpose: determine whether the original scientific anomaly is reproduced with
the existing native GCC13/Linux binary, or remains an unresolved cross-host
difference. Correct native output does not waive the Windows anomaly. A native
crash/missing result is preserved and stops this check; no second run, solver
patch, performance filter or full-correctness claim is permitted.

Authenticate original Tier0 manifest/full tree and runtime inventory before and
after execution, actual source/binary/input identities and per-command critical
runtime identities. Keep command/return/stdout/stderr, actual child birth/session
and owned absence, actual affinity restoration and helper release proof.
Use the existing restricted CPU102/sibling230 lease, global spare>50% and two
reserved CPUs<=half spare. Source and metadata work stay on CPU0. No other runner
may use this host. No performance conclusion follows from elapsed time.

Engineering process limit5 seconds, parent deadline90 seconds (including all
postchecks), with bounded owned TERM3/KILL5-second cleanup; root helper
lease remains bounded by its existing7200 maximum. Expected native execution
milliseconds, plus full identity checks. A lawful engineering timeout is
INCONCLUSIVE, not a correct scientific answer. No source/compiler/configuration,
benchmark truth, bound/output/timeout or CSS/QECC/Pauli semantics change.
DistQLDPC/QDistSAT is its own instrumented MaxCDCL-derived code, not upstream
MaxCDCL; do not assign upstream causation without evidence.
