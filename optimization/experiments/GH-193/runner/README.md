# Radial independent proof/numeric completion — unexecuted

| stem | default MaxSAT60s | CC60s | actual verified GF2 upper | numeric gate |
|---|---|---|---:|---|
|LP_352_18_unknown|[9,20]|[19,20]|20|PASS|
|LP_928_18_unknown|[9,26]|[22,58]|26|PASS|
|LP_1504_18_unknown|[9,26]|[22,26]|26|PASS|
|LP_2528_18_unknown|no numeric fields|[22,26]|26|INCOMPLETE|

Strongest CC lower19/22 is PLAUSIBLE pending independent implementation/
search. Default jobs.jsonl freezes four MaxSAT jobs for that cross-check;
the largest also addresses missing numeric output. One job addresses both
gates, not two duplicate runs. Source352 estimated20 actual-word gate PASS;
all original ring upper targets also have actual words. No supplemental
finder job needed. No exact result or stem/tier change.

Four CC exact-completion research jobs are separately frozen in
optional-cc-jobs.jsonl. They are NOT part of the default queue and require
explicit selection. They may become useful if independent exact completion
is sought; do not run them merely because bounds remain open. Original
modulus cases all have actual upper26: no growing-distance claim.

Both queues use seed0/verbose/6hCPU+600swall/4GiB/serial pinned explicitly
PI-allocated confirmed-free yfclab2 core/nohup/nullstdin. Each queue's
configured total24hCPU/24h40mwall is a LIMIT, not ETA (both combined48hCPU/
49h20mwall). No allocated core/server execution, Mac/routine Actions/paid
cloud substitute or repeated scientific CI. CPU54 dry-run is syntax only.

Source/build must matchbada5e6e917e3b06f7db5c0c004111f22abce95b.
Case/input/job/argv/source/binary identities, source-reference/actual-word/
other-engine contradiction guards retained. References20/26/26/26 are
materialized GF2 upper words, not substituted CLI fields. Exact results
need actual minimum words and subsequent independent scientific review.
Preserve raw CC928 upper58 and missing MaxSAT2528 fields.

Use the complete frozen branch snapshot linked in the GH193 terminal issue
comment (it contains this runner and retained audit). On an explicitly
allocated server core, build serially before execution:
```
taskset -c CORE prlimit --as=4294967296 -- make -j1 bin/distqldpc
```
The runner records the resulting binary SHA256 and frozen source/input
identities; the CI binary hash is provenance, not a cross-compiler promise.

Default dry-run (CORE must be an assigned integer):
```
python3 optimization/experiments/GH-193/runner/run_serial.py --cpu CORE --out /absolute/new/evidence
```
Optional CC queue, dry-run only unless separately selected:
```
python3 optimization/experiments/GH-193/runner/run_serial.py --cpu CORE --out /absolute/new/cc-evidence --jobs optimization/experiments/GH-193/runner/optional-cc-jobs.jsonl
```
Only after explicit PI allocation and fresh free-core check:
```
nohup python3 optimization/experiments/GH-193/runner/run_serial.py --cpu CORE --out /absolute/new/evidence --execute --allocation-ref 'PI allocation comment URL' --core-confirmed-free > /absolute/new/runner.log 2>&1 < /dev/null &
```
Required/optional dry-run and Mac/altered-argv refusal checks pass without
solver invocation/output directory. No automatic rename/tier/mirror/merge.
