#!/usr/bin/env python3
"""GH-140 S0: finder-only jobs (-engine=cc -ub-search=budget:B -cc-ub-only) on every tier0-5 code.
usage: make_jobs_finder.py OUT.jsonl BUDGET SEEDS [EXTRA_ARGS_TAG=args ...]"""
import glob, json, os, sys
out, budget, seeds = sys.argv[1], float(sys.argv[2]), [int(x) for x in sys.argv[3].split(',')]
variants = {'base': []}
for v in sys.argv[4:]:
    tag, _, args = v.partition('=')
    variants[tag] = args.split()
tiers = os.environ.get('TIERS', '0,1,2,3,4,5').split(',')
jobs = []
for tag, extra in variants.items():
    for t in tiers:
        for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for s in seeds:
                jobs.append(dict(id=f'ub.{tag}.{stem}.s{s}', args=['-engine=cc', '-cc-stats', f'-ub-search=budget:{budget:g}', '-cc-ub-only', f'-seed={s}'] + extra,
                                 code=f'data/matrices/tier{t}/{stem}', stem=stem, tier=int(t), arm=tag, seed=s, limit=int(budget + 120)))
# largest codes first so that the long tail starts early
jobs.sort(key=lambda j: -int(j['stem'].split('_')[1]))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs')
