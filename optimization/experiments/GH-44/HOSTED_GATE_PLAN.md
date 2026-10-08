# Hosted ISA compatibility validation repair prerecord

Source-only2026-10-09, BEFORE workflow changes. Production ISA scope stays
4a820ac, one Makefile token; no solver/test oracle/time limit/result change.

Automatic original PR checks started before an explicit hardware/OS gate was
added. OrdinaryCI37837239436 succeeded and crossrepo37837239674 was in progress
when inspected. These runs did not retain actual CPUID/XCR0 before v3 execution;
they cannot satisfy the experiment's stated preflight requirement. Do not
retroactively claim a certified hosted ISA environment or inherit this PASS.

Supporting repair: in BOTH existing ordinaryCI and QDistSAT crossrepo workflows,
after original build dependencies but before ANY production build/execution,
compile the registered cpu_isa_gate.cc with portable explicit x86-64/generic
flags, run it and retain exact JSON in logs. Crossrepo additionally retains
isa-gate.json in the ordinary benchmark artifact. Gate must succeed; unsupported
runner fails compatibility before scientific comparison rather than being
reported as a wrong-distance result. Same original pilot cases, comparison
checker,45s timeout, baseline/candidate build modes, result/exit/escalation
interpretation and shared timing restriction remain unchanged.

This is validation support for the one ISA concept; not an optimization,
CPU reservation or CI timing conclusion. Actual local compiler/CPU/OS proofs
remain independently mandatory and currently NOT RUN. Windows GH38 standard48
Tier1 owns6068139292, no GH44 probes/builds/tests during it.
