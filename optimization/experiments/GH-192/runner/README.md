# Three proof jobs and one actual source-upper-word job — unexecuted

All numeric smoke gates PASS. Scientific proof and B3 source-word gates
remain incomplete; a green collection workflow is not a completed proof.

| stem | default MaxSAT60s | CC60s | actual verified GF2 upper | source upper-word gate |
|---|---|---|---:|---|
|LP_882_24_unknown|[18,24]|exact24 PLAUSIBLE|24|PASS|
|LP_1270_28_unknown|[18,48]|[24,64]|48|INCOMPLETE (source46)|

B1 CC exact24 needs independent MaxSAT proof; B3 strongest lower24 also
needs independent proof. The source intervals18..24/16..46 remain separate
claims. Do not replace B3 raw CC upper64 with48, or actual verified upper48
with unmaterialized source46. No contradiction follows merely from finding
a weaker upper word than a published upper claim. No rename/tier/mirror.

Frozen jobs: defaultseed0/verbose MaxSAT B1; defaultseed0/verbose MaxSAT and
CC B3; one explicit supplemental B3 MaxSAT -ub-pre=3600 to seek an actual
word<=source46. The supplemental flags are recorded separately from the
default jobs. All have6hCPU+600swall/4GiB, serial pinned explicitly
PI-allocated confirmed-free yfclab2 core/nohup/nullstdin. Four jobs give
configured total24hCPU/24h40mwall LIMITS, not ETA. No allocated core/run.
No Mac/routine Actions/paid-cloud substitute or scientific CI rerun.

References24/48 are materialized GF2 words. Source target46 is separately
frozen and never substituted for an actual word, initial CLI bound or input
logical. Exact answers need actual minimum words. Case/job/argv/input/source
identities and source/other-engine/word contradiction guards are enforced.
Solver/build must match5827c8900c2da6f1d575a4ef0a6bffb2c2c86247. Retain full
source/binary/input/log evidence; independent scientific review follows.

Dry-run (CORE must be an assigned integer):
```
python3 optimization/experiments/GH-192/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```
Only after explicit PI allocation and fresh free-core check:
```
nohup python3 optimization/experiments/GH-192/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```
CPU54 in retained dry-run is syntactic, not an allocation. Mac, altered
argv and altered source-target guards reject without solver/output directory.
