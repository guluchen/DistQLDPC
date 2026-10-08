# H-007 controlled follow-up prerequisites and commands

Prepared 2026-10-08; **not executed**. No existing diagnostic run establishes a
controlled Tier 1 PASS. User resource limit remains >50% global spare capacity
and no more than half spare CPUs. No Tier 3 runner or blanket merge permission.

Before using the commands below:

1. Obtain a real exclusive/stable yfclab2 window and record its scheduler/operator
   evidence. Do not interrupt other users or invent a reservation note.
2. Complete the installed helper's live acquired-lease, nonzero-command cleanup
   and forced-supervisor recovery validation. Existing validation only confirms
   installation and refusal of busy CPU230. This remains an external dependency.
3. Verify installed helper hash/root ownership/timer and the staged follow-up
   driver hash `43d77c565c3aa0e07c29c829705064368f7072442f2a012aa282ceea13bedf40`.
   Driver checker tests PASS, but its complete controlled integration has not run.

Then, in a Linux shell on yfclab2, with actual reservation evidence supplied via
`DISTQLDPC_RESERVATION_NOTE` (not a placeholder), create a fresh payload directory:

```bash
set -eu
: "${DISTQLDPC_RESERVATION_NOTE:?Set actual exclusive and stable reservation evidence}"
experiment_root=/home/yfc/codex-e004-lto-20261007
fresh_root="$experiment_root/controlled-package-20261008-01"
test ! -e "$fresh_root"
test ! -e "$experiment_root/controlled-results-20261008-01"
printf '%s  %s\n' \
  963c398f3ea87c2fd063bb06a752f1739139c75a5b81e518e44ac28d40844d06 \
  "$experiment_root/E004-server-package.tar.gz" | sha256sum --check
mkdir "$fresh_root"
tar -xzf "$experiment_root/E004-server-package.tar.gz" -C "$fresh_root"
sudo -n /usr/local/sbin/distqldpc-cpu-run run --cwd "$experiment_root" -- \
  /usr/bin/python3 "$experiment_root/controlled_followup.py" \
  --package "$fresh_root/E004-server-package" \
  --output "$experiment_root/controlled-results-20261008-01" \
  --cpu 102 --exclusive-host --reservation-note "$DISTQLDPC_RESERVATION_NOTE" \
  > "$experiment_root/controlled-wrapper-20261008-01.log" 2>&1
```

CPU102 and its sibling230 are still the specifically authorized pair; the
supervisor checks >=95% per-CPU idle at acquisition, >50% global idle and pair
allocation <=half spare every two seconds. It verifies exclusive cpusets and
automatically releases on completion/failure/resource loss. Any wrapper isolation
error invalidates that attempt. Do not select a different pair or weaken the
guard through user-supplied root arguments. Setup scope changes are separate.

The fresh immutable tar excludes objects/binaries, avoiding stale builds. Driver
verifies all 156 hashes, builds baseline/candidate serially with LTO=0/1, runs
the same Tier 0, then the 48 Tier 1 runs. Only a passed original gate permits the
twelve Tier 2 LP340 runs; semantic failures reject and stop. No Tier 3. A driver
filter accept is early-tier evidence, not a research-grade speedup or automatic
merge: retain wrapper logs, full scientific output and hosted correctness checks.

Keep incomplete/aborted evidence, then use a new directory only with separately
justified authorization rather than silently retrying. If the two-hour lease
limit/resource guard ends the run, classify it INCONCLUSIVE. Verify release with
`sudo -n /usr/local/sbin/distqldpc-cpu-run status` and absence of our cgroup/lease.
Copy all run/wrapper logs back into the versioned history and independently
audit expected ground truth, timing medians, resources, binary/compiler identities
and numeric decisions before reconciling STATE/HYPOTHESES. Never pool these
samples with previous desktop/server diagnostics.
