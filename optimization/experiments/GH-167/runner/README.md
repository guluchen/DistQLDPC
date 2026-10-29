# Unexecuted PP proof continuation

Seven unresolved engine jobs only; no server core is assigned. Source exact
claims are references, not results. No timing/adoption experiment or tiering.
Each job: default seed0, unchanged engine, 21600s CPU, 22200s wall backstop,
4GiB address-space cap, stdin /dev/null, one explicitly allocated pinned core.
All seven serial limits total42h CPU /43h10m wall. This is not a runtime forecast.

From a clean checkout of the final GH-167 branch, build on yfclab2:

```sh
make
python3 optimization/experiments/GH-167/runner/run_serial.py --cpu "$PP_CORE" --out "$PP_RESULTS"
```

The command above only prints commands. After PI allocation, independently
checking that the core is free, set PP_CORE to that core and PP_RESULTS to a
new results directory. Execute detached, with the real allocation reference:

```sh
nohup python3 optimization/experiments/GH-167/runner/run_serial.py --cpu "$PP_CORE" --out "$PP_RESULTS" --execute --allocation-ref "$PP_ALLOCATION_REF" --core-confirmed-free > "$PP_DRIVER_LOG" 2>&1 < /dev/null &
```

Do not reuse currently occupied/unassigned cores without PI allocation.
Runner checks yfclab2, clean source, affinity and existing pinned processes;
manual allocation/free-core confirmation remains required. Source, binary,
case/job/input hashes and exact argv are retained. Inputs/binary are checked
before and after runs. Unexpected answers, witnesses or missing-result failures
retain raw evidence and stop. No external solver is invoked.

Review retained engine lower bounds independently and verify minimum-weight
logical words in GF(2) before promoting PLAUSIBLE results. A successful process
exit or source matching alone does not complete the cross-check. Update the
numeric gate for n1784 only after actual lower and upper outputs exist.

Regenerate the job set from actual short-run audit into a new file:

```sh
python3 optimization/experiments/GH-167/runner/prepare_jobs.py --audit optimization/experiments/GH-167/raw/actions/default/audit.json --out /tmp/pp-jobs-fresh.jsonl
cmp /tmp/pp-jobs-fresh.jsonl optimization/experiments/GH-167/runner/jobs.jsonl
```
