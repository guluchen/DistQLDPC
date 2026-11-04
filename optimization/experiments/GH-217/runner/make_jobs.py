#!/usr/bin/env python3
"""GH-217 job files (run from a worktree root on yfclab2). Arms (all -engine=cc -cc-stats):
  main = frozen main 02879a93, CC defaults (excl,pack,orbf,parity,leaf,overlap,charge, -cc-roworder=index);
  A    = candidate, its defaults (excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv, -cc-roworder=auto);
  B    = candidate, -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak (fallback: no sparse tokens; default roworder auto);
  old  = candidate, -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge -cc-roworder=index (= main's search, drift control).
Codes are found under data/matrices/*/ (tier0..tier5 and untiered); the tier recorded is the directory at job creation,
the analysis regroups by the layout on main at judging time.
  panel OUT MAIN CAND ARMS SEEDS LIMIT STEM...: seeds 0..SEEDS-1, the arms of each (code, seed) adjacent (they run concurrently).
  tier5 OUT MAIN CAND ARMS LIMIT STEM...: default seed.
  answers OUT MAIN CAND STEM...: Tier 0 answer + witness check (600 s, -cc-trace TRACEDIR/<id>.trace), candidate variants.
"""
import glob, json, os, sys
kind, out, MAIN, CAND = sys.argv[1:5]
OLD = ['-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge', '-cc-roworder=index']
ALL = {'main': (MAIN, []), 'A': (CAND, []), 'B': (CAND, ['-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak']), 'old': (CAND, OLD)}


def code_of(stem):
    f = glob.glob(f'data/matrices/*/{stem}_Hx.txt')
    assert len(f) == 1, (stem, f)
    return f[0][:-7], os.path.basename(os.path.dirname(f[0]))


jobs = []
if kind == 'panel':
    arms, seeds, limit = sys.argv[5].split(','), int(sys.argv[6]), int(sys.argv[7])
    for stem in sys.argv[8:]:
        code, tier = code_of(stem)
        for seed in range(seeds):
            for arm in arms:
                b, extra = ALL[arm]
                jobs.append(dict(id=f'cc.{stem}.{arm}.s{seed}', bin=b, args=['-engine=cc', '-cc-stats', f'-seed={seed}'] + extra,
                                 code=code, stem=stem, tier=tier, arm=arm, seed=seed, limit=limit))
elif kind == 'tier5':
    arms, limit = sys.argv[5].split(','), int(sys.argv[6])
    for stem in sys.argv[7:]:
        code, tier = code_of(stem)
        for arm in arms:
            b, extra = ALL[arm]
            jobs.append(dict(id=f't5.{stem}.{arm}', bin=b, args=['-engine=cc', '-cc-stats'] + extra, code=code, stem=stem, tier=tier,
                             arm=arm, seed=0, limit=limit))
elif kind == 'answers':
    B = ALL['B'][1]
    VARS = [('A', []), ('A-seed1', ['-seed=1']), ('A-seed2-dualoff', ['-seed=2', '-cc-dual=off']), ('A-switch', ['-cc-probe=switch']),
            ('A-p0-seed3', ['-cc-probe=0', '-seed=3']), ('A-autoff-seed4', ['-cc-aut=off', '-seed=4']), ('A-nosym', ['-no-symbreak', '-cc-probe=0']),
            ('A-noub', ['-ub-search=off', '-ub-basis=off', '-cc-probe=0']), ('B', B), ('B-switch-seed1', B + ['-cc-probe=switch', '-seed=1']),
            ('old', OLD)]
    for stem in sys.argv[5:]:
        code, tier = code_of(stem)
        for name, extra in VARS:
            jid = f'ans.{stem}.{name}'
            jobs.append(dict(id=jid, bin=CAND, args=['-engine=cc', '-cc-stats'] + extra + [f'-cc-trace=TRACEDIR/{jid}.trace'],
                             code=code, stem=stem, tier=tier, arm=name, seed=0, limit=600))
with open(out, 'w') as fh:
    for j in jobs: fh.write(json.dumps(j) + '\n')
print(len(jobs), 'jobs ->', out)
