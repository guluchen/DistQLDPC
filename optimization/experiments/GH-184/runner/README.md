# Five closed-color engine-proof/numeric completions — unexecuted

n240/n480 have both-engine exactd8 and need no jobs. n640/n1200/n1440 have
CC-only exact12/8/16, still PLAUSIBLE; default MaxSAT intervals[10,12]/
[6,8]/[4,16]. n2400 remains open with CC[2,8] and no default MaxSAT numeric
fields; its numeric smoke gate stays INCOMPLETE. Actual basis upper8 does
not fill the missing raw fields or prove an exact distance.

Jobs: MaxSAT n640/1200/1440/2400; CC n2400. Upper references12/8/16/8 are
actual independently GF2-verified physical words, not asserted exact answers.
No source Floquet distance/k or geometric floor/ceiling expression is used.
A connected primitive cyclic cover does not supply a distance lower bound.
The fixed cover cases retain actual upper8, not a claim of growing d.

Each job: default seed0,verbose,6hCPU,600s additional wall backstop,4GiB,
serial on one explicitly PI-allocated confirmed-free yfclab2 core,null stdin.
Aggregate30hCPU/30h50mwall are configured limits, not ETA. No server core is
allocated or job executed. Do not run on Mac, Actions or paid cloud.
Use a clean frozen checkout, inspect core ownership/availability and build
the unchanged solver serially on the assigned core. Frozen case SHA,
retained matrix hashes, actual upper word and exact job arguments are checked;
source/binary/job/case/input identities and raw outputs retained. Every new
bound/word is compared with retained other-engine evidence, including
provisional results. An exact result requires a materialized verified minimum
word. Any contradiction stops for scientific review; one-engine results
remain PLAUSIBLE. No auto-name/tier/QDistSAT/default/merge.

Dry-run only (replace CORE by the assigned integer):

```sh
python3 optimization/experiments/GH-184/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

Only after explicit PI allocation and a fresh free-core check:

```sh
nohup python3 optimization/experiments/GH-184/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Default dry-run (54 used syntactically only, no allocation), Mac execution
refusal and altered-argv refusal pass without solver invocation/output
directory. Host, clean-checkout, stale-case/input/argv, missing allocation
and occupied-core guards apply. Independent construction may continue while
these five jobs await allocation and independent scientific review.
