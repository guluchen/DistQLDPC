#!/usr/bin/env python3
"""GH-195 job files (run from a worktree root on the server; template GH-162 make_jobs.py). Since the merge with main
02879a93 (2026-11-04) the arms are (all -engine=cc -cc-stats):
  def    = frozen main 02879a9, its CC default (excl,pack,orbf,parity,leaf,overlap,charge, -cc-aut=on, roworder index);
  defer  = candidate, the default rules + erasure                                       (compare with def);
  tbra   = frozen main 02879a9, default rules + tiebreak, -cc-roworder=auto;
  tbraer = candidate, default rules + tiebreak + erasure, -cc-roworder=auto              (compare with tbra).
  panel:   tiers 1-4, seeds 0-4, limits tier1-3 1800 s, tier4 5000 s; the four arms of each (code, seed) adjacent.
  tier5:   the given stems (or all tier5), default seed, 21600 s, arms from env ARMS (comma list, default all four) adjacent.
  answers: Tier 0 answer check: every tier0-3 code x erasure variants (rule subsets, seeds, dual off, aut off, index seeds,
           finder off, mrv, roworder bfs/auto, GH-181 tokens), 600 s, each with -cc-trace (witnesses for the GF(2) check).
usage: make_jobs.py panel|tier5|answers OUT.jsonl MAIN CAND [STEMS...]   (MAIN: frozen main binary)"""
import glob, json, os, sys
kind, out, MAIN, CAND = sys.argv[1:5]
D = 'excl,pack,orbf,parity,leaf,overlap,charge'
ALL = [('def', MAIN, []), ('defer', CAND, [f'-cc-rules={D},erasure']),
       ('tbra', MAIN, [f'-cc-rules={D},tiebreak', '-cc-roworder=auto']),
       ('tbraer', CAND, [f'-cc-rules={D},tiebreak,erasure', '-cc-roworder=auto'])]
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
    want = os.environ.get('ARMS', 'def,defer,tbra,tbraer').split(',')
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
    VARS = [('defer', [f'-cc-rules={E}', Z]), ('tbraer', [f'-cc-rules={T}', Z, '-cc-roworder=auto']),
            ('tbraer-defstart', [f'-cc-rules={T}', '-cc-roworder=auto']), ('tber-seed1', [f'-cc-rules={T}', Z, '-seed=1']),
            ('tber-seed2-dualoff', [f'-cc-rules={T}', Z, '-seed=2', '-cc-dual=off']),
            ('defer-autoff-seed3', [f'-cc-rules={E}', Z, '-cc-aut=off', '-seed=3']),
            ('tber-index-seed4', [f'-cc-rules={T}', Z, '-no-symbreak', '-seed=4']),
            ('tber-mrv-bfs', [f'-cc-rules={T},mrv', Z, '-cc-roworder=bfs']), ('tber-noub', [f'-cc-rules={T}', Z, '-ub-search=off', '-ub-basis=off']),
            ('er-pack-excl', ['-cc-rules=excl,pack,erasure', Z, '-seed=5', '-ub-search=off']),
            ('tber-gh181', [f'-cc-rules={T},sparse,sparseov,xorunit', Z, '-seed=6'])]
    for tier in (0, 1, 2, 3):
        for f in sorted(glob.glob(f'data/matrices/tier{tier}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for v, extra in VARS:
                jobs.append(dict(id=f'ans.{stem}.{v}', bin=CAND, args=['-engine=cc', '-v', '-cc-stats', f'-cc-trace=TRACE/ans.{stem}.{v}.trace'] + extra,
                                 code=f[:-7], stem=stem, tier=tier, arm=v, seed=0, limit=600))
with open(out, 'w') as fo:
    for j in jobs: fo.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
