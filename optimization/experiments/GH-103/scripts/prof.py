#!/usr/bin/env python3
"""GH-103 profile run: full solve under the 2 GB cap, `sample` the solving child for SECS seconds.
usage: prof.py BIN OUTPREFIX CODE MODE [SECS]
Writes OUTPREFIX.v.log, OUTPREFIX.sample.txt, OUTPREFIX.time (wall, child user+sys from ps)."""
import sys, os, time, subprocess, threading, shlex
sys.path.insert(0, '/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord')
import memlimit
FLAGS = {'default': '-v', 'nocard': '-v -no-card', 'sinz': '-v -card-sinz', 'mto': '-v -card-mto'}
ROOT = '/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb/cand103'
binp, pre, code, mode = sys.argv[1:5]
secs = int(sys.argv[5]) if len(sys.argv) > 5 else 60
sh = 'cd %s && exec /usr/bin/time -p %s %s %s > %s 2>&1' % (shlex.quote(ROOT), shlex.quote(binp), FLAGS[mode], code, shlex.quote(pre + '.v.log'))
res = {}
def runit():
    t0 = time.time(); res['rc'] = memlimit.run(['/bin/sh', '-c', sh], timeout=int(os.environ.get("PROF_TIMEOUT", "240")))[0]; res['wall'] = time.time() - t0
th = threading.Thread(target=runit); th.start()
# find the solving child: a distqldpc process whose parent is a distqldpc process
child = None
for _ in range(200):
    time.sleep(0.05)
    out = subprocess.run(['ps', '-A', '-o', 'pid=,ppid=,comm='], capture_output=True, text=True).stdout
    procs = [l.strip().split(None, 2) for l in out.strip().split('\n')]
    dq = {p[0]: p[1] for p in procs if len(p) == 3 and p[2] == os.path.realpath(binp)}
    kids = [p for p, pp in dq.items() if pp in dq]
    if kids: child = kids[0]; break
if child:
    subprocess.run(['sample', child, str(secs), '1', '-mayDie', '-file', pre + '.sample.txt'], capture_output=True)
th.join()
open(pre + '.time', 'w').write('rc=%s wall=%.2f child=%s\n' % (res.get('rc'), res.get('wall', -1), child))
print(open(pre + '.time').read().strip())
