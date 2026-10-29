# Unexecuted internal-engine proof continuation

Eleven unresolved engine jobs selected from actual60s evidence: six MaxSAT,
CC for all except the already solved n756 case. No server core assigned.
Source claims are randomized uppers, not target exact answers. Smaller exact
answers/witnesses are compatible; a certified lower exceeding the source
upper is a scientific escalation. Never run an external distance tool.

Each job: default seed0,21600s CPU,22200s wall backstop,4GiB address cap,
stdin /dev/null, explicitly allocated/free pinned core, serially. Aggregate
limits66h CPU/67h50m wall are limits, not runtime estimates. All short numeric
gates already passed; these jobs address independent lower-bound completion.

From a clean frozen checkout on yfclab2:

```sh
make
python3 optimization/experiments/GH-169/runner/run_serial.py --cpu "$TN_CORE" --out "$TN_RESULTS"
```

This only prints commands. After PI allocation and independent free-core
review, set TN_CORE to that core, TN_RESULTS to a new directory and supply
the actual allocation reference. Run detached:

```sh
nohup python3 optimization/experiments/GH-169/runner/run_serial.py --cpu "$TN_CORE" --out "$TN_RESULTS" --execute --allocation-ref "$TN_ALLOCATION_REF" --core-confirmed-free > "$TN_DRIVER_LOG" 2>&1 < /dev/null &
```

The runner requires yfclab2, a clean checkout, explicit allocation/free-core
confirmation, affinity and pinned-process checks. It retains source/binary/
job/case/input identities, exact commands and raw outputs; input and binary
hashes are checked before/after every job. Unexpected results retain evidence
and stop. Process completion alone does not authorize scientific promotion,
renaming, tier assignment or main integration. Compare independent lower
proofs and independently check actual attaining words in GF(2).

Rebuild the job selection from actual audit into a new file:

```sh
python3 optimization/experiments/GH-169/runner/prepare_jobs.py --audit optimization/experiments/GH-169/raw/actions/default/audit.json --out /tmp/tn-jobs-rebuilt.jsonl
cmp /tmp/tn-jobs-rebuilt.jsonl optimization/experiments/GH-169/runner/jobs.jsonl
```

`review_bounds.py` separately records common two-engine lower bounds and
stronger PLAUSIBLE values, without rewriting raw bounds. Its JSON binds the
source audit digest. The verified upper word can come from either engine;
it is a separate GF(2) certificate shared by both searches.
