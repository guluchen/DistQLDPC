# Independent three-cycle proof completion — unexecuted

| stem | MaxSAT raw60s | CC raw60s | actual GF2 upper | scientific status |
|---|---|---|---:|---|
|ITB_54_14_unknown|exact5|exact5|5|cross-checked source anchor|
|ITB_128_20_unknown|exact8|exact8|8|cross-checked source anchor|
|ITB_250_26_unknown|exact10|exact10|10|cross-checked original finite exact|
|ITB_686_38_unknown|[9,14]|exact14|14|CC-only exact PLAUSIBLE|
|ITB_1458_50_unknown|[9,18]|exact18|18|CC-only exact PLAUSIBLE|
|ITB_2662_62_unknown|[9,22]|[18,22]|22|CC lower18 PLAUSIBLE|

All numeric gates PASS. The first3require no further proof job. Three
remaining defaultMaxSAT jobs seek independent proof/progress; separately
one optionalCC exact-completion job for2662 requires explicit selection.
No extra numeric/source-word job. Originals have no individual published
source endpoints; source-upper-word NOT_APPLICABLE. Known5/8 and new finite
exact10 cross-checked by two searches+actual GF2 words. Do not promote
CC-only14/18 or largestlower18 into independently confirmed exact/lower.
Retain every frozen size; no universal d=2L or growing-distance theorem.

Default queue configured18CPUh/18h30mwall; optional queue6CPUh/6h10mwall;
both24CPUh/24h40mwall LIMITS, not ETA. Each job seed0/verbose/6hCPU+600swall/
4GiB/serial pinned explicitly PI-allocated confirmed-free yfclab2/nohup/
nullstdin. No core allocated/server execution, Mac/Actions/paid-cloud
substitution or repeated scientific CI. CPU54 dry-run syntax not allocation.
Check current process/core activity before execution; /proc supplements it.

Solver/build must match29fca9ec447b2a8f0246c7a38754b62def20fee1. Complete
case/job/argv/source/build/input/binary identity and prior-engine/source/
actual-word consistency guards. Exact results require actual minimum words
and independent scientific review. Use final branch snapshot linked in197.
CI hash is provenance, not a cross-compiler requirement. No tier/name/mirror/
solver/default/main change. Build on the freshly checked PI-assigned core:
```
taskset -c CORE prlimit --as=4294967296 -- make -j1 bin/distqldpc
```
Default dry-run (CORE must be an explicitly assigned integer):
```
python3 optimization/experiments/GH-197/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```
Optional CC queue dry-run; execute only if separately selected:
```
python3 optimization/experiments/GH-197/runner/run_serial.py --cpu CORE --out /absolute/new/cc-evidence --jobs optimization/experiments/GH-197/runner/optional-cc-jobs.jsonl
```
Only after explicit PI allocation and fresh free-core checks:
```
nohup python3 optimization/experiments/GH-197/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```
3default/1optional dry-runs and Mac/altered-argv/altered-target refusals PASS,
without solver invocation or output directory. No automatic result promotion.
