#!/usr/bin/env python3
"""GH-206 job files (run from a worktree root on the server). Arms (all -engine=cc -cc-stats):
  main     = frozen main 6083e66, CC defaults;
  tb       = candidate, -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak (GH-162 configuration);
  tbmrvbfs = candidate, tb + mrv + -cc-roworder=bfs (GH-183 configuration);
  auto     = candidate, tb rules + -cc-roworder=auto (GH-206; probe at the first level >= 1 s);
  autoa    = auto + -cc-tbbase=asc.
  panel:   tiers 1-4, seeds 0-4, limits tier1-3 1800 s, tier4 5000 s; the arms of each (code, seed) adjacent.
  tier5:   given stems, default seed, 21600 s, arms by comma list.
  answers: Tier 0 answer check (tier0-3 codes x auto variants, 600 s, -cc-trace for the GF(2) witness check).
usage: make_jobs.py panel|tier5|answers OUT.jsonl MAIN CAND [ARMS] [STEMS...]"""
import glob, json, os, sys
kind, out, MAIN, CAND = sys.argv[1:5]
TB = 'excl,pack,orbf,parity,leaf,overlap,tiebreak'
ALL = {'main': (MAIN, []), 'tb': (CAND, [f'-cc-rules={TB}']), 'tbmrvbfs': (CAND, [f'-cc-rules={TB},mrv', '-cc-roworder=bfs']),
       'auto': (CAND, [f'-cc-rules={TB}', '-cc-roworder=auto']), 'autoa': (CAND, [f'-cc-rules={TB}', '-cc-roworder=auto', '-cc-tbbase=asc'])}
jobs = []
if kind == 'panel':
    arms = sys.argv[5].split(',') if len(sys.argv) > 5 else list(ALL)
    for tier in (4, 3, 2, 1):
        for f in sorted(glob.glob(f'data/matrices/tier{tier}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for seed in range(5):
                for arm in arms:
                    b, extra = ALL[arm]
                    jobs.append(dict(id=f'cc.{stem}.{arm}.s{seed}', bin=b, args=['-engine=cc', '-cc-stats', f'-seed={seed}'] + extra,
                                     code=f[:-7], stem=stem, tier=tier, arm=arm, seed=seed, limit=5000 if tier == 4 else 1800))
elif kind == 'tier5':
    arms = sys.argv[5].split(',')
    for stem in sys.argv[6:]:
        code = glob.glob(f'data/matrices/tier5/{stem}_Hx.txt')[0][:-7]
        for arm in arms:
            b, extra = ALL[arm]
            jobs.append(dict(id=f't5.{stem}.{arm}', bin=b, args=['-engine=cc', '-cc-stats'] + extra, code=code, stem=stem, tier=5,
                             arm=arm, seed=0, limit=21600))
elif kind == 'answers':
    A = [f'-cc-rules={TB}', '-cc-roworder=auto']
    VARS = [('auto', A), ('auto-p0', A + ['-cc-probe=0']), ('auto-switch', A + ['-cc-probe=switch']), ('auto-stay', A + ['-cc-probe=stay']),
            ('auto-p0-seed1', A + ['-cc-probe=0', '-seed=1']), ('auto-switch-seed2-dualoff', A + ['-cc-probe=switch', '-seed=2', '-cc-dual=off']),
            ('auto-p0-autoff-seed3', A + ['-cc-probe=0', '-cc-aut=off', '-seed=3']), ('auto-switch-index-seed4', A + ['-cc-probe=switch', '-no-symbreak', '-seed=4']),
            ('auto-p0-noub', A + ['-cc-probe=0', '-ub-search=off', '-ub-basis=off']), ('auto-p0-asc', A + ['-cc-probe=0', '-cc-tbbase=asc']),
            ('auto-switch-defaultrules', ['-cc-roworder=auto', '-cc-probe=switch', '-seed=5'])]
    for tier in (0, 1, 2, 3):
        for f in sorted(glob.glob(f'data/matrices/tier{tier}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for name, extra in VARS:
                jid = f'ans.{stem}.{name}'
                jobs.append(dict(id=jid, bin=CAND, args=['-engine=cc', '-cc-stats'] + extra + [f'-cc-trace=TRACEDIR/{jid}.trace'],
                                 code=f[:-7], stem=stem, tier=tier, arm=name, seed=0, limit=600))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
