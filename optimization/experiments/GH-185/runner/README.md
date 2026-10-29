# One static3D-color proof completion — unexecuted

Both engines reproduce d2 on the published cube anchor, d4 on n384/576/864
and d6 on n1296/1728. Those need no server jobs. At n2304, MaxSAT60s gives
[5,6] and CC60s exact6; the latter remains PLAUSIBLE until independent
lower-proof completion. Both numeric smoke gates pass. Actual GF2-verified
physical upper6 is the reference; it is not an assumed exact answer.

One frozen job: default MaxSAT n2304, explicit default seed0, verbose,
6hCPU +600s wall backstop,4GiB, serial pinned PI-allocated confirmed-free
yfclab2 core, nohup/nullstdin.6hCPU/6h10mwall are configured LIMITS, not ETA.
No server core allocated or job executed; do not run on Mac/Actions/paid cloud.

Use a clean frozen branch checkout and build the unchanged solver serially
on the allocated core. The runner verifies exact case/input/job/argv identity,
actual physical upper and retained other-engine bounds; it saves all logs
and source/binary/input identities. An exact answer requires a materialized
verified minimum word. A contradiction stops for scientific review. Further
scientific review remains required; no automatic rename, tier or main merge.

Dry-run only (replace CORE by the assigned integer):
```
python3 optimization/experiments/GH-185/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```

After explicit PI allocation and a fresh free-core check:
```
nohup python3 optimization/experiments/GH-185/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

Dry-run CPU54 is a syntactic check only. Mac execution and altered-argv
guards reject without invoking any solver or creating an output directory.
Other family construction/research can continue while this job is pending.
