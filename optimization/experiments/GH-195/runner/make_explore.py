#!/usr/bin/env python3
"""GH-195 pre-panel exploration of the cost gate (exploration binary with a CCE_GATE env switch: the test runs when
2|S| + 2 <= w + CCE_GATE; 100 = every node with extra <= 2). Arms: tb (rules ...,tiebreak) and tber at gates 0, 2, 4, 100,
seed 0, tiers 2-4 plus BB_360_12_24. usage: make_explore.py OUT.jsonl BIN"""
import glob, json, os, sys
out, B = sys.argv[1:3]
T = 'excl,pack,orbf,parity,leaf,overlap,tiebreak'
codes = []
for t in (4, 3, 2):
    codes += [(t, f[:-7]) for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'))]
codes.append((5, 'data/matrices/tier5/BB_360_12_24'))
jobs = []
for t, c in codes:
    stem = os.path.basename(c)
    jobs.append(dict(id=f'x.{stem}.tb', bin=B, args=['-engine=cc', '-cc-stats', f'-cc-rules={T}'], code=c, stem=stem, tier=t, arm='tb', seed=0, limit=3000))
    for g in (0, 2, 4, 100):
        jobs.append(dict(id=f'x.{stem}.tber.g{g}', bin=B, args=['-engine=cc', '-cc-stats', f'-cc-rules={T},erasure'], env={'CCE_GATE': str(g)},
                         code=c, stem=stem, tier=t, arm=f'tber.g{g}', seed=0, limit=3000))
jobs.sort(key=lambda j: -j['tier'])
with open(out, 'w') as f:
    for j in jobs: f.write(json.dumps(j) + '\n')
print(len(jobs))
