# Seven engine-proof/numeric completions — unexecuted

n169 and n361 have two-engine exactd2/4 and need no further jobs. n841
CC-only exact6 remains PLAUSIBLE; MaxSAT returned[3,6]. n1369/n1849/n2809
remain open with provisional combined intervals[10,12]/[9,16]/[8,49].
Default MaxSAT n2809 returned no numeric fields: its numeric smoke gate
stays INCOMPLETE. No independent or CC value fills those missing raw fields.

Jobs: MaxSAT n841/1369/1849/2809; CC n1369/1849/2809. References6/12/16/49
are actual independently GF2-verified physical upper words, not asserted exact
answers. n2809's CC initial49 comes from an actual supplied basis row; its
full support/input hashes are materialized in raw/basis_words.json by
verify_retained_basis_words.py. No combinations or support search were used.
Each job: default seed0,verbose,6hCPU,600s extra wall backstop,4GiB,serial
on one explicitly PI-allocated free yfclab2 core, null stdin. Aggregate
42hCPU/43h10mwall are configured limits, not an ETA. No core is allocated and
no server job has run. Do not run this on the Mac, Actions or paid cloud.

Use a clean frozen checkout, inspect ownership/availability and build the
unchanged solver serially on the assigned core. Frozen case SHA, exact job
arguments, retained-smoke matrix hashes and actual upper words are checked
before execution. Source/binary/job/case/input identities and raw logs are
retained. Bounds and actual words are compared with retained other-engine
evidence, including provisional results; a contradiction stops for scientific
review. A timeout stays incomplete; one-engine results remain PLAUSIBLE.
No auto-name/tier/QDistSAT/default/merge.

Inspect default dry-run (replace CORE by the assigned integer):

```sh
python3 optimization/experiments/GH-179/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

Only after explicit PI allocation and a fresh free-core check:

```sh
nohup python3 optimization/experiments/GH-179/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Host, clean-checkout, stale-case/input/argv, missing-allocation and occupied-
core guards apply. Default dry-run (54 is a syntactic test value, no allocation),
Mac --execute refusal and altered-argv refusal pass without any solver
invocation or output directory creation. Construction may continue while
these seven jobs await allocation and independent scientific review.
