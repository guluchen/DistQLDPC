# Tile proof/numeric completion — unexecuted

| stem | MaxSAT60s raw | CC60s raw | actual GF2 upper | numeric gate |
|---|---|---|---:|---|
|TILE_288_8_unknown|exact12|exact12|12|PASS|
|TILE_512_18_unknown|[9,21]|[13,21]|21|PASS|
|TILE_1152_18_unknown|[5,41]|[12,46]|41|PASS|
|TILE_2592_18_unknown|no numeric fields|[12,161]|161|INCOMPLETE|

Published288exact12 is cross-checked by both engines and actual GF2 words.
No job there. Source512 upper23 is reproduced and an actual weight21 word
verified; no supplemental source-word job. Do not assert exact21. Last2
are original layouts with no inherited distance or growing-distance claim.
Strongest new CC lower13/12/12 PLAUSIBLE pending independent proof/search.
Three default MaxSAT jobs cross-check these bounds; the largest also
addresses missing numeric output. One job serves both gates, no duplicate.
Three optional CC exact-completion jobs are frozen separately; they require
explicit queue selection and are not run merely because distance is unknown.
Preserve raw CC1152 upper46 and missing MaxSAT2592 fields.

Each queue has3serial seed0/verbose/6hCPU+600swall/4GiB/pinned explicitly
PI-allocated confirmed-free yfclab2 jobs. Configured18hCPU/18h30mwall per
queue are LIMITS, not ETA (both combined36hCPU/37hwall). No allocated core,
server execution, Mac/Actions/paid-cloud substitute or repeated scientific
CI. CPU54 dry-run is syntax only, not an allocation. Check process/core
activity immediately before executing; /proc guard supplements that check.

Solver/build must match54ebd9f1878d7a5a6bfe0fb6a61e666c82f86cb0.
Complete frozen source/input/case/job/argv/binary identity, prior-engine/
reference/actual-word contradiction guards and minimum-word requirement.
Final branch snapshot is linked in GH194 terminal issue comment. Build
serially on the explicitly assigned free core before execution:
```
taskset -c CORE prlimit --as=4294967296 -- make -j1 bin/distqldpc
```
Record resulting binarySHA256; CI hash is provenance, not a cross-compiler
promise. No tier/name/QDistSAT/default/solver/main change.

Default dry-run (CORE must be an assigned integer):
```
python3 optimization/experiments/GH-194/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```
Optional CC queue, dry-run unless independently selected:
```
python3 optimization/experiments/GH-194/runner/run_serial.py --cpu CORE --out /absolute/new/cc-evidence --jobs optimization/experiments/GH-194/runner/optional-cc-jobs.jsonl
```
Only after explicit PI allocation and a fresh free-core check:
```
nohup python3 optimization/experiments/GH-194/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```
Exact completion remains a scientific result requiring independent review.
