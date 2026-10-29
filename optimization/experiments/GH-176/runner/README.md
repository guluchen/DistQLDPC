# Seven unresolved engine proofs — unexecuted

All12 short runs emitted consistent numeric intervals and actual verified
upper words. n64,d8 and n128,d12 have both-engine exact confirmation.
n192 CC-only exact16 is PLAUSIBLE until MaxSAT or another independent search
completes. Other open cases retain provisional CC lower bounds18 and verified
uppers20/22/24. Their source upper labels do not become exact references.

Jobs: MaxSAT n192,216,256,288; CC n216,256,288. Each uses default seed0,
verbose,6hCPU,600s extra wall backstop,4GiB, serial on one explicitly
PI-allocated free yfclab2 core, null stdin. Aggregate42hCPU/43h10mwall are
configured limits, not an ETA. No core is allocated and no job has run.
Do not execute on the Mac, routine Actions or a paid substitute environment.

Use a clean frozen checkout; check ownership/availability and build unchanged
solver serially on the assigned core. Cases, input matrix hashes from retained
smoke evidence and exact argv are checked before dry-run/execution. Runtime
records source/binary/case/job/input identities and raw output. It rechecks
bounds/words against retained other-engine evidence; contradictions stop for
scientific review. A timeout or one-engine improvement remains incomplete/
PLAUSIBLE, with no automatic name/tier/QDistSAT/merge change.

Inspect (default dry-run; replace CORE with assigned integer):

```sh
python3 optimization/experiments/GH-176/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

Only after explicit PI allocation and a fresh free-core check:

```sh
nohup python3 optimization/experiments/GH-176/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Host, clean-checkout, frozen-case/input/argv, allocation and free-core guards
apply; wall failures retain evidence and stop. Dry-run, Mac --execute refusal
and altered-argv refusal were tested without running any solver. Independent
library work continues while this package awaits allocated server execution.
