#!/usr/bin/env python3
"""GH-103 trace batch (GH-95 run_one.sh semantics) under the 2 GB cap (coord/memlimit.py).
usage: batch.py BIN OUTDIR CPULIM DATAROOT LISTFILE [JOBS]
Writes OUTDIR/<code>.<mode>.out (stdout+stderr) and .rc ('exit=<status>' or 'exit=MEMOUT'/'exit=WATCHDOG')."""
import sys, os, shlex, subprocess
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, '/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord')
import memlimit
FLAGS = {'default': '-v', 'nocard': '-v -no-card', 'sinz': '-v -card-sinz', 'mto': '-v -card-mto', 'joint': '-joint -v -no-card'}
binp, out, lim, root, lst = sys.argv[1:6]
jobs = int(sys.argv[6]) if len(sys.argv) > 6 else 4
os.makedirs(out, exist_ok=True)
runs = [l.split() for l in open(lst) if l.strip()]
def one(cm):
    code, mode = cm
    o = os.path.join(out, code + '.' + mode)
    sh = 'cd %s && exec %s %s -cpu-lim=%s %s > %s 2>&1' % (shlex.quote(root), shlex.quote(binp), FLAGS[mode], lim, code, shlex.quote(o + '.out'))
    rc, _, _, peak = memlimit.run(['/bin/sh', '-c', sh], timeout=int(lim) * 3 + 120)
    open(o + '.rc', 'w').write('exit=%s\n' % rc)
    return code, mode, rc, peak
with ThreadPoolExecutor(jobs) as ex:
    for code, mode, rc, peak in ex.map(one, runs):
        print(code, mode, rc, 'peakMB=%d' % (peak // 1024), flush=True)
