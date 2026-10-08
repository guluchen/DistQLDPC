# GH-34 preregistered 60 s trace-identity check — PASS

Plan: TIER0_60S_PLAN.md (committed before running). 38 stems x 4 modes = 152
comparisons, `-cpu-lim=60`, same frozen binaries. Raw: `raw/tier0-60s/`.

- Completed within 60 s: 10 comparisons, all byte-identical (stdout, stderr, exit
  code); distances as named: BB_144_12_12 = 12 (all 4 modes), TN_108_2_12 = 12
  (all 4 modes), TN_200_10_10 = 10 (default, card-mto). These are the runs the 20 s
  sweep could only prefix-check.
- Timed out: 142 comparisons, all OK under the comparator declared in the plan
  (child output prefix-consistent, TIMEOUT trailer in both, bounds consistent).
- The original harness comparator (known defective, kept for continuity) flagged 1
  pair as `TIMEOUT-PREFIX-MISMATCH`; the declared comparator accepts it, as
  expected from the documented defect. Both verdict files are retained.

Together with the 20 s sweep, PROPOSAL.md Tier0 item 3 is now satisfied as
preregistered: every bundled case/mode finishing within 60 s is byte-identical.
