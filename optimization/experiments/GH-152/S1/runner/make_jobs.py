#!/usr/bin/env python3
"""GH-152 job files (run from a worktree root). Arms: old = -engine=cc (main e52d15b's CC search; the candidate binary's
default path is byte-identical, S0/identity), new = old + -cc-aut=on. Both arms carry -cc-stats.
  panel: tiers 1-4 (directories data/matrices/tier1..4 of e52d15b), seeds 0-4, limits tier1-3 1800 s, tier4 5000 s;
         for each (code, seed) the two arms are adjacent in the file (run back to back on whichever cores are free).
  tier5: the 27 tier5 codes, default seed, 21600 s, old and new adjacent.
  s0:    node counts per level, -ub-search=off (deterministic ladder), 3600 s, codes given on the command line.
usage: make_jobs.py panel|tier5|s0 OUT.jsonl [STEMS...]"""
import glob, json, os, sys
kind, out = sys.argv[1], sys.argv[2]
ARMS = [('old', []), ('new', ['-cc-aut=on'])]
jobs = []
def code_of(stem):
    return glob.glob(f'data/matrices/tier*/{stem}_Hx.txt')[0][:-7]
if kind == 'panel':
    for tier in (4, 3, 2, 1):   # long cells first
        for f in sorted(glob.glob(f'data/matrices/tier{tier}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for seed in range(5):
                for arm, extra in ARMS:
                    jobs.append(dict(id=f'cc.{stem}.{arm}.s{seed}', args=['-engine=cc', '-cc-stats', f'-seed={seed}'] + extra,
                                     code=f[:-7], stem=stem, tier=tier, arm=arm, seed=seed, limit=5000 if tier == 4 else 1800))
elif kind == 'tier5':
    for f in sorted(glob.glob('data/matrices/tier5/*_Hx.txt')):
        stem = os.path.basename(f)[:-7]
        for arm, extra in ARMS:
            jobs.append(dict(id=f't5.{stem}.{arm}', args=['-engine=cc', '-cc-stats'] + extra, code=f[:-7], stem=stem, tier=5,
                             arm=arm, seed=0, limit=21600))
elif kind == 's0':
    for stem in sys.argv[3:]:
        for arm, extra in ARMS:
            jobs.append(dict(id=f's0.{stem}.{arm}', args=['-engine=cc', '-cc-stats', '-ub-search=off', '-v'] + extra, code=code_of(stem),
                             stem=stem, tier=int(code_of(stem).split('tier')[1][0]), arm=arm, seed=0, limit=3600))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
