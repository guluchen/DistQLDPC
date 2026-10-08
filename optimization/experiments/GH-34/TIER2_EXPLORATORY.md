# GH-34 exploratory Tier2 preregistration (written before any LP_340 timing)

Basis: Tier1 gate INCONCLUSIVE, not rejected (TIER1_RESULT.md). Standing user
instruction recorded in docs/OPTIMIZATION_LOOP_POLICY.md on branch
experiment/h001-logical-row-xor, section "User-directed exploratory continuation
(2026-10-08)": "if the evidence does not clearly justify rejection, advance one
tier ... It does not turn an inconclusive gate into PASS or authorize acceptance,
merge, or a controlled performance claim." This run is that one bounded step.

Scope: LP_340_56_8 only, `-no-card` and `-card-mto`, baseline 3 + candidate 3 per
mode in AB/BA/AB order (12 solves), `-cpu-lim=600`, watchdog 615 s, same frozen
binaries and hashes as Tier1, same host, same load guard (< 6.0), same science
checks (rc 0, `o 8`, identical emitted progress/bound lines across versions).
Any timeout in either version is recorded as INCONCLUSIVE for that mode, never
as a completed sample. No replication phase, no reruns, no Tier3.

Command:

    python3 -I optimization/experiments/GH-34/tier1_mac.py \
      --base ../base/bin/distqldpc --cand bin/distqldpc \
      --out optimization/experiments/GH-34/raw/tier2-exploratory-01 \
      --cases LP_340_56_8 --limit 600 --watchdog 615

Interpretation (fixed now): report per-mode medians, ranges and ratio. Consistent
direction with Tier1 (candidate median lower in both modes, no non-overlapping
regression) = "exploratory direction consistent"; reversal or a non-overlapping
regression = "not corroborated", which shelves the hypothesis. Either way the
formal status stays INCONCLUSIVE pending controlled dedicated-server runs.
Budget: about 12 x 40–90 s on this host (< 20 min).
