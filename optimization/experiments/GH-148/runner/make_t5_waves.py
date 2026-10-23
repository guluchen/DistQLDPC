#!/usr/bin/env python3
"""GH-148 Tier 5 waves (preregistered in #148): 54 candidate cells (27 codes x 2 modes, -stab-overlap=auto, default
seed, 21600 s) in two waves on the 34 cores 90-123: wave 1 = the first 34 cells in make_jobs order (largest codes
first); wave 2 = the remaining 20 cells, the first 14 of them paired with a concurrent main-12b3e05 drift control
(adjacent in the queue). usage: make_t5_waves.py MAIN CAND OUTDIR   (from a worktree root)"""
import glob, json, os, sys
MAIN, CAND, OUT = sys.argv[1:4]
cells = []
for f in sorted(glob.glob('data/matrices/tier5/*_Hx.txt'), key=lambda p: -int(os.path.basename(p).split('_')[1])):
    stem = os.path.basename(f)[:-7]
    for mode in ('-no-card', '-card-mto'):
        cells.append((stem, mode))
def job(stem, mode, arm, b, extra):
    return dict(id=f't5.{stem}.{mode[1:]}.{arm}', bin=b, args=[mode, '-frontier-stats'] + extra, code=f'data/matrices/tier5/{stem}',
                stem=stem, tier=5, arm=arm, seed=0, mode=mode[1:], limit=21600)
w1 = [job(s, m, 'cand', CAND, ['-stab-overlap=auto']) for s, m in cells[:34]]
w2 = []
for i, (s, m) in enumerate(cells[34:]):
    w2.append(job(s, m, 'cand', CAND, ['-stab-overlap=auto']))
    if i < 14: w2.append(job(s, m, 'main', MAIN, []))
for name, js in (('jobs_t5_wave1.jsonl', w1), ('jobs_t5_wave2.jsonl', w2)):
    with open(os.path.join(OUT, name), 'w') as fh:
        for j in js: fh.write(json.dumps(j) + '\n')
    print(name, len(js))
