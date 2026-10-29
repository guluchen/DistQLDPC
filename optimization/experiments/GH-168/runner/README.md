# Toric missing-numeric CLI continuation (not executed)

Three jobs only: MaxSAT n1458 and both engines n2888. No server core assigned.
The independent internal graph oracle already confirms d27/38; this package
addresses actual missing CLI numeric outputs, without substituting that oracle
into the CLI. CC n1458 already prints [25,27] and needs no repeated gate run.

Each default seed0 job has21600s CPU,22200s wall backstop,4GiB address cap,
stdin /dev/null and one explicitly allocated/free pinned core, serially.
Aggregate limits18h CPU/18h30m wall; these are limits, not runtime forecasts.

From a clean frozen checkout of this work branch on yfclab2, after building:

```sh
make
python3 optimization/experiments/GH-168/runner/run_serial.py --cpu "$TOR_CORE" --out "$TOR_RESULTS"
```

This only prints commands. After explicit PI allocation and free-core review,
set TOR_CORE to that core, TOR_RESULTS to a new results directory, and supply
the real allocation reference. Execute detached:

```sh
nohup python3 optimization/experiments/GH-168/runner/run_serial.py --cpu "$TOR_CORE" --out "$TOR_RESULTS" --execute --allocation-ref "$TOR_ALLOCATION_REF" --core-confirmed-free > "$TOR_DRIVER_LOG" 2>&1 < /dev/null &
```

The runner refuses execution outside yfclab2 or a clean checkout, checks
affinity/existing pinned processes, and requires manual allocation/free-core
confirmation. It retains source/binary/case/job/input hashes, exact commands,
raw logs and bounds, checking inputs and binary before/after every run. Any
unexpected answer/witness/error retains evidence and stops. No external solver.
Manual numeric-gate review is still needed after completion; missing outputs
remain incomplete. Do not change unknown stems, assign tiers or merge main.

Reproduce the selection from actual smoke evidence into a new file:

```sh
python3 optimization/experiments/GH-168/runner/prepare_jobs.py --audit optimization/experiments/GH-168/raw/actions/default/audit.json --out /tmp/tor-jobs-rebuilt.jsonl
cmp /tmp/tor-jobs-rebuilt.jsonl optimization/experiments/GH-168/runner/jobs.jsonl
```
