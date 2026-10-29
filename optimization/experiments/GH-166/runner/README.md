# Optional yfclab2 exact-proof reproduction

Prepared, NOT EXECUTED. jobs.jsonl contains exactly seven short-run outcomes
that did not finish with an exact answer: MaxSAT n=320; both engines at
n=390,550,775. Completed n=160/240 and CC n=320 are excluded. Job fields
follow the baseline queue convention, with reference_claim/expected_d kept
separate from unknown filenames. Upper estimates remain upper estimates.

Reproduce job selection:

```
python3 optimization/experiments/GH-166/runner/prepare_jobs.py \
  --audit optimization/experiments/GH-166/raw/actions/default/audit.json \
  --out /tmp/zsz-unresolved.jsonl
cmp /tmp/zsz-unresolved.jsonl optimization/experiments/GH-166/runner/jobs.jsonl
```

Seven default-seed jobs run serially on ONE explicitly PI-assigned free core.
Each has a 21600s limit, 4 GiB address-space cap, stdin /dev/null and +600s
wall backstop. Worst-case serial budget: 42h of solver limits, 43h10m including
all backstops. This is a reproducible verification package, not authorization
to consume that time or use a server core. No timing/tier adoption is claimed.
A server-enabled agent may propose a smaller selected job file and obtain PI
approval; the runner validates that every job matches the reference cases.

Before execution, PI assigns a core; operator checks current occupancy,
including unpinned jobs. Do not reuse stale core ranges from older rounds.
Use a clean checkout at the exact package commit, build unchanged solver,
freeze it at an absolute path and record its SHA256. Runner records source,
case/job/binary/all-input hashes and rejects changes during execution.

Command-only dry run (safe on Mac, launches no process):

```
python3 optimization/experiments/GH-166/runner/run_serial.py \
  --cpu "$PI_ASSIGNED_CORE" --bin "$FROZEN_BINARY" --out "$NEW_OUTPUT_DIR"
```

Only on yfclab2 after explicit allocation and occupancy checks:

```
nohup python3 optimization/experiments/GH-166/runner/run_serial.py \
  --cpu "$PI_ASSIGNED_CORE" --bin "$FROZEN_BINARY" --out "$NEW_OUTPUT_DIR" \
  --execute --allocation-ref "$PI_APPROVAL_REFERENCE" --core-confirmed-free \
  < /dev/null > "$RUNNER_OUTPUT" 2>&1 &
```

All variables must be supplied by the operator; no core is currently assigned
by this package. Runner checks hostname, Linux, affinity, source cleanliness,
existing pinned userspace processes and explicit allocation/free-core flags.
These checks supplement the human occupancy check; they do not reserve a core.

Outputs: config.json, plain raw .log per job, per-job identity JSON saved even
on a wall-backstop kill, results.json with actual parsed bounds/answers,
independently verified emitted witnesses and conservative exact-result status.
Contradictions and nonstandard exit/identity failures stop the queue after
preserving evidence. DONE means jobs completed, not that all proof gates passed.
Every new exact result remains PLAUSIBLE until independent implementation/search
completion and minimum-weight GF(2) witness cross-check; never rename stems.

The initial short-run lower bounds have their confidence reviewed separately:

```
python3 optimization/experiments/GH-166/runner/review_bounds.py \
  --audit optimization/experiments/GH-166/raw/actions/default/audit.json \
  --out /tmp/zsz-bound-crosschecks.json
cmp /tmp/zsz-bound-crosschecks.json optimization/experiments/GH-166/raw/bound-crosschecks.json
```

For n=390/550/775 the two-engine common lower bound is 9; CC's stronger
15/16/16 observations remain PLAUSIBLE. Witness upper bounds 16/18/22 are
independently verified. Original logs/metadata are never overwritten with
weaker values merely to make the review appear independently complete.
