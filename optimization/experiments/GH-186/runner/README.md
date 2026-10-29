# Three finite DHLV MaxSAT proof/numeric completions — unexecuted

Both engines confirm exact4/8/6 at n108/784/1176. No jobs for those cases.
Remaining CC-only exact16/10/14 at n1568/1960/2744 are PLAUSIBLE until
independent lower-proof completion. Default MaxSAT60s intervals[5,16]/
[3,10], and no numeric fields at n2744. That last numeric gate remains
INCOMPLETE; another engine's result or a basis word does not fill it.

Three frozen jobs: MaxSAT n1568/1960/2744. References16/10/14 are actual
independently GF2-verified physical upper words, not assumed exact answers.
No geometric edge-block weight or unverified asymptotic theorem is used.

Each job: defaultseed0,verbose,6hCPU+600swall backstop,4GiB,serial pinned
explicitly PI-allocated confirmed-free yfclab2 core,nohup/nullstdin.
Aggregate18hCPU/18h30mwall are configured LIMITS, not ETA. No core allocated
or server job run. Do not execute on Mac, Actions or a paid cloud substitute.

Use a clean frozen checkout; build the unchanged solver serially on the
assigned core. The runner checks exact case/input/job/argv identities and
actual upper words, then retains logs/source/binary/input hashes. New bounds
and words are checked against all retained other-engine evidence. An exact
answer requires a materialized verified minimum word. A contradiction stops
for scientific review; no automatic rename, tier, QDistSAT mirror or merge.

Dry-run only (replace CORE by the assigned integer):
```
python3 optimization/experiments/GH-186/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

Only after explicit PI allocation and a fresh free-core check:
```
nohup python3 optimization/experiments/GH-186/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Dry-run CPU54 is syntactic only, not an allocation. Mac execution and
altered-argv guards reject without a solver invocation or output directory.
Independent construction/research can continue while these jobs await review.
