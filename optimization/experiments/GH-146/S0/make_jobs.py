#!/usr/bin/env python3
"""GH-146 S0: finder-only jobs (-engine=cc -ub-basis=off -ub-search=budget:B -cc-ub-only -v) per arm.
usage: make_jobs.py OUT.jsonl BUDGET SEEDS STEMS|tier5open|knownd|all ARM=flags [ARM=flags ...]
ARM 'old' with no flags = the GH-140 finder (default). Largest codes first."""
import glob, json, os, sys
out, budget, seeds, sel = sys.argv[1], float(sys.argv[2]), [int(x) for x in sys.argv[3].split(',')], sys.argv[4]
arms = []
for v in sys.argv[5:]:
    tag, _, args = v.partition('=')
    arms.append((tag, args.split()))
stems = {}
for f in sorted(glob.glob('data/matrices/tier*/*_Hx.txt')):
    stem = os.path.basename(f)[:-7]; stems[stem] = f[:-7]
def known(s): return s.split('_')[3].isdigit()
if sel == 'tier5open': pick = [s for s in stems if '/tier5/' in stems[s] and not known(s)]
elif sel == 'knownd': pick = [s for s in stems if known(s)]
elif sel == 'all': pick = list(stems)
else: pick = sel.split(',')
jobs = []
for tag, extra in arms:
    for s in pick:
        tier = int(stems[s].split('/tier')[1][0])
        for sd in seeds:
            jobs.append(dict(id=f'{tag}.{s}.s{sd}', args=['-engine=cc', '-v', '-cc-stats', '-ub-basis=off', f'-ub-search=budget:{budget:g}',
                             '-cc-ub-only', f'-seed={sd}'] + extra, code=stems[s], stem=s, tier=tier, arm=tag, seed=sd, limit=int(budget + 120)))
jobs.sort(key=lambda j: (-int(j['stem'].split('_')[1]), j['seed']))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs')
