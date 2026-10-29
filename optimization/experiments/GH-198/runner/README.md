# GH-198 unexecuted server package

Two default MaxSAT independent proof jobs for TT840/1029. No CC completion
or source-global-word job remains; the two corresponding JSONL files are empty.
All numeric/source-global-word smoke gates PASS. Exact6/14/14/14 already
cross-checked by both engines and actual GF(2) minimum words. LargerCC16
is PLAUSIBLE, MaxSAT raw[10,16]. No extra sweep or post-result replacement.

Default dry-run (CPU54 here is syntax only, not an allocation):

```
python3 optimization/experiments/GH-198/runner/run_serial.py --cpu 54 --out /tmp/gh198-unexecuted
```

Execution requires Linux yfclab2, a clean committed checkout containing this
package, unchanged solver/build versus55d5b01a, frozen input/case hashes,
rebuilt binary, PI-allocated free core, and --execute --allocation-ref with
--core-confirmed-free. Use actual allocated CPU and unique output path,
nohup with stdin /dev/null. No allocation or execution has occurred.
Each serial job6CPUh+600swall/4GiB/seed0; total12CPUh/12h20wall LIMITS,
not predicted time. taskset/prlimit and actual support verification enforced.
Retain stdout/config/source/input/binary/argv identities, including failures.
New lower/exact remains PLAUSIBLE until independent proof+GF2 review; an
exact16 independent MaxSAT result plus actual word can complete retainedCC
cross-check. Scientific contradictions stop the queue, never adjust source
claims or silently overwrite retained raw evidence. No tier/name/main changes.
