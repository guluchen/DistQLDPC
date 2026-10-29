#!/usr/bin/env python3
"""GH-181 job files (copied from GH-162; run from a worktree root on the server). Arms:
  main = frozen main 6083e66 (-engine=cc, its CC defaults excl,pack,orbf,parity,leaf,overlap with -cc-aut=on),
  sp   = candidate binary with -cc-rules=excl,pack,orbf,parity,leaf,overlap,sparse,sparseov,sparsemrv (everything else default).
  ablation: the codes where sparse adds rows (TN_200, TN_250), seeds 0-4, every GH-181 token subset of interest.
Both arms carry -cc-stats. MAIN / CAND are the frozen binaries (absolute paths) passed per job.
  panel:   tiers 1-4, seeds 0-4, limits tier1-3 1800 s, tier4 5000 s; main and tb of each (code, seed) adjacent.
  tier5:   the tier5 codes (or the stems given), default seed, 21600 s, main and tb adjacent.
  answers: Tier 0 answer check: every tier0-3 code x tiebreak variants (rule subsets, seeds, dual off, aut off,
           index seeds, finder off), 600 s, each with -cc-trace (witnesses for the GF(2) check).
usage: make_jobs.py panel|tier5|answers|ablation OUT.jsonl MAIN CAND [STEMS...]"""
import glob, json, os, sys
kind, out, MAIN, CAND = sys.argv[1:5]
G = 'excl,pack,orbf,parity,leaf,overlap'
SP = f'-cc-rules={G},sparse,sparseov,sparsemrv'
ARMS = [('main', MAIN, []), ('sp', CAND, [SP])]
jobs = []
if kind == 'panel':
    for tier in (4, 3, 2, 1):
        for f in sorted(glob.glob(f'data/matrices/tier{tier}/*_Hx.txt')):
            stem = os.path.basename(f)[:-7]
            for seed in range(5):
                for arm, b, extra in ARMS:
                    jobs.append(dict(id=f'cc.{stem}.{arm}.s{seed}', bin=b, args=['-engine=cc', '-cc-stats', f'-seed={seed}'] + extra,
                                     code=f[:-7], stem=stem, tier=tier, arm=arm, seed=seed, limit=5000 if tier == 4 else 1800))
elif kind == 'tier5':
    stems = sys.argv[5:] or [os.path.basename(f)[:-7] for f in sorted(glob.glob('data/matrices/tier5/*_Hx.txt'))]
    for stem in stems:
        code = glob.glob(f'data/matrices/tier5/{stem}_Hx.txt')[0][:-7]
        for arm, b, extra in ARMS:
            jobs.append(dict(id=f't5.{stem}.{arm}', bin=b, args=['-engine=cc', '-cc-stats'] + extra, code=code, stem=stem, tier=5,
                             arm=arm, seed=0, limit=21600))
elif kind == 'ablation':
    VARS = [('main', MAIN, G), ('mainmrv', MAIN, G + ',mrv'), ('sparse', CAND, G + ',sparse'), ('spov', CAND, G + ',sparse,sparseov'),
            ('spmrv', CAND, G + ',sparse,sparsemrv'), ('sp', CAND, G + ',sparse,sparseov,sparsemrv'), ('ov', CAND, G + ',sparseov'),
            ('xu', CAND, G + ',xorunit'), ('spxu', CAND, G + ',sparse,sparseov,sparsemrv,xorunit')]
    for tier, stem in ((2, 'TN_200_10_10'), (4, 'TN_250_10_15')):
        for seed in range(5):
            for arm, b, r in VARS:
                jobs.append(dict(id=f'abl.{stem}.{arm}.s{seed}', bin=b, args=['-engine=cc', '-cc-stats', f'-cc-rules={r}', f'-seed={seed}'],
                                 code=f'data/matrices/tier{tier}/{stem}', stem=stem, tier=tier, arm=arm, seed=seed, limit=1800))
elif kind == 'answers':
    R = G + ',sparse,sparseov,sparsemrv'
    VARS = [('sp', [f'-cc-rules={R}']), ('sp-seed1', [f'-cc-rules={R}', '-seed=1']),
            ('sp-seed2-dualoff', [f'-cc-rules={R}', '-seed=2', '-cc-dual=off']),
            ('sp-autoff-seed3', [f'-cc-rules={R}', '-cc-aut=off', '-seed=3']),
            ('sp-index-seed4', [f'-cc-rules={R}', '-no-symbreak', '-seed=4']),
            ('sp-mrv-xorunit', [f'-cc-rules={R},mrv,xorunit']), ('sp-noub', [f'-cc-rules={R}', '-ub-search=off', '-ub-basis=off']),
            ('sparse-xorunit-plain', ['-cc-rules=excl,pack,sparse,xorunit', '-seed=5', '-ub-search=off']),
            ('xorunit', [f'-cc-rules={G},xorunit', '-seed=6'])]
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
