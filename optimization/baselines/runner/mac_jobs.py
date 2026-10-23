#!/usr/bin/env python3
"""Baseline re-record (main 12b3e05; first used for main cbb0642, then c914ef5): job list for mac_serial.py.
tier0-4 codes x {-no-card, -card-mto} x 3 runs, default flags (frontier auto), limits tier0 600 s, tier1-3 1800 s,
tier4 2000 s. Runs are ordered run-major (r0 of every cell, then r1, then r2) so a partial table is usable early.
usage (in a repo checkout): mac_jobs.py BIN LOGDIR > jobs.jsonl"""
import glob, json, os, sys
BIN, LOGDIR = sys.argv[1:3]; os.makedirs(LOGDIR, exist_ok=True)
LIMIT = {0: 600, 1: 1800, 2: 1800, 3: 1800, 4: 2000}
cells = [(t, os.path.basename(p)[:-7], m) for t in range(5)
         for p in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt')) for m in ('no-card', 'card-mto')]
for r in range(3):
    for t, s, m in cells:
        rid = f't{t}|{s}|{m}|r{r}'
        print(json.dumps(dict(id=rid, cmd=[BIN, f'-{m}', f'-cpu-lim={LIMIT[t]}', f'data/matrices/tier{t}/{s}'],
                              out=f'{LOGDIR}/{s}.{m}.r{r}.log')))
