# GH-206 Tier 5, first run (binary 14ec146, `-cc-probe-growth=30`)

- Binary 14ec146 re-probed at 30 x the last probe level's time. No re-probe ever changed a decision, but each one cost a full level. At level 30 that is thousands of seconds: BB_864 auto lost 9447 s, BB_1080 6733 s, TN_288 6319 s.
- The final default (fca5d3c) is one probe per half. It is confirmed in `../S3_tier5_final/`.
- `single_probe.jsonl` derives the single-probe event times from these logs. The searches are deterministic, and no re-probe switched, so the derivation is exact for the search; it assumes equal machine speed.
- `lp_ref_core34.txt` holds same-session tb / tbmrvbfs / auto(growth 0) on the LP codes, run back to back on clean core 34.
- Core 36 carries a root process using about 16 % of the core. The auto runs of LP_1428 and TN_252 were on it.
