# Unexecuted internal-engine proof continuation

Seven unresolved jobs selected from actual short evidence: all four MaxSAT,
CC512/768/1024. CC256 already returned exact12 and is not rerun. No server
core allocated. Source exact claims are references; independently GF2-checked
source words give upper bounds, not lower exclusions. No external solver.

Each default seed0 job:21600s CPU,22200s wall backstop,4GiB address-space cap,
stdin /dev/null, one explicitly allocated/free pinned core, serially. Aggregate
limits42h CPU/43h10m wall are limits, not solve-time estimates. All numeric
smoke gates already passed; these jobs address independent lower completion.

From a clean frozen checkout of this branch on yfclab2:

```sh
make
python3 optimization/experiments/GH-170/runner/run_serial.py --cpu "$PP4_CORE" --out "$PP4_RESULTS"
```

This only prints commands. After explicit PI allocation and manual free-core
review, set PP4_CORE to that core, PP4_RESULTS to a new directory and supply
the actual allocation reference. Execute detached:

```sh
nohup python3 optimization/experiments/GH-170/runner/run_serial.py --cpu "$PP4_CORE" --out "$PP4_RESULTS" --execute --allocation-ref "$PP4_ALLOCATION_REF" --core-confirmed-free > "$PP4_DRIVER_LOG" 2>&1 < /dev/null &
```

Runner requires yfclab2/clean checkout/allocation/free-core confirmation,
checks affinity and pinned processes, retains source/binary/case/job/input
identities and exact argv, and rechecks inputs/binary before/after every job.
Unexpected answers/witnesses/errors retain evidence and stop. Independent
lower proofs and actual GF2 upper words need scientific review before any
promotion of PLAUSIBLE results. Never fill missing CLI fields from source.
No rename/tiering/QDistSAT mirror/main integration is authorized by execution.

Rebuild the selection into a new file:

```sh
python3 optimization/experiments/GH-170/runner/prepare_jobs.py --audit optimization/experiments/GH-170/raw/actions/default/audit.json --out /tmp/pp4-jobs-rebuilt.jsonl
cmp /tmp/pp4-jobs-rebuilt.jsonl optimization/experiments/GH-170/runner/jobs.jsonl
```

`review_bounds.py` records stronger PLAUSIBLE vs two-engine common lower
bounds separately, tied to the actual audit SHA256. Raw data stays unchanged.
