# Six engine-proof/numeric completions — unexecuted

n252 and n378 have both-engine exactd9 and need no further jobs.
n1400 CC-only exact13 and n2100 CC-only exact18 remain PLAUSIBLE;
MaxSAT n1400 returned[9,13], while n2100 default60s returned no numbers.
n1750/n2800 remain open with provisional CC intervals[20,23]/[20,25];
default MaxSAT returned no numeric fields. Their numeric smoke gates remain
INCOMPLETE; verified algebraic upper25 does not fill raw missing fields.

Jobs: MaxSAT n1400/1750/2100/2800; CC n1750/2800. All source-individual
exact distances were unpublished/unknown; each job's reference is ONLY the
independently GF2-verified upperL25, never an asserted exact answer.
Each job: default seed0,verbose,6hCPU,600s extra wall backstop,4GiB,serial
on one explicitly PI-allocated free yfclab2 core, null stdin. Aggregate
36hCPU/37hwall are configured limits, not an ETA. No core is allocated and
no server job has run. Do not run this on the Mac, Actions or paid cloud.

Use a clean frozen checkout, inspect ownership/availability and build the
unchanged solver serially on the assigned core. Frozen case SHA, exact job
arguments and retained-smoke matrix hashes are checked before execution.
Source/binary/job/case/input identities and raw logs are retained. Bounds
and actual words are compared with retained other-engine evidence, including
provisional results; a contradiction stops for scientific review rather than
silently overwriting the earlier result. A timeout stays incomplete and a
one-engine result remains PLAUSIBLE. No auto-name/tier/QDistSAT/default/merge.

Inspect default dry-run (replace CORE by assigned integer):

```sh
python3 optimization/experiments/GH-178/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

Only after explicit PI allocation and a fresh free-core check:

```sh
nohup python3 optimization/experiments/GH-178/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Host, clean-checkout, stale-case/input/argv, missing-allocation and occupied-
core guards apply. Default dry-run, Mac --execute refusal and altered-argv
refusal were tested with no solver execution. Independent library construction
can continue while these six jobs await a core allocation and review.
