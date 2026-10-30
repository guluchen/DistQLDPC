# QR remaining numeric gate and optional distance research

No job has run and no core is allocated. Exactly one acceptance gate is
incomplete: default MaxSAT on QR_2039_1_unknown returned TIMEOUT_NO_BOUNDS
in the frozen60CPU-second attempt. `jobs.jsonl` contains only that numeric
completion. The other four codes have numeric fields from both engines.
The known23-qubit Golay control is exact7 independently and in both engines.

The four large codes are intended unresolved-distance targets. Exact distance
is not a prerequisite for library acceptance. Optional additional research
is explicitly separate: `optional-maxsat-jobs.jsonl` has the three other
MaxSAT cases; `optional-cc-jobs.jsonl` has all four CC targets. Their source
floors and actual-word uppers are23..71/31..135/35..191/47..427. Raw native
bounds remain weaker and are not overwritten. Source lower-only claims never
require finding a word at the lower endpoint.

On a clean checkout, build the unchanged solver with `make`. After an explicit
PI allocation and fresh check that the core is free, inspect a dry plan:

```sh
python3 optimization/experiments/GH-208/runner/run_serial.py --cpu 54 --out /tmp/gh208-output
```

54 is a syntax example, **not a core allocation**. Only after allocation,
replace the example core/reference/output paths:

```sh
nohup python3 optimization/experiments/GH-208/runner/run_serial.py --cpu 54 --out /absolute/new/gh208-output --execute --allocation-ref 'PI allocation reference' --core-confirmed-free > /absolute/new/launcher.log 2>&1 < /dev/null &
```

Optional queues require the corresponding `--jobs` path and a distinct output
directory. The runner validates the three frozen queues, physical source/input
hashes, independent finite correlation certificates, retained words, clean
checkout and source/build Git trees (no historical objects needed). It checks
allowed affinity and pinned userspace processes, and requires the operator's
fresh free-core confirmation. Every actual command uses taskset, seed0,v,
4GiB address-space cap,21600CPU seconds and22200wall backstop; jobs are serial.

Limits, not runtime expectations: required1=6CPUh/6h10wall; optional MaxSAT3=
18CPUh/18h30wall; optionalCC4=24CPUh/24h40wall. All8 would have48CPUh/
49h20wall ceilings. No seed/cardinality/order sweep or automatic retry. New
scientific search claims stay PLAUSIBLE until independent review and actual
GF2 words; contradictions/backstop stop with evidence retained. Missing
numeric fields are never fabricated. This package does not resume GH200/GH202.
