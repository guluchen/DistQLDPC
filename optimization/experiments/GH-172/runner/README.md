# Unresolved static4.8.8 proof jobs — not executed

Seven jobs selected from the retained short-run audit: MaxSAT n199 and both
engines for n647,1567,2887. Unknown stems and source claims stay separate.
Limits6h CPU plus600s wall backstop per job, serial4GiB process on one
PI-assigned free yfclab2 core. Aggregate configured42h CPU/43h10m wall is a
limit, not a forecast. No allocation has been made and no job is launched.

Freeze a clean checkout of this work branch and build the unchanged solver
on yfclab2. Record its exact source, compiler, binary and matrix identities.
Read the report and confirm that a second agent has not claimed the same
proofs/cores. Do not use the PI's Mac or shared Actions for these long jobs.

Inspect without executing:

```sh
python3 optimization/experiments/GH-172/runner/run_serial.py --cpu CORE --out /absolute/new/evidence-directory
```

After explicit PI core allocation and a fresh free-core check:

```sh
nohup python3 optimization/experiments/GH-172/runner/run_serial.py --cpu CORE --out /absolute/new/evidence-directory --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```

The launcher refuses execution off yfclab2, a dirty checkout, an unallocated
core, changed frozen jobs/cases or a pinned process already on the core.
It rechecks the core and binary/input hashes between jobs, uses null stdin,
stops after contradictions/backstop failures, and retains raw evidence.
No automatic completion, renaming, tiering, merging or QDistSAT mirroring.

Preparation/review from actual audit (new output paths required for jobs):

```sh
python3 optimization/experiments/GH-172/runner/prepare_jobs.py --audit optimization/experiments/GH-172/raw/actions/default/audit.json --out /tmp/color488-proof-jobs.jsonl
python3 optimization/experiments/GH-172/runner/review_bounds.py --audit optimization/experiments/GH-172/raw/actions/default/audit.json --out /tmp/color488-bounds-review.json
```

Only unresolved engine results create jobs. A one-engine exact/lower result
remains PLAUSIBLE until independent implementation/search completion and
GF(2) witness review. Missing CLI lower/upper fields stay missing even when
the independently constructed boundary proves a separate upper bound.
