#!/usr/bin/env python3
"""GH-195 job files (run from a worktree root on the server; template GH-162 make_jobs.py). Arms (all -engine=cc -cc-stats):
  main = frozen main 6083e66, its CC defaults (excl,pack,orbf,parity,leaf,overlap, -cc-aut=on);
  er   = candidate, -cc-rules=excl,pack,orbf,parity,leaf,overlap,erasure            (compare with main);
  tb   = candidate, -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak           (= PR #180, token-off identity checked);
  tber = candidate, -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,erasure   (compare with tb).
  panel:   tiers 1-4, seeds 0-4, limits tier1-3 1800 s, tier4 5000 s; the four arms of each (code, seed) adjacent.
  tier5:   the tier5 codes (or the stems given), default seed, 21600 s, arms tb and tber (ARMS env: comma list) adjacent.
  answers: Tier 0 answer check: every tier0-3 code x erasure variants (rule subsets, seeds, dual off, aut off, index seeds,
           finder off, mrv), 600 s, each with -cc-trace (witnesses for the GF(2) check).
usage: make_jobs.py panel|tier5|answers OUT.jsonl MAIN CAND [STEMS...]"""
import glob, json, os, sys
kind, out, MAIN, CAND = sys.argv[1:5]
D = 'excl,pack,orbf,parity,leaf,overlap'
ALL = [('main', MAIN, []), ('er', CAND, [f'-cc-rules={D},erasure']), ('tb', CAND, [f'-cc-rules={D},tiebreak']),
       ('tber', CAND, [f'-cc-rules={D},tiebreak,erasure'])]
jobs = []
if kind == 'panel':
    for tier in (4, 3, 2, 1):
        for f in sorted(glob.glob(f'data/matrices/tier{tier}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for seed in range(5):
                for arm, b, extra in ALL:
                    jobs.append(dict(id=f'cc.{stem}.{arm}.s{seed}', bin=b, args=['-engine=cc', '-cc-stats', f'-seed={seed}'] + extra,
                                     code=f[:-7], stem=stem, tier=tier, arm=arm, seed=seed, limit=5000 if tier == 4 else 1800))
elif kind == 'tier5':
    want = os.environ.get('ARMS', 'tb,tber').split(',')
    stems = sys.argv[5:] or [os.path.basename(f)[:-7] for f in sorted(glob.glob('data/matrices/tier5/*_Hx.txt'))]
    for stem in stems:
        code = glob.glob(f'data/matrices/tier5/{stem}_Hx.txt')[0][:-7]
        for arm, b, extra in ALL:
            if arm in want:
                jobs.append(dict(id=f't5.{stem}.{arm}', bin=b, args=['-engine=cc', '-cc-stats'] + extra, code=code, stem=stem, tier=5,
                                 arm=arm, seed=0, limit=21600))
elif kind == 'answers':
    E, T = f'{D},erasure', f'{D},tiebreak,erasure'
    Z = '-cc-erasure-start=0'   # tests from the first level (the default start, 16384 nodes, leaves most Tier 0 codes untouched)
    VARS = [('er', [f'-cc-rules={E}', Z]), ('tber', [f'-cc-rules={T}', Z]), ('tber-defstart', [f'-cc-rules={T}']),
            ('tber-seed1', [f'-cc-rules={T}', Z, '-seed=1']),
            ('tber-seed2-dualoff', [f'-cc-rules={T}', Z, '-seed=2', '-cc-dual=off']),
            ('er-autoff-seed3', [f'-cc-rules={E}', Z, '-cc-aut=off', '-seed=3']),
            ('tber-index-seed4', [f'-cc-rules={T}', Z, '-no-symbreak', '-seed=4']),
            ('tber-mrv', [f'-cc-rules={T},mrv', Z]), ('tber-noub', [f'-cc-rules={T}', Z, '-ub-search=off', '-ub-basis=off']),
            ('er-pack-excl', ['-cc-rules=excl,pack,erasure', Z, '-seed=5', '-ub-search=off'])]
    for tier in (0, 1, 2, 3):
        for f in sorted(glob.glob(f'data/matrices/tier{tier}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for v, extra in VARS:
                jobs.append(dict(id=f'ans.{stem}.{v}', bin=CAND, args=['-engine=cc', '-v', '-cc-stats', f'-cc-trace=TRACE/ans.{stem}.{v}.trace'] + extra,
                                 code=f[:-7], stem=stem, tier=tier, arm=v, seed=0, limit=600))
with open(out, 'w') as fo:
    for j in jobs: fo.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
