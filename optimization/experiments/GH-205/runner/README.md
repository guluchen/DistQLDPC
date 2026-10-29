# Unfinished MaxSAT reproductions, not a server allocation

Three default MaxSAT proof completions: N900/1800/2700,K50. Each original
60-second result was [9,14]; CC returned14 and actual weight14 words passed
GF2. The N900 source exact14 control was reproduced by CC. New finite N1800/
2700 exact14 remains PLAUSIBLE until independently completed/reviewed.
The source-construction bounds and raw search fields remain separate.

N420/840/1260 already have both-engine exact8/11/11 plus actual minimum words,
so they are not queued. Every CC job completed; optional-cc-jobs.jsonl is empty.
There are no missing-numeric or source-upper-word jobs. No reselection/retry,
performance adoption, tier assignment or QDistSAT mirroring is authorized.

Each queued run: one pinned core,4GiB address-space cap,seed0,6CPUh and6h10wall
backstop. Total limits18CPUh/18h30wall serial, not an expected runtime or ETA.
No server core is allocated. PI must allocate a free yfclab2 core and approve
the execution reference; check it is free immediately before launch. Other
agents' reservations are not overridden. No Mac/cloud distance runs.

From the clean committed checkout, an allocated server operator can inspect:

```
python3 optimization/experiments/GH-205/runner/run_serial.py --cpu "$HBC_CORE" --out "$HBC_OUT"
```

HBC_CORE must be the PI-assigned core; HBC_OUT is a new evidence directory
outside the checkout with an existing writable parent. HBC_ALLOCATION_REF is
the actual PI approval record. After verifying allocation/free-core status,
build the unchanged solver on that core and launch serially:

```
taskset -c "$HBC_CORE" prlimit --as=4294967296 -- make --jobs=1 bin/distqldpc
nohup python3 optimization/experiments/GH-205/runner/run_serial.py --cpu "$HBC_CORE" --out "$HBC_OUT" --execute --allocation-ref "$HBC_ALLOCATION_REF" --core-confirmed-free > "$HBC_OUT.launch.log" 2>&1 < /dev/null &
```

The runner refuses changed queues/cases/matrices, completed jobs, missing GF2
upper words, changed solver sources, dirty checkouts, other hosts, missing PI
approval/free-core attestation and observed occupied cores. It checks every
retained input/source identity and actual upper word before execution. New
contradictions or malformed exits stop after preserving raw logs and identities.
Missing bounds stay missing; results require review against the retained CC
proof before any scientific confirmation or renaming. No outside solver used.

Local dry-run and refusal receipts are in ../raw/server-*.json. The dry example
core54 is syntax only; it neither reserves nor authorizes a core.
