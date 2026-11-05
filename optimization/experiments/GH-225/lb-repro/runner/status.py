#!/usr/bin/env python3
import glob, os, re, json
R = os.path.expanduser('~/mac-agent-20261009/gh225lb-runs/repro')
done = set()
if os.path.exists(R + '/results.jsonl'):
    for l in open(R + '/results.jsonl'):
        try: done.add(json.loads(l)['id'])
        except Exception: pass
for f in sorted(glob.glob(R + '/logs/*.log')):
    lb = None; t = None; last = 0.0; cpu = '?'
    for line in open(f):
        if line.startswith('# start'):
            cpu = line.split()[4]; continue
        p = line.split('\t', 1)
        if len(p) < 2: continue
        try: last = float(p[0])
        except ValueError: continue
        m = re.match(r'c d_lb: (\d+)\s*$', p[1])
        if m: lb = int(m.group(1)); t = last
    i = os.path.basename(f)[:-4]
    print(f'{i:40s} cpu{cpu:>3s} lb {lb} at {t} elapsed {last:.0f}{" DONE" if i in done else ""}')
print('RUNNER_DONE' if os.path.exists(R + '/RUNNER_DONE') else 'running')
