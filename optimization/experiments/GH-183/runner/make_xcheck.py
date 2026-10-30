#!/usr/bin/env python3
"""GH-183 cross-check of the PLAUSIBLE lower bounds BB_756 >= 32, BB_864 >= 32, TN_496 >= 24: the configuration that found
them (frozen GH-183 binary, -engine=cc -cc-stats -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-roworder=bfs)
with relabeled seeds 1-3 (-seed=N = -cc-seed=N: qubits and rows relabeled, a different search order), 28800 s.
usage: make_xcheck.py OUT.jsonl CAND"""
import glob, json, sys
out, CAND = sys.argv[1:3]
R = '-cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv'
jobs = []
for stem in ('BB_756_16_30to34', 'BB_864_4_30to40', 'TN_496_2_23to30'):
    code = glob.glob(f'data/matrices/tier5/{stem}_Hx.txt')[0][:-7]
    for seed in (1, 2, 3):
        jobs.append(dict(id=f'x.{stem}.s{seed}', bin=CAND, args=['-engine=cc', '-cc-stats', R, '-cc-roworder=bfs', f'-seed={seed}'],
                         code=code, stem=stem, tier=5, arm='tbmrvbfs', seed=seed, limit=28800))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
