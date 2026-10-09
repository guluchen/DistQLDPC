# Tier 2 resource interruption and bounded recovery

Recorded after attempt 1 and before any further solve, 2026-10-07.
Preflight idle was 73.75%; during the first OFF baseline it fell to 47.61%.
The original >50% guard terminated the entire process group immediately.
Zero completed samples. This is a resource abort, not a solver timeout, crash,
distance result or performance regression. Retain the archive and partial log.

To fulfill the requested test without exceeding resource permission, observe up
to three 10-second acquisition windows. Require each window's global idle >55%
(an acquisition margin only; the active guard remains >50%). If all three pass,
allow exactly one fresh attempt in a new output directory, with fresh CPU-pair
selection and the same unchanged binaries/driver, 600/615s limits and scientific
checks. If acquisition fails or this second attempt is interrupted/incomplete,
stop with INCONCLUSIVE and no additional retry in this turn. Keep both attempts
separate; do not pool partially completed repetitions or select favorable timing.

No new optimization, acceptance criterion, timeout semantics, resource permission
or controlled-environment claim. No Tier 3. Original run was stopped as required;
this explicit amendment records the recovery decision rather than silently retrying.
