# Four interval-reference proof jobs — unexecuted

Both numeric smoke gates and actual source-upper-word gates PASS. These
jobs address remaining proof gaps, not missing CLI fields. Retained60s:

| stem | default MaxSAT | CC | actual GF2 upper |
|---|---|---|---:|
|GB_254_28_unknown|[10,20]|[16,20]|20|
|GB_180_10_unknown|[9,18]|[17,18]|18|

CC lower16/17 exceeds the source14/15 lower but is PLAUSIBLE pending
independent search/proof. Published intervals remain separate claims.
No exact distance, renaming or tier assignment. Preserve frozen inputs.

One MaxSAT and one CC defaultseed0/verbose job per case,6hCPU+600swall/
4GiB/serial pinned explicitly PI-allocated confirmed-free yfclab2 core.
Total24hCPU/24h40mwall are configured serial LIMITS, not ETA. No allocated
core/server execution. No Mac/routine Actions/paid-cloud substitute.

Default dry-run, actual GF2 upper references20/18, cases/jobs/argv/input
identities, source/binary retention and source/other-engine/actual-word
contradiction guards. Solver/build must match9588fc5ed120c57bf9bdc4588c52022e48e01bc9.
The runner records raw results; an exact answer needs a materialized actual
minimum word, and cross-engine scientific review still follows. Any
contradiction stops for PI review; no automatic rename/tier/mirror/merge.

Dry-run (CORE must be an assigned integer):
```
python3 optimization/experiments/GH-191/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```
Only after explicit PI allocation and a fresh free-core check:
```
nohup python3 optimization/experiments/GH-191/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```
CPU54 in retained dry-run is syntax only, not an allocation. Mac and altered
argv guards reject without solver invocation/output directory. No repeated
scientific CI to complete these proof gaps.
