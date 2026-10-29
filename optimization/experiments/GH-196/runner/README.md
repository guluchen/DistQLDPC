# Lower-only GB688 proof completion — unexecuted

| stem | MaxSAT60s raw | CC60s raw | actual GF2 upper | numeric gate |
|---|---|---|---:|---|
|GB_180_26_unknown|exact7|exact7|7|PASS|
|GB_688_30_unknown|[9,112]|[15,104]|104|PASS|

The source exact7 anchor is cross-checked by both engines and GF2 words;
no job there. GB688 exact distance remains unconfirmed. Source TableII
lower19 is attributed, not yet independently re-certified by our searches.
Current own raw lower15 is weaker; this is not a contradiction or a raised
scientific bound. Keep raw MaxSAT upper112 despite actual basis upper104.
No finite published upper is invented; source-upper-word NOT_APPLICABLE.

One default MaxSAT job seeks independent proof/progress toward source19
and exact completion; one optional CC exact-completion job is frozen
separately and requires explicit queue selection. No separate numeric job,
all numeric gates pass. Do not launch optional research merely because an
exact distance remains unknown. No post-result code/parameter replacement.
Each queue has1serial seed0/verbose/6hCPU+600swall/4GiB/pinned explicitly
PI-allocated confirmed-free yfclab2 job. Configured6CPUh/6h10mwall perqueue
are LIMITS, not ETA (both12CPUh/12h20mwall). No core allocated/server run/
Mac/Actions/paid-cloud substitution or repeated scientific CI.

Source/build must matchfaeb1269d94e362f964e645169b79fbd457b11fd.
Complete case/job/argv/input/source/build/binary identity guards; actual
GF2 cap104, source lower19 and prior-engine consistency checked separately.
Exact results require actual minimum words and independent scientific
review; source19 is never substituted for missing raw bounds. CI binary
hash is provenance, not a cross-compiler requirement. No tier/name/mirror/
solver/default/main change. Use final branch snapshot linked in issue196.

Build on a freshly checked PI-assigned free core:
```
taskset -c CORE prlimit --as=4294967296 -- make -j1 bin/distqldpc
```
Default dry-run (CORE must be an explicitly assigned integer):
```
python3 optimization/experiments/GH-196/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```
Optional CC queue dry-run, execute only if separately selected:
```
python3 optimization/experiments/GH-196/runner/run_serial.py --cpu CORE --out /absolute/new/cc-evidence --jobs optimization/experiments/GH-196/runner/optional-cc-jobs.jsonl
```
Only after explicit PI allocation and fresh process/core activity checks:
```
nohup python3 optimization/experiments/GH-196/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```
Both one-job dry-runs and Mac/altered-argv/altered-target refusals pass,
without solver invocation/output directory. CPU54 syntax is not allocation.
