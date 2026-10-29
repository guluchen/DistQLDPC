#!/usr/bin/env python3
"""GH-183 job files (run from a worktree root on the server). Arms (all -engine=cc -cc-stats):
  main      = frozen main 6083e66, its CC defaults (excl,pack,orbf,parity,leaf,overlap, -cc-aut=on);
  tb        = candidate binary, -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak (the GH-162 configuration; the
              candidate's search with the default row order is byte-identical to GH-162 97c8629);
  tbmrv     = Part A: tb + mrv;
  tbmrvbfs  = Part B: tbmrv + -cc-roworder=bfs;
  tbmrvbfsa = tbmrvbfs + -cc-tbbase=asc.
  panel:   tiers 1-4, seeds 0-4, limits tier1-3 1800 s, tier4 5000 s; the arms of each (code, seed) adjacent.
  tier5:   given stems, default seed, 21600 s, arms given by --arms (comma list).
  answers: Tier 0 answer check: every tier0-3 code x GH-183 variants, 600 s, each with -cc-trace (GF(2) witness check).
usage: make_jobs.py panel|tier5|answers OUT.jsonl MAIN CAND [ARMS] [STEMS...]"""
import glob, json, os, sys
kind, out, MAIN, CAND = sys.argv[1:5]
R0 = 'excl,pack,orbf,parity,leaf,overlap'
TB = f'{R0},tiebreak'
ALL = {'main': (MAIN, []), 'tb': (CAND, [f'-cc-rules={TB}']), 'tbmrv': (CAND, [f'-cc-rules={TB},mrv']),
       'tbmrvbfs': (CAND, [f'-cc-rules={TB},mrv', '-cc-roworder=bfs']),
       'tbmrvbfsa': (CAND, [f'-cc-rules={TB},mrv', '-cc-roworder=bfs', '-cc-tbbase=asc'])}
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
    R = f'{TB},mrv'
    VARS = [('tbmrv', [f'-cc-rules={R}']),
            ('tbmrv-bfs', [f'-cc-rules={R}', '-cc-roworder=bfs']),
            ('tbmrv-bfs-asc', [f'-cc-rules={R}', '-cc-roworder=bfs', '-cc-tbbase=asc']),
            ('tbmrv-bfs-seed1', [f'-cc-rules={R}', '-cc-roworder=bfs', '-seed=1']),
            ('tbmrv-bfs-seed2-dualoff', [f'-cc-rules={R}', '-cc-roworder=bfs', '-seed=2', '-cc-dual=off']),
            ('tbmrv-bfs-autoff-seed3', [f'-cc-rules={R}', '-cc-roworder=bfs', '-cc-aut=off', '-seed=3']),
            ('tbmrv-bfs-index-seed4', [f'-cc-rules={R}', '-cc-roworder=bfs', '-no-symbreak', '-seed=4']),
            ('bfs-default-noub', ['-cc-roworder=bfs', '-ub-search=off', '-ub-basis=off']),
            ('tb-asc', [f'-cc-rules={TB}', '-cc-tbbase=asc']),
            ('bfs-oldrules-seed5', ['-cc-rules=excl,pack,orbf,mrv', '-cc-roworder=bfs', '-seed=5', '-ub-search=off'])]
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
