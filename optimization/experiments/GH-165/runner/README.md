# Optional yfclab2 internal-engine reproduction package

Two explicit JSONL jobs, baseline queue field conventions: one default-seed
MaxSAT, one default-seed CC solve of HYP_1800_182_unknown, serial on one
PI-assigned free core. Each has a 21600s CPU limit, 4 GiB address-space cap,
stdin /dev/null and limit+600s process-group backstop. Worst-case serial wall
budget is about 12h20m. This package is prepared, NOT EXECUTED. It is not a
baseline/tiering or performance-comparison run, and assigns no server cores.

The independent graph oracle already certifies both half distances 10. These
jobs ask the general internal engines to independently complete their proofs
beyond the short smoke limits. Any contradiction stops the queue for PI review.
No external solver is used. No automatic stem rename or tier move follows.

1. PI/server-enabled agent obtains explicit core assignment, checks occupancy
   (including unpinned jobs) and confirms the selected core is free. Existing
   active rounds may occupy previously free cores; do not reuse old ranges.
2. On yfclab2 use a clean checkout of this work branch at the exact commit
   containing this package. Record `git rev-parse HEAD`, build unchanged
   solver with `make --jobs=2 bin/distqldpc`, then freeze the resulting binary
   at an absolute path and record `sha256sum` of it. Recheck source cleanliness.
3. Inspect commands first (works on Mac too; no process launches):

```
python3 optimization/experiments/GH-165/runner/run_serial.py \
  --cpu "$PI_ASSIGNED_CORE" --bin "$FROZEN_BINARY" --out "$NEW_OUTPUT_DIR"
```

4. On the dedicated server only, after allocation and occupancy checks:

```
nohup python3 optimization/experiments/GH-165/runner/run_serial.py \
  --cpu "$PI_ASSIGNED_CORE" --bin "$FROZEN_BINARY" --out "$NEW_OUTPUT_DIR" \
  --execute --allocation-ref "$PI_APPROVAL_REFERENCE" --core-confirmed-free \
  < /dev/null > "$RUNNER_OUTPUT" 2>&1 &
```

The variables above must be supplied by the operator; they do not imply a
current assignment. The runner checks dedicated hostname, Linux, affinity,
existing pinned userspace processes and a clean source checkout. Its check
supplements the operator's occupancy check; it cannot reserve a core against
other agents. One solver process runs at a time on that core.

Outputs: config.json with source, binary, jobs and resource identities; exact
plain .log per job; per-job identity JSON even on a wall-backstop failure;
results.json with actual parsed bounds/status and verified emitted witnesses;
DONE only after both jobs complete. Unknown/partial bounds remain missing,
not replaced with oracle knowledge. The expected distance 10 is kept separate
from the unknown stem in the job file, unlike baseline runners that parse a
numeric distance from the filename.

Validation here: command-only dry run produces exactly the two prescribed
commands. No long run has been performed on the Mac, CI, or a server.
