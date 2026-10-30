# Frozen remaining BCH gates

No job has been executed and no core is allocated. `jobs.jsonl` contains only
the two n1365 default MaxSAT missing-numeric/proof gates. `optional-cc-jobs.jsonl`
contains the same two remaining distance gaps. Bounds17..22/19..24 combine an
independent physical-root lower certificate and actual GF2 upper words; they
do not replace old engine fields. Exact5/9/11 already have finite certificates
and need no heavy search for independent confirmation.

On a clean checkout of this branch, build the unchanged binary with `make`.
Get an explicit PI allocation and freshly check the proposed core is free.
Runner rechecks pinned userspace processes, allowed affinity, input identities,
all finite certificates, retained words, frozen source/build trees and job
definitions. Source identities use Git trees, including in shallow checkouts.
The old binary hash is recorded but a separately built unchanged-source binary
may differ; each new run records its own fixed binary SHA256.

Dry plan (54 is a syntax example, **not an allocation**):

```sh
python3 optimization/experiments/GH-207/runner/run_serial.py --cpu 54 --out /tmp/gh207-run
```

After PI allocation, replace the example core and reference:

```sh
nohup python3 optimization/experiments/GH-207/runner/run_serial.py --cpu 54 --out /absolute/new/output-directory --execute --allocation-ref 'PI allocation reference' --core-confirmed-free > /absolute/new/launcher.log 2>&1 < /dev/null &
```

To select optional CC, supply `--jobs
optimization/experiments/GH-207/runner/optional-cc-jobs.jsonl` and a different
output directory. Both canonical queues are serial, taskset pinned, seed0,
4GiB address-space cap,21600CPU seconds and22200wall backstop per case.
Each queue has12CPUh/12h20wall ceilings; both queues24CPUh/24h40wall. These
are limits, not expected runtimes. No seed/cardinality/order sweep or automatic
retry. Wall-backstop or semantic inconsistency stops with evidence retained.
New search claims remain PLAUSIBLE until independently reviewed; new words
are GF2 checked immediately. No missing numeric field is synthesized.
