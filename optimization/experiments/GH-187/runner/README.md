# Two quantum Margulis MaxSAT proof/numeric jobs — unexecuted

Both engines cross-check n672 exact8 with a verified minimum word; no job
for that case. n240 CC-only17 and n2640 CC-only10 remain PLAUSIBLE until an
independent complete lower proof. Default MaxSAT gives[9,17] and no numeric
fields respectively. The last numeric gate is INCOMPLETE, not filled from CC.

Two frozen jobs use actual independently GF2-verified physical upper words
17/10, not presumed exact answers. Each6hCPU+600swall/4GiB/defaultseed0/
verbose/serial pinned explicitly PI-allocated confirmed-free yfclab2 core.
Aggregate12hCPU/12h20mwall are configured LIMITS, not ETA. No allocation/run.
Do not execute on Mac, Actions or paid cloud substitute.

Use a clean frozen checkout and build the unchanged solver on the assigned
core. Exact cases/input/job/argv identities, physical words and other-engine
contradictions are checked; retain source/binary/input hashes and logs. New
exact answers require materialized verified minimum words; contradictions
stop for scientific review. No rename, tier, mirror or automatic integration.

Dry-run only (CORE must be replaced by an integer):
```
python3 optimization/experiments/GH-187/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```
Only after explicit PI allocation and a fresh free-core check:
```
nohup python3 optimization/experiments/GH-187/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```
CPU54 in retained dry-run is syntactic only. Mac/altered-argv guards reject
without solver invocation or output directory. Continue independent research
on unresolved-distance candidates while these proof jobs await allocation.
