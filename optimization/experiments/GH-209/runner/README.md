# Remaining polynomial-minor gates and optional research

No server job has run and no core is allocated. Four required jobs are in
`jobs.jsonl`: both engines must finish reproducing the source255 exact12
control; default MaxSAT must obtain numeric fields on PM_1785_80_unknown and
PM_2805_80_unknown. The small source27 control is independently exact4 and
both native engines reproduced4. Actual source word12 and all four algebraic
word54 supports are already independently GF2 verified.

Four new large targets intentionally retain unknown exact distances. Their
CC8 lower bounds are PLAUSIBLE pending independent corroboration. Raw MaxSAT
fields3..64/5..138/null-null/null-null and rawCC8..76/8..100/8..140/8..220
are immutable; independent actual-word upper54 never fills those fields.
Optional2MaxSAT and4CC further searches are in `optional-maxsat-jobs.jsonl`
and `optional-cc-jobs.jsonl`; solving an intended unknown target exactly is
not an acceptance prerequisite. Any new scientific claim remains provisional
until independent review and an actual minimum word.

Use a clean checkout of this branch and build the unchanged solver with
`make`. Get explicit PI core allocation and freshly check the core is free.
Inspect the default required plan before execution:

```sh
python3 optimization/experiments/GH-209/runner/run_serial.py --cpu 54 --out /tmp/gh209-output
```

54 is only a syntax example, **not an allocation**. After allocation, replace
the core/reference/output paths:

```sh
nohup python3 optimization/experiments/GH-209/runner/run_serial.py --cpu 54 --out /absolute/new/gh209-output --execute --allocation-ref 'PI allocation reference' --core-confirmed-free > /absolute/new/launcher.log 2>&1 < /dev/null &
```

Optional queues use the corresponding `--jobs` path and a distinct output
directory. All jobs are serial, seed0,v,taskset pinned,4GiB address-space cap,
21600CPU seconds/22200wall backstop. Required4 ceilings24CPUh/24h40wall;
optionalMaxSAT2=12CPUh/12h20wall; optionalCC4=24CPUh/24h40wall. All10 ceilings
60CPUh/61h40wall. These are limits, not runtime expectations.

The runner regenerates canonical gate/research queues from the immutable
original observations; verifies case/input/source/build identities and every
retained GF2 word; requires a clean checkout, yfclab2, explicit allocation,
fresh free-core confirmation and available affinity; rechecks pinned userspace
processes. Source Git tree/blob checks work without historical commits in
shallow clones. No parameter/seed/cardinality/order sweep or automatic retry.
Raw failures/backstops/contradictions are retained and stop for review; unmet
numeric/source/word gates remain INCOMPLETE. No fields are fabricated.

The generic planner also requires a finder-only word job if numeric upper
or exact claims lack a physical word: CC,budget600per half,`-cc-ub-only`,same
6h/4GiB ceilings. There are ZERO such jobs in this frozen batch; all actual
upper-word gates passed. Known exact controls still must reproduce, while
unknown-target exact completion is optional. This package does not resume
GH200/GH202 source holds or change main/tier/default/stem/QDistSAT.
